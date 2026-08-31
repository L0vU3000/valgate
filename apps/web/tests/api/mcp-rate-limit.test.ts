import { describe, it, expect, vi, beforeEach } from "vitest";

// ---------------------------------------------------------------------------
// /mcp — an over-limit request must NOT reach the MCP handler.
//
// The rate-limit decision is made inside withMcpAuth's verify callback, which mcp-handler runs
// BEFORE the MCP handler. The original implementation only *flagged* the request there and
// swapped the response for a 429 afterwards — so the tools still executed and any write they
// performed was already committed by the time the caller saw the 429. Discarding the response
// is not rate limiting; these tests pin that an over-limit request performs no dispatch at all.
//
// mcp-handler is replaced with a faithful double of the two contracts the route depends on:
//   - createMcpHandler(...) -> the request handler that dispatches tools (spied on here)
//   - withMcpAuth(handler, verify, { required: true }) -> when verify resolves undefined the
//     real implementation throws InvalidTokenError and returns 401 WITHOUT calling the handler
//     (see mcp-handler dist: `if (required && !authInfo) throw new InvalidTokenError(...)`).
// ---------------------------------------------------------------------------

const { mcpDispatchMock, createMcpHandlerMock, verifyClerkTokenMock, authMock, allowedMock, MCP_LIMITER, ctxFromMcpAuthMock, registerValgateMcpMock } =
  vi.hoisted(() => ({
    // Stands in for "the tools ran": every tool call on this surface goes through it.
    mcpDispatchMock: vi.fn(async () => new Response(JSON.stringify({ ok: true }), { status: 200 })),
    createMcpHandlerMock: vi.fn(),
    verifyClerkTokenMock: vi.fn(),
    authMock: vi.fn(),
    allowedMock: vi.fn(),
    MCP_LIMITER: { __limiter: "mcp" },
    ctxFromMcpAuthMock: vi.fn(),
    registerValgateMcpMock: vi.fn(),
  }));

vi.mock("mcp-handler", () => ({
  createMcpHandler: createMcpHandlerMock.mockImplementation(() => mcpDispatchMock),
  experimental_withMcpAuth:
    (handler: (req: Request, ctx?: unknown) => Promise<Response>, verify: (req: Request, token?: string) => Promise<unknown>, opts?: { required?: boolean }) =>
    async (req: Request) => {
      const [type, token] = (req.headers.get("Authorization") ?? "").split(" ");
      const bearer = type?.toLowerCase() === "bearer" ? token : undefined;
      const authInfo = await verify(req, bearer);
      // Faithful to mcp-handler: required + no authInfo -> 401, handler never invoked.
      if (opts?.required && !authInfo) {
        return new Response(JSON.stringify({ error: "invalid_token" }), { status: 401 });
      }
      return handler(req, { authInfo });
    },
}));

vi.mock("@clerk/mcp-tools/next", () => ({ verifyClerkToken: verifyClerkTokenMock }));
vi.mock("@clerk/nextjs/server", () => ({ auth: authMock }));
vi.mock("@/mcp-server/register", () => ({ registerValgateMcp: registerValgateMcpMock }));
vi.mock("@/mcp-server/ctxFor", () => ({ ctxFromMcpAuth: ctxFromMcpAuthMock }));
vi.mock("@/lib/ratelimit", () => ({ mcpLimiter: MCP_LIMITER, allowed: allowedMock }));
vi.mock("@/lib/env", () => ({
  // Unbound endpoint in a non-production NODE_ENV -> any client accepted, so the allowlist
  // check never masks the rate-limit behaviour under test.
  env: { MCP_ALLOWED_OAUTH_CLIENT_IDS: undefined, MCP_ALLOW_ANY_OAUTH_CLIENT: undefined },
}));

import { POST as mcpPost } from "@/app/mcp/route";

const CLERK_USER_ID = "user_abc123";

function mcpReq(): Request {
  return new Request("http://localhost/mcp", {
    method: "POST",
    headers: { Authorization: "Bearer test-oauth-token", "Content-Type": "application/json" },
    body: JSON.stringify({ jsonrpc: "2.0", id: 1, method: "tools/call", params: { name: "create_property", arguments: {} } }),
  });
}

beforeEach(() => {
  vi.clearAllMocks();
  authMock.mockResolvedValue({ userId: CLERK_USER_ID });
  verifyClerkTokenMock.mockResolvedValue({
    clientId: "client_abc",
    scopes: [],
    extra: { userId: CLERK_USER_ID },
  });
  allowedMock.mockResolvedValue(true);
});

describe("POST /mcp rate limiting", () => {
  it("dispatches to the MCP handler when the caller is under the limit", async () => {
    const res = await mcpPost(mcpReq());

    expect(allowedMock).toHaveBeenCalledWith(MCP_LIMITER, CLERK_USER_ID);
    expect(mcpDispatchMock).toHaveBeenCalledTimes(1);
    expect(res.status).toBe(200);
  });

  it("returns 429 WITHOUT dispatching to the MCP handler when over the limit", async () => {
    allowedMock.mockResolvedValue(false);

    const res = await mcpPost(mcpReq());

    expect(res.status).toBe(429);
    // The whole point: no tool ran, so no write happened before the 429.
    expect(mcpDispatchMock).not.toHaveBeenCalled();
  });

  it("returns a Retry-After header on the 429 so clients back off", async () => {
    allowedMock.mockResolvedValue(false);

    const res = await mcpPost(mcpReq());

    expect(res.headers.get("Retry-After")).toBe("60");
    expect(await res.json()).toMatchObject({ error: "rate_limit_exceeded" });
  });

  it("does not consult the limiter when the token is invalid (401 before any dispatch)", async () => {
    verifyClerkTokenMock.mockResolvedValue(undefined);

    const res = await mcpPost(mcpReq());

    expect(res.status).toBe(401);
    expect(allowedMock).not.toHaveBeenCalled();
    expect(mcpDispatchMock).not.toHaveBeenCalled();
  });
});
