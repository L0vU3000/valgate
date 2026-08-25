import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Ctx } from "@/lib/services/_mapping";

const { resolveApiV1CtxMock, getPropertyMock, listPropertyValuationsMock } = vi.hoisted(() => ({
  resolveApiV1CtxMock: vi.fn(),
  getPropertyMock: vi.fn(),
  listPropertyValuationsMock: vi.fn(),
}));

vi.mock("./auth", () => ({
  resolveApiV1Ctx: resolveApiV1CtxMock,
}));

vi.mock("@/lib/services/properties", () => ({
  getProperty: getPropertyMock,
}));

vi.mock("@/lib/services/property-valuations", () => ({
  listPropertyValuations: listPropertyValuationsMock,
}));

import { GET } from "@/app/api/v1/properties/[id]/valuations/route";

const CTX: Ctx = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" };
const PROPERTY = { id: "PROP-0001" };
const VALUATION = {
  id: "VAL-0001",
  propertyId: "PROP-0001",
  month: "Jan 2026",
  price: 450000,
  recordedAt: 1_759_449_600_000,
};

function params(id = "PROP-0001") {
  return { params: Promise.resolve({ id }) };
}

beforeEach(() => {
  vi.clearAllMocks();
  resolveApiV1CtxMock.mockResolvedValue({ ok: true, ctx: CTX });
  getPropertyMock.mockResolvedValue(PROPERTY);
  listPropertyValuationsMock.mockResolvedValue([VALUATION]);
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("GET /api/v1/properties/[id]/valuations", () => {
  it("returns the auth seam response before resolving the property or listing valuations", async () => {
    resolveApiV1CtxMock.mockResolvedValue({
      ok: false,
      response: new Response(JSON.stringify({ error: { code: "unauthorized" } }), { status: 401 }),
    });

    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/valuations"), params());

    expect(response.status).toBe(401);
    expect(getPropertyMock).not.toHaveBeenCalled();
    expect(listPropertyValuationsMock).not.toHaveBeenCalled();
  });

  it("returns 404 and never lists valuations when the property is missing or outside the caller org", async () => {
    getPropertyMock.mockResolvedValue(null);
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/valuations"), params());
    expect(response.status).toBe(404);
    const body = await response.json();
    expect(body.error.code).toBe("not_found");
    expect(listPropertyValuationsMock).not.toHaveBeenCalled();
  });

  it("returns the org-scoped valuation list as public DTOs with exactly the allowed fields", async () => {
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/valuations"), params());
    expect(response.status).toBe(200);
    expect(getPropertyMock).toHaveBeenCalledWith(CTX, "PROP-0001");
    expect(listPropertyValuationsMock).toHaveBeenCalledWith(CTX, "PROP-0001");

    const body = await response.json();
    expect(body).toEqual([
      {
        id: VALUATION.id,
        price: VALUATION.price,
        valuationDate: VALUATION.recordedAt,
        month: VALUATION.month,
        recordedAt: VALUATION.recordedAt,
      },
    ]);
    expect(Object.keys(body[0]).sort()).toEqual(["id", "month", "price", "recordedAt", "valuationDate"]);
    expect(JSON.stringify(body)).not.toContain("propertyId");
  });

  it("propagates a generic 500 when valuation lookup fails, never leaking the underlying error", async () => {
    listPropertyValuationsMock.mockRejectedValue(new Error("db exploded: secret detail"));
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/valuations"), params());
    expect(response.status).toBe(500);
    const body = await response.json();
    expect(body.error.code).toBe("internal_error");
    expect(JSON.stringify(body)).not.toContain("secret detail");
  });
});
