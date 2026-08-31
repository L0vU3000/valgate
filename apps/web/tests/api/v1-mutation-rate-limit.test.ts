import { describe, it, expect, vi, beforeEach } from "vitest";

// ---------------------------------------------------------------------------
// HTTP API v1 — mutations must be throttled by a DISTINCT, STRICTER limiter than reads.
//
// Today every v1 route (read or write) shares apiReadLimiter at 120/min. A write costs far
// more than a read (row creation, audit rows, downstream fan-out), so a client that is well
// under the read budget can still hammer the DB with 120 writes/min. These tests pin:
//   1. apiMutationLimiter exists, is a different limiter object, and is configured stricter.
//   2. POST /api/v1/properties, PATCH and DELETE /api/v1/properties/[id] check the MUTATION
//      limiter — and when it rejects, return 429 with NO service call (no write).
//   3. GET stays on the read limiter (mutations must not tighten the read surface).
//
// Everything below the limiter is mocked (no Clerk, no DB): the real code under test is
// resolveApiV1Ctx + the route handlers' wiring to it.
// ---------------------------------------------------------------------------

const {
  authMock,
  ctxFromMcpAuthMock,
  allowedMock,
  READ_LIMITER,
  MUTATION_LIMITER,
  listPropertiesPageMock,
  createPropertyMock,
  getPropertyMock,
  updatePropertyMock,
  deletePropertyMock,
  loggerMock,
} = vi.hoisted(() => ({
  authMock: vi.fn(),
  ctxFromMcpAuthMock: vi.fn(),
  allowedMock: vi.fn(),
  // Sentinel objects: identity is the assertion — "which limiter did the seam consult?"
  READ_LIMITER: { __limiter: "read" },
  MUTATION_LIMITER: { __limiter: "mutation" },
  listPropertiesPageMock: vi.fn(),
  createPropertyMock: vi.fn(),
  getPropertyMock: vi.fn(),
  updatePropertyMock: vi.fn(),
  deletePropertyMock: vi.fn(),
  loggerMock: { info: vi.fn(), warn: vi.fn(), error: vi.fn(), debug: vi.fn(), child: vi.fn().mockReturnThis() },
}));

vi.mock("@clerk/nextjs/server", () => ({ auth: authMock }));
vi.mock("@/mcp-server/ctxFor", () => ({ ctxFromMcpAuth: ctxFromMcpAuthMock }));
vi.mock("@/lib/ratelimit", () => ({
  apiReadLimiter: READ_LIMITER,
  apiMutationLimiter: MUTATION_LIMITER,
  allowed: allowedMock,
}));
vi.mock("@/lib/services/properties", () => ({
  listPropertiesPage: listPropertiesPageMock,
  createProperty: createPropertyMock,
  getProperty: getPropertyMock,
  updateProperty: updatePropertyMock,
  deleteProperty: deletePropertyMock,
}));
vi.mock("@/lib/logger", () => ({ logger: loggerMock }));

import { GET as listProperties, POST as createPropertyRoute } from "@/app/api/v1/properties/route";
import {
  PATCH as patchPropertyRoute,
  DELETE as deletePropertyRoute,
} from "@/app/api/v1/properties/[id]/route";

const CLERK_USER_ID = "user_abc123";
const CTX = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" as const };

// The rate-limit decision happens in the auth seam, BEFORE body parsing — so these tests
// deliberately send a minimal body rather than a schema-valid Property. A 400 from the body
// parser would still prove the limiter ran and let the request through, which is the only
// thing under test here.
const params = Promise.resolve({ id: "PROP-0001" });

function jsonReq(method: string, url = "http://localhost/api/v1/properties"): Request {
  return new Request(url, { method, body: JSON.stringify({}), headers: { "Content-Type": "application/json" } });
}

beforeEach(() => {
  vi.clearAllMocks();
  authMock.mockResolvedValue({ userId: CLERK_USER_ID });
  ctxFromMcpAuthMock.mockResolvedValue(CTX);
  allowedMock.mockResolvedValue(true);
});

describe("apiMutationLimiter configuration", () => {
  it("is a distinct limiter from apiReadLimiter and is configured strictly tighter", async () => {
    const actual = await vi.importActual<typeof import("@/lib/ratelimit")>("@/lib/ratelimit");

    expect(actual.apiMutationLimiter).toBeDefined();
    expect(actual.apiMutationLimiter).not.toBe(actual.apiReadLimiter);
    expect(actual.API_V1_MUTATION_LIMIT).toBeLessThan(actual.API_V1_READ_LIMIT);
  });
});

describe("POST /api/v1/properties", () => {
  it("checks the mutation limiter (not the read limiter)", async () => {
    await createPropertyRoute(jsonReq("POST"));

    expect(allowedMock).toHaveBeenCalledWith(MUTATION_LIMITER, CTX.userId);
    expect(allowedMock).not.toHaveBeenCalledWith(READ_LIMITER, expect.anything());
  });

  it("returns 429 and performs no write when the mutation limiter rejects", async () => {
    allowedMock.mockResolvedValue(false);

    const res = await createPropertyRoute(jsonReq("POST"));

    expect(res.status).toBe(429);
    expect(await res.json()).toEqual({ error: { code: "rate_limited", message: expect.any(String) } });
    expect(createPropertyMock).not.toHaveBeenCalled();
  });
});

describe("PATCH /api/v1/properties/[id]", () => {
  it("checks the mutation limiter (not the read limiter)", async () => {
    updatePropertyMock.mockResolvedValue({ id: "PROP-0001" });

    await patchPropertyRoute(jsonReq("PATCH", "http://localhost/api/v1/properties/PROP-0001"), { params });

    expect(allowedMock).toHaveBeenCalledWith(MUTATION_LIMITER, CTX.userId);
    expect(allowedMock).not.toHaveBeenCalledWith(READ_LIMITER, expect.anything());
  });

  it("returns 429 and performs no write when the mutation limiter rejects", async () => {
    allowedMock.mockResolvedValue(false);

    const res = await patchPropertyRoute(jsonReq("PATCH", "http://localhost/api/v1/properties/PROP-0001"), {
      params,
    });

    expect(res.status).toBe(429);
    expect(updatePropertyMock).not.toHaveBeenCalled();
  });
});

describe("DELETE /api/v1/properties/[id]", () => {
  it("checks the mutation limiter (not the read limiter)", async () => {
    deletePropertyMock.mockResolvedValue(undefined);

    await deletePropertyRoute(jsonReq("DELETE", "http://localhost/api/v1/properties/PROP-0001"), { params });

    expect(allowedMock).toHaveBeenCalledWith(MUTATION_LIMITER, CTX.userId);
    expect(allowedMock).not.toHaveBeenCalledWith(READ_LIMITER, expect.anything());
  });

  it("returns 429 and performs no delete when the mutation limiter rejects", async () => {
    allowedMock.mockResolvedValue(false);

    const res = await deletePropertyRoute(jsonReq("DELETE", "http://localhost/api/v1/properties/PROP-0001"), {
      params,
    });

    expect(res.status).toBe(429);
    expect(deletePropertyMock).not.toHaveBeenCalled();
  });
});

describe("GET /api/v1/properties", () => {
  it("stays on the read limiter — the stricter mutation budget must not apply to reads", async () => {
    listPropertiesPageMock.mockResolvedValue({ items: [], nextCursor: null });

    await listProperties(new Request("http://localhost/api/v1/properties"));

    expect(allowedMock).toHaveBeenCalledWith(READ_LIMITER, CTX.userId);
    expect(allowedMock).not.toHaveBeenCalledWith(MUTATION_LIMITER, expect.anything());
  });
});
