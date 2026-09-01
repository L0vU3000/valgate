import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ---------------------------------------------------------------------------
// resolveApiV1Ctx is the single auth seam for every HTTP API v1 route:
//   Clerk bearer session token -> ctxFromMcpAuth (reused, not duplicated) -> rate limit.
// Fully mocked: no real Clerk, no DB, no network. Proves each failure mode returns the
// stable { error: { code, message } } shape and never leaks a caught error's message.
// ---------------------------------------------------------------------------

const { authMock, ctxFromMcpAuthMock, allowedMock, readLimiter, mutationLimiter, loggerMock } = vi.hoisted(() => ({
  authMock: vi.fn(),
  ctxFromMcpAuthMock: vi.fn(),
  allowedMock: vi.fn(),
  readLimiter: { __limiter: "read" },
  mutationLimiter: { __limiter: "mutation" },
  loggerMock: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    debug: vi.fn(),
    child: vi.fn().mockReturnThis(),
  },
}));

vi.mock("@clerk/nextjs/server", () => ({
  auth: authMock,
}));

vi.mock("@/mcp-server/ctxFor", () => ({
  ctxFromMcpAuth: ctxFromMcpAuthMock,
}));

vi.mock("@/lib/ratelimit", () => ({
  apiReadLimiter: readLimiter,
  apiMutationLimiter: mutationLimiter,
  allowed: allowedMock,
}));

vi.mock("@/lib/logger", () => ({
  logger: loggerMock,
}));

import { resolveApiV1Ctx } from "./auth";

const CLERK_USER_ID = "user_abc123";
const CTX = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" as const };
const GET_REQUEST = new Request("http://localhost/api/v1/properties", { method: "GET" });

beforeEach(() => {
  vi.clearAllMocks();
});

describe("resolveApiV1Ctx", () => {
  it("returns a generic 401 when there is no authenticated Clerk user", async () => {
    authMock.mockResolvedValue({ userId: null });

    const result = await resolveApiV1Ctx(GET_REQUEST);

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected failure");
    expect(result.response.status).toBe(401);
    const body = await result.response.json();
    expect(body).toEqual({ error: { code: "unauthorized", message: expect.any(String) } });
    expect(ctxFromMcpAuthMock).not.toHaveBeenCalled();
    expect(allowedMock).not.toHaveBeenCalled();
    expect(loggerMock.info).toHaveBeenCalledWith("api-v1-auth: missing-clerk-user");
  });

  it("uses acceptsToken: session_token so a Bearer session token (not just a cookie) is accepted", async () => {
    authMock.mockResolvedValue({ userId: null });

    await resolveApiV1Ctx(GET_REQUEST);

    expect(authMock).toHaveBeenCalledWith({ acceptsToken: "session_token" });
  });

  it("returns a generic 401 (never the caught error's message) when ctxFromMcpAuth cannot resolve a Ctx", async () => {
    authMock.mockResolvedValue({ userId: CLERK_USER_ID });
    ctxFromMcpAuthMock.mockRejectedValue(new Error("super secret internal detail"));

    const result = await resolveApiV1Ctx(GET_REQUEST);

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected failure");
    expect(result.response.status).toBe(401);
    const body = await result.response.json();
    expect(body.error.code).toBe("unauthorized");
    expect(JSON.stringify(body)).not.toContain("super secret internal detail");
    expect(allowedMock).not.toHaveBeenCalled();
    expect(loggerMock.info).toHaveBeenCalledWith("api-v1-auth: identity-resolution-failed");
  });

  it("returns 429 when the dedicated read-API rate limiter rejects the resolved user", async () => {
    authMock.mockResolvedValue({ userId: CLERK_USER_ID });
    ctxFromMcpAuthMock.mockResolvedValue(CTX);
    allowedMock.mockResolvedValue(false);

    const result = await resolveApiV1Ctx(GET_REQUEST);

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected failure");
    expect(result.response.status).toBe(429);
    const body = await result.response.json();
    expect(body).toEqual({ error: { code: "rate_limited", message: expect.any(String) } });
    // Keyed on the resolved internal userId, not the raw Clerk id.
    expect(allowedMock).toHaveBeenCalledWith(readLimiter, CTX.userId);
    expect(allowedMock).not.toHaveBeenCalledWith(mutationLimiter, expect.anything());
  });

  it("resolves ok:true with the Ctx when auth, org resolution, and rate limit all succeed", async () => {
    authMock.mockResolvedValue({ userId: CLERK_USER_ID });
    ctxFromMcpAuthMock.mockResolvedValue(CTX);
    allowedMock.mockResolvedValue(true);

    const result = await resolveApiV1Ctx(GET_REQUEST);

    expect(result).toEqual({ ok: true, ctx: CTX });
    // provisionIfMissing:true -> this read-only surface can JIT-provision a user if the logic allows.
    expect(ctxFromMcpAuthMock).toHaveBeenCalledWith(CLERK_USER_ID, { provisionIfMissing: true });
  });
});

// The demo short-circuit hands out a fixed ORG-0001 owner Ctx with no authentication at all.
// In production that is a full auth bypass, so a demo/staging flag there must fail CLOSED
// (refuse the request) rather than short-circuit — and rather than silently fall through.
describe("resolveApiV1Ctx demo short-circuit hardening", () => {
  afterEach(() => {
    vi.unstubAllEnvs();
  });

  it.each(["STAGING_DEMO_MODE", "DEMO_MODE"])(
    "fails closed in production when %s=true, never returning the demo owner ctx",
    async (flag) => {
      vi.stubEnv("NODE_ENV", "production");
      vi.stubEnv(flag, "true");
      // Even with a valid Clerk user + limiter available, the misconfig must not resolve a Ctx.
      authMock.mockResolvedValue({ userId: CLERK_USER_ID });
      ctxFromMcpAuthMock.mockResolvedValue(CTX);
      allowedMock.mockResolvedValue(true);

      const result = await resolveApiV1Ctx(GET_REQUEST);

      expect(result.ok).toBe(false);
      if (result.ok) throw new Error("expected failure");
      expect(result.response.status).toBe(500);
      const body = await result.response.json();
      expect(body).toEqual({ error: { code: "internal_error", message: expect.any(String) } });
      expect(authMock).not.toHaveBeenCalled();
      expect(ctxFromMcpAuthMock).not.toHaveBeenCalled();
    },
  );

  it.each(["STAGING_DEMO_MODE", "DEMO_MODE"])(
    "still short-circuits to the demo ctx outside production when %s=true (staging preview)",
    async (flag) => {
      vi.stubEnv("NODE_ENV", "development");
      vi.stubEnv(flag, "true");

      const result = await resolveApiV1Ctx(GET_REQUEST);

      expect(result).toEqual({ ok: true, ctx: { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" } });
      expect(authMock).not.toHaveBeenCalled();
    },
  );
});
