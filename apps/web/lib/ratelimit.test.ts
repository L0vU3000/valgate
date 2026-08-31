import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";

// ---------------------------------------------------------------------------
// The in-memory limiter is a per-instance Map — meaningless across serverless invocations,
// so in production it is effectively no rate limiting at all. Falling back to it because an
// UPSTASH_* var is missing is a silent security downgrade; production must fail CLOSED.
// ---------------------------------------------------------------------------

const { envMock } = vi.hoisted(() => ({
  envMock: {
    UPSTASH_REDIS_REST_URL: undefined as string | undefined,
    UPSTASH_REDIS_REST_TOKEN: undefined as string | undefined,
  },
}));

vi.mock("@/lib/env", () => ({ env: envMock }));
vi.mock("@upstash/redis", () => ({ Redis: class {} }));
vi.mock("@upstash/ratelimit", () => ({
  Ratelimit: class {
    static slidingWindow = () => ({});
    limit = async () => ({ success: true });
  },
}));

// NODE_ENV is "test" at import time, so the module-level limiters take the in-memory path.
import { makeLimiter, allowed } from "./ratelimit";

const URL = "https://example.upstash.io";
const TOKEN = "tok_test";

beforeEach(() => {
  envMock.UPSTASH_REDIS_REST_URL = undefined;
  envMock.UPSTASH_REDIS_REST_TOKEN = undefined;
});

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("makeLimiter in production", () => {
  it("fails closed when UPSTASH_REDIS_REST_URL is missing", () => {
    vi.stubEnv("NODE_ENV", "production");
    envMock.UPSTASH_REDIS_REST_TOKEN = TOKEN;

    expect(() => makeLimiter("rl:test", 5, "1 m", 60_000)).toThrow(/UPSTASH/);
  });

  it("fails closed when UPSTASH_REDIS_REST_TOKEN is missing", () => {
    vi.stubEnv("NODE_ENV", "production");
    envMock.UPSTASH_REDIS_REST_URL = URL;

    expect(() => makeLimiter("rl:test", 5, "1 m", 60_000)).toThrow(/UPSTASH/);
  });

  it("fails closed when both Upstash vars are missing", () => {
    vi.stubEnv("NODE_ENV", "production");

    expect(() => makeLimiter("rl:test", 5, "1 m", 60_000)).toThrow(/UPSTASH/);
  });

  it("builds an Upstash limiter when both vars are set", () => {
    vi.stubEnv("NODE_ENV", "production");
    envMock.UPSTASH_REDIS_REST_URL = URL;
    envMock.UPSTASH_REDIS_REST_TOKEN = TOKEN;

    expect(() => makeLimiter("rl:test", 5, "1 m", 60_000)).not.toThrow();
  });
});

describe("makeLimiter outside production (unchanged)", () => {
  it("falls back to the in-memory sliding window when Upstash is unconfigured", async () => {
    vi.stubEnv("NODE_ENV", "development");

    const limiter = makeLimiter("rl:test", 2, "1 m", 60_000);

    expect(await allowed(limiter, "user-1")).toBe(true);
    expect(await allowed(limiter, "user-1")).toBe(true);
    expect(await allowed(limiter, "user-1")).toBe(false);
    // Per-key window: a different id is unaffected.
    expect(await allowed(limiter, "user-2")).toBe(true);
  });
});

describe("allowed failure handling", () => {
  it("fails closed when the limiter backend rejects", async () => {
    const limiter = { limit: vi.fn().mockRejectedValue(new Error("redis unavailable")) };

    await expect(allowed(limiter, "user-1")).resolves.toBe(false);
  });
});
