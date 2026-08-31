import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ---------------------------------------------------------------------------
// assertCanMutate is the write guard every mutating service calls. A demo/staging
// configuration reaching production means an unauthenticated ORG-0001 owner context is in
// play, so writes must refuse there — including when DEMO_ALLOW_WRITES (a local-dev-only
// escape hatch) is switched on.
// ---------------------------------------------------------------------------

const { envMock } = vi.hoisted(() => ({
  envMock: { DEMO_MODE: false, DEMO_ALLOW_WRITES: false },
}));

vi.mock("@/lib/env", () => ({ env: envMock }));
vi.mock("@/lib/db/client", () => ({ db: { execute: vi.fn() } }));

import { assertCanMutate } from "./_mapping";

beforeEach(() => {
  envMock.DEMO_MODE = false;
  envMock.DEMO_ALLOW_WRITES = false;
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("assertCanMutate in production", () => {
  it("refuses writes when DEMO_MODE is on, even with DEMO_ALLOW_WRITES=true", () => {
    vi.stubEnv("NODE_ENV", "production");
    envMock.DEMO_MODE = true;
    envMock.DEMO_ALLOW_WRITES = true;

    expect(() => assertCanMutate()).toThrow();
  });

  it("refuses writes when STAGING_DEMO_MODE=true, even with DEMO_ALLOW_WRITES=true", () => {
    vi.stubEnv("NODE_ENV", "production");
    vi.stubEnv("STAGING_DEMO_MODE", "true");
    envMock.DEMO_ALLOW_WRITES = true;

    expect(() => assertCanMutate()).toThrow();
  });

  it("allows writes with no demo configuration at all", () => {
    vi.stubEnv("NODE_ENV", "production");

    expect(() => assertCanMutate()).not.toThrow();
  });
});

describe("assertCanMutate outside production (unchanged)", () => {
  it("refuses writes in DEMO_MODE", () => {
    vi.stubEnv("NODE_ENV", "development");
    envMock.DEMO_MODE = true;

    expect(() => assertCanMutate()).toThrow("Demo is read-only");
  });

  it("allows writes in DEMO_MODE when DEMO_ALLOW_WRITES=true (local dev escape hatch)", () => {
    vi.stubEnv("NODE_ENV", "development");
    envMock.DEMO_MODE = true;
    envMock.DEMO_ALLOW_WRITES = true;

    expect(() => assertCanMutate()).not.toThrow();
  });

  it("allows writes with STAGING_DEMO_MODE=true (staging preview stays writable)", () => {
    vi.stubEnv("NODE_ENV", "development");
    vi.stubEnv("STAGING_DEMO_MODE", "true");

    expect(() => assertCanMutate()).not.toThrow();
  });
});
