import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ---------------------------------------------------------------------------
// resolveApiV1Ctx is the single auth seam for every HTTP API v1 route:
//   Clerk bearer session token -> ctxFromMcpAuth (reused, not duplicated) -> rate limit.
// Fully mocked: no real Clerk, no DB, no network. Proves each failure mode returns the
// stable { error: { code, message } } shape and never leaks a caught error's message.
// ---------------------------------------------------------------------------

const { authMock, ctxFromMcpAuthMock, allowedMock, loggerMock, mockEnv } = vi.hoisted(() => ({
  authMock: vi.fn(),
  ctxFromMcpAuthMock: vi.fn(),
  allowedMock: vi.fn(),
  loggerMock: {
    info: vi.fn(),
    warn: vi.fn(),
    error: vi.fn(),
    debug: vi.fn(),
    child: vi.fn().mockReturnThis(),
  },
  mockEnv: { CLERK_SECRET_KEY: undefined as string | undefined },
}));

vi.mock("@clerk/nextjs/server", () => ({
  auth: authMock,
}));

vi.mock("@/lib/env", () => ({
  env: mockEnv,
}));

vi.mock("@/mcp-server/ctxFor", () => ({
  ctxFromMcpAuth: ctxFromMcpAuthMock,
}));

vi.mock("@/lib/ratelimit", () => ({
  apiReadLimiter: { limit: vi.fn() },
  allowed: allowedMock,
}));

vi.mock("@/lib/logger", () => ({
  logger: loggerMock,
}));

import { resolveApiV1Ctx } from "./auth";

const CLERK_USER_ID = "user_abc123";
const CTX = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" as const };
const DEMO_CTX = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" as const };

// A realistic *shape* for a Clerk secret that is deliberately NOT a real credential.
// isRealClerkKey() treats any non-empty value other than the DEMO_CLERK_SENTINEL as
// "real", so this fixture drives the guard down the same path a real configured key
// would — proving DEMO_MODE alone cannot bypass Clerk when a real key is present.
const REAL_CLERK_KEY_FIXTURE = "sk_test_not_a_real_secret_fixture_0000000000000000";

beforeEach(() => {
  vi.clearAllMocks();
  mockEnv.CLERK_SECRET_KEY = undefined;
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("resolveApiV1Ctx demo-mode boundaries", () => {
  it("does not return the demo ctx for DEMO_MODE=true in production; falls through to real Clerk auth", async () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("DEMO_MODE", "true");
    authMock.mockResolvedValue({ userId: null });

    const result = await resolveApiV1Ctx();

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected failure");
    expect(result.response.status).toBe(401);
    const body = await result.response.json();
    expect(body).toEqual({ error: { code: "unauthorized", message: expect.any(String) } });
    expect(authMock).toHaveBeenCalledWith({ acceptsToken: "session_token" });
    expect(ctxFromMcpAuthMock).not.toHaveBeenCalled();
  });

  it("does not return the demo ctx for STAGING_DEMO_MODE=true in production; falls through to real Clerk auth", async () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("STAGING_DEMO_MODE", "true");
    authMock.mockResolvedValue({ userId: null });

    const result = await resolveApiV1Ctx();

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected failure");
    expect(result.response.status).toBe(401);
    const body = await result.response.json();
    expect(body).toEqual({ error: { code: "unauthorized", message: expect.any(String) } });
    expect(authMock).toHaveBeenCalledWith({ acceptsToken: "session_token" });
    expect(ctxFromMcpAuthMock).not.toHaveBeenCalled();
  });

  it("still returns the demo ctx for DEMO_MODE=true outside production/test (existing intended behavior)", async () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("DEMO_MODE", "true");

    const result = await resolveApiV1Ctx();

    expect(result).toEqual({ ok: true, ctx: DEMO_CTX });
    expect(authMock).not.toHaveBeenCalled();
    expect(ctxFromMcpAuthMock).not.toHaveBeenCalled();
  });

  it("does not return the demo ctx for DEMO_MODE=true in development when a real CLERK_SECRET_KEY is configured; falls through to real Clerk auth and 401s when no user exists", async () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("DEMO_MODE", "true");
    // A real key configured alongside DEMO_MODE means DEMO_MODE was left on by mistake:
    // the guard must fall through to real Clerk auth rather than grant demo access.
    mockEnv.CLERK_SECRET_KEY = REAL_CLERK_KEY_FIXTURE;
    authMock.mockResolvedValue({ userId: null });

    const result = await resolveApiV1Ctx();

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected failure");
    expect(result.response.status).toBe(401);
    const body = await result.response.json();
    expect(body).toEqual({ error: { code: "unauthorized", message: expect.any(String) } });
    expect(authMock).toHaveBeenCalledWith({ acceptsToken: "session_token" });
    expect(ctxFromMcpAuthMock).not.toHaveBeenCalled();
  });

  it("still returns the demo ctx for STAGING_DEMO_MODE=true outside production/test (existing intended behavior)", async () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("STAGING_DEMO_MODE", "true");

    const result = await resolveApiV1Ctx();

    expect(result).toEqual({ ok: true, ctx: DEMO_CTX });
    expect(authMock).not.toHaveBeenCalled();
    expect(ctxFromMcpAuthMock).not.toHaveBeenCalled();
  });
});

describe("resolveApiV1Ctx", () => {
  it("returns a generic 401 when there is no authenticated Clerk user", async () => {
    authMock.mockResolvedValue({ userId: null });

    const result = await resolveApiV1Ctx();

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

    await resolveApiV1Ctx();

    expect(authMock).toHaveBeenCalledWith({ acceptsToken: "session_token" });
  });

  it("returns a generic 401 (never the caught error's message) when ctxFromMcpAuth cannot resolve a Ctx", async () => {
    authMock.mockResolvedValue({ userId: CLERK_USER_ID });
    ctxFromMcpAuthMock.mockRejectedValue(new Error("super secret internal detail"));

    const result = await resolveApiV1Ctx();

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

    const result = await resolveApiV1Ctx();

    expect(result.ok).toBe(false);
    if (result.ok) throw new Error("expected failure");
    expect(result.response.status).toBe(429);
    const body = await result.response.json();
    expect(body).toEqual({ error: { code: "rate_limited", message: expect.any(String) } });
    // Keyed on the resolved internal userId, not the raw Clerk id.
    expect(allowedMock).toHaveBeenCalledWith(expect.anything(), CTX.userId);
  });

  it("resolves ok:true with the Ctx when auth, org resolution, and rate limit all succeed", async () => {
    authMock.mockResolvedValue({ userId: CLERK_USER_ID });
    ctxFromMcpAuthMock.mockResolvedValue(CTX);
    allowedMock.mockResolvedValue(true);

    const result = await resolveApiV1Ctx();

    expect(result).toEqual({ ok: true, ctx: CTX });
    // provisionIfMissing:true -> this read-only surface can JIT-provision a user if the logic allows.
    expect(ctxFromMcpAuthMock).toHaveBeenCalledWith(CLERK_USER_ID, { provisionIfMissing: true });
  });
});
