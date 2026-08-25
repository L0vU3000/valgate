import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Ctx } from "@/lib/services/_mapping";

const { resolveApiV1CtxMock, getPropertyMock, listLeasesMock } = vi.hoisted(() => ({
  resolveApiV1CtxMock: vi.fn(),
  getPropertyMock: vi.fn(),
  listLeasesMock: vi.fn(),
}));

vi.mock("./auth", () => ({
  resolveApiV1Ctx: resolveApiV1CtxMock,
}));

vi.mock("@/lib/services/properties", () => ({
  getProperty: getPropertyMock,
}));

vi.mock("@/lib/services/leases", () => ({
  listLeases: listLeasesMock,
}));

import { GET } from "@/app/api/v1/properties/[id]/leases/route";

const CTX: Ctx = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" };
const PROPERTY = { id: "PROP-0001" };
const LEASE = {
  id: "LEASE-0001",
  propertyId: "PROP-0001",
  tenantId: "TEN-SECRET-0001",
  unit: "3B",
  stage: "Signed",
  startDate: 1_759_449_600_000,
  endDate: 1_790_985_600_000,
  monthlyRent: 850,
  termMonths: 12,
  renewalStatus: "pending",
};

function params(id = "PROP-0001") {
  return { params: Promise.resolve({ id }) };
}

beforeEach(() => {
  vi.clearAllMocks();
  resolveApiV1CtxMock.mockResolvedValue({ ok: true, ctx: CTX });
  getPropertyMock.mockResolvedValue(PROPERTY);
  listLeasesMock.mockResolvedValue([LEASE]);
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("GET /api/v1/properties/[id]/leases", () => {
  it("returns the auth seam response before resolving the property or listing leases", async () => {
    resolveApiV1CtxMock.mockResolvedValue({
      ok: false,
      response: new Response(JSON.stringify({ error: { code: "unauthorized" } }), { status: 401 }),
    });

    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/leases"), params());

    expect(response.status).toBe(401);
    expect(getPropertyMock).not.toHaveBeenCalled();
    expect(listLeasesMock).not.toHaveBeenCalled();
  });

  it("returns 404 and never lists leases when the property is missing or outside the caller org", async () => {
    getPropertyMock.mockResolvedValue(null);

    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/leases"), params());

    expect(response.status).toBe(404);
    const body = await response.json();
    expect(body.error.code).toBe("not_found");
    expect(listLeasesMock).not.toHaveBeenCalled();
  });

  it("returns the org-scoped lease list as public summary DTOs with no tenant linkage", async () => {
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/leases"), params());

    expect(response.status).toBe(200);
    expect(getPropertyMock).toHaveBeenCalledWith(CTX, "PROP-0001");
    expect(listLeasesMock).toHaveBeenCalledWith(CTX, "PROP-0001");
    const body = await response.json();
    expect(body).toEqual([
      {
        id: LEASE.id,
        propertyId: LEASE.propertyId,
        unit: LEASE.unit,
        stage: LEASE.stage,
        startDate: LEASE.startDate,
        endDate: LEASE.endDate,
        monthlyRent: LEASE.monthlyRent,
        termMonths: LEASE.termMonths,
        renewalStatus: LEASE.renewalStatus,
      },
    ]);
    expect(JSON.stringify(body)).not.toContain("tenantId");
    expect(JSON.stringify(body)).not.toContain("TEN-SECRET-0001");
  });

  it("propagates a generic 500 when lease lookup fails, never leaking the underlying error", async () => {
    listLeasesMock.mockRejectedValue(new Error("db exploded: secret detail"));

    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/leases"), params());

    expect(response.status).toBe(500);
    const body = await response.json();
    expect(body.error.code).toBe("internal_error");
    expect(JSON.stringify(body)).not.toContain("secret detail");
  });
});
