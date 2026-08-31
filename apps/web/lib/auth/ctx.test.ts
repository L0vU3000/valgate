import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ---------------------------------------------------------------------------
// resolveCtx's demo branch returns DEMO_CTX — a fixed ORG-0001 *owner* context with no
// authentication behind it. These tests pin the one rule that matters: in production no
// demo/staging flag combination may reach that return. Everything Clerk/DB is mocked.
// ---------------------------------------------------------------------------

const { authMock, currentUserMock, isRealClerkKeyMock, envMock } = vi.hoisted(() => ({
  authMock: vi.fn(),
  currentUserMock: vi.fn(),
  isRealClerkKeyMock: vi.fn(),
  envMock: { DEMO_MODE: false, CLERK_SECRET_KEY: undefined as string | undefined },
}));

// requireCtx is wrapped in React's cache(); outside a request scope we want the plain function.
vi.mock("react", async (importOriginal) => {
  const actual = await importOriginal<typeof import("react")>();
  return { ...actual, cache: (fn: unknown) => fn };
});

vi.mock("@clerk/nextjs/server", () => ({ auth: authMock, currentUser: currentUserMock }));
vi.mock("@/lib/auth/clerk-check", () => ({ isRealClerkKey: isRealClerkKeyMock }));
vi.mock("@/lib/env", () => ({ env: envMock }));
vi.mock("@/lib/db/client", () => ({ db: { select: vi.fn() } }));
vi.mock("@/lib/services/identity-sync", () => ({
  upsertOrg: vi.fn(),
  upsertUser: vi.fn(),
  upsertMembership: vi.fn(),
  ourOrgId: vi.fn(),
  ourUserId: vi.fn(),
  normaliseRole: vi.fn(),
}));

import { requireCtx } from "./ctx";

const DEMO_CTX = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" };

beforeEach(() => {
  vi.clearAllMocks();
  envMock.DEMO_MODE = false;
  envMock.CLERK_SECRET_KEY = undefined;
  isRealClerkKeyMock.mockReturnValue(false);
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("requireCtx in production", () => {
  it("refuses STAGING_DEMO_MODE=true instead of returning the demo owner ctx", async () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("STAGING_DEMO_MODE", "true");

    await expect(requireCtx()).rejects.toThrow();
    expect(authMock).not.toHaveBeenCalled();
  });

  it("refuses DEMO_MODE instead of returning the demo owner ctx", async () => {
    vi.stubEnv("NODE_ENV", "production");
    envMock.DEMO_MODE = true;

    await expect(requireCtx()).rejects.toThrow();
    expect(authMock).not.toHaveBeenCalled();
  });

  it("refuses DEMO_MODE even when STAGING_DEMO_MODE=true is also set", async () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("STAGING_DEMO_MODE", "true");
    envMock.DEMO_MODE = true;

    await expect(requireCtx()).rejects.toThrow();
    expect(authMock).not.toHaveBeenCalled();
  });
});

describe("requireCtx outside production (unchanged)", () => {
  it("returns the demo ctx for a Tailscale staging preview (STAGING_DEMO_MODE with a real Clerk key)", async () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("STAGING_DEMO_MODE", "true");
    isRealClerkKeyMock.mockReturnValue(true);

    await expect(requireCtx()).resolves.toEqual(DEMO_CTX);
  });

  it("returns the demo ctx for DEMO_MODE without a real Clerk key", async () => {
    vi.stubEnv("NODE_ENV", "development");
    envMock.DEMO_MODE = true;

    await expect(requireCtx()).resolves.toEqual(DEMO_CTX);
  });

  it("still refuses DEMO_MODE when a real CLERK_SECRET_KEY is configured", async () => {
    vi.stubEnv("NODE_ENV", "development");
    envMock.DEMO_MODE = true;
    isRealClerkKeyMock.mockReturnValue(true);

    await expect(requireCtx()).rejects.toThrow(/CLERK_SECRET_KEY/);
  });

  it("falls through to Clerk when no demo flag is set", async () => {
    vi.stubEnv("NODE_ENV", "development");
    authMock.mockResolvedValue({ userId: null, orgId: null, orgRole: null });

    await expect(requireCtx()).rejects.toThrow("unauthenticated");
    expect(authMock).toHaveBeenCalled();
  });
});
