import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Ctx } from "@/lib/services/_mapping";

const { resolveApiV1CtxMock, getPropertyMock, listOwnershipRecordsMock } = vi.hoisted(() => ({
  resolveApiV1CtxMock: vi.fn(),
  getPropertyMock: vi.fn(),
  listOwnershipRecordsMock: vi.fn(),
}));

vi.mock("./auth", () => ({
  resolveApiV1Ctx: resolveApiV1CtxMock,
}));

vi.mock("@/lib/services/properties", () => ({
  getProperty: getPropertyMock,
}));

vi.mock("@/lib/services/ownership-records", () => ({
  listOwnershipRecords: listOwnershipRecordsMock,
}));

import { GET } from "@/app/api/v1/properties/[id]/ownership/route";

const CTX: Ctx = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" };
const PROPERTY = { id: "PROP-0001" };
const OWNERSHIP_RECORD = {
  id: "OREC-0001",
  propertyId: "PROP-0001",
  holdingType: "Sole Ownership",
  loanType: "Fixed",
  loanAmount: 300000,
  loanTermYears: 30,
  interestRate: 5.5,
  originationDate: 1_700_000_000_000,
  maturityDate: 1_900_000_000_000,
  nextPaymentDue: 1_760_000_000_000,
  lenderName: "Acme Bank",
  downPayment: 60000,
  closingCosts: 5000,
  distributionMethod: "Equal Split",
  verified: true,
  verifiedAt: 1_701_000_000_000,
  evidenceDocIds: ["DOC-SECRET-0001"],
  createdAt: 1_690_000_000_000,
  updatedAt: 1_701_000_000_000,
};

function params(id = "PROP-0001") {
  return { params: Promise.resolve({ id }) };
}

beforeEach(() => {
  vi.clearAllMocks();
  resolveApiV1CtxMock.mockResolvedValue({ ok: true, ctx: CTX });
  getPropertyMock.mockResolvedValue(PROPERTY);
  listOwnershipRecordsMock.mockResolvedValue([OWNERSHIP_RECORD]);
});

afterEach(() => {
  vi.restoreAllMocks();
});

describe("GET /api/v1/properties/[id]/ownership", () => {
  it("returns the auth seam response before resolving the property or the ownership record", async () => {
    resolveApiV1CtxMock.mockResolvedValue({
      ok: false,
      response: new Response(JSON.stringify({ error: { code: "unauthorized" } }), { status: 401 }),
    });

    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/ownership"), params());

    expect(response.status).toBe(401);
    expect(getPropertyMock).not.toHaveBeenCalled();
    expect(listOwnershipRecordsMock).not.toHaveBeenCalled();
  });

  it("returns 404 and never looks up ownership when the property is missing or outside the caller org", async () => {
    getPropertyMock.mockResolvedValue(null);
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/ownership"), params());
    expect(response.status).toBe(404);
    const body = await response.json();
    expect(body.error.code).toBe("not_found");
    expect(listOwnershipRecordsMock).not.toHaveBeenCalled();
  });

  it("returns null when the property exists but has no ownership record yet", async () => {
    listOwnershipRecordsMock.mockResolvedValue([]);
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/ownership"), params());
    expect(response.status).toBe(200);
    const body = await response.json();
    expect(body).toBeNull();
  });

  it("returns the org-scoped ownership record as a public DTO with exactly the allowed fields", async () => {
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/ownership"), params());
    expect(response.status).toBe(200);
    expect(getPropertyMock).toHaveBeenCalledWith(CTX, "PROP-0001");
    expect(listOwnershipRecordsMock).toHaveBeenCalledWith(CTX, "PROP-0001");

    const body = await response.json();
    expect(body).toEqual({
      id: OWNERSHIP_RECORD.id,
      holdingType: OWNERSHIP_RECORD.holdingType,
      loanType: OWNERSHIP_RECORD.loanType,
      loanAmount: OWNERSHIP_RECORD.loanAmount,
      loanTermYears: OWNERSHIP_RECORD.loanTermYears,
      interestRate: OWNERSHIP_RECORD.interestRate,
      originationDate: OWNERSHIP_RECORD.originationDate,
      maturityDate: OWNERSHIP_RECORD.maturityDate,
      nextPaymentDue: OWNERSHIP_RECORD.nextPaymentDue,
      lenderName: OWNERSHIP_RECORD.lenderName,
      downPayment: OWNERSHIP_RECORD.downPayment,
      closingCosts: OWNERSHIP_RECORD.closingCosts,
      distributionMethod: OWNERSHIP_RECORD.distributionMethod,
      verified: OWNERSHIP_RECORD.verified,
    });
    expect(Object.keys(body).sort()).toEqual(
      [
        "closingCosts",
        "distributionMethod",
        "downPayment",
        "holdingType",
        "id",
        "interestRate",
        "lenderName",
        "loanAmount",
        "loanTermYears",
        "loanType",
        "maturityDate",
        "nextPaymentDue",
        "originationDate",
        "verified",
      ].sort(),
    );
    expect(JSON.stringify(body)).not.toContain("propertyId");
    expect(JSON.stringify(body)).not.toContain("evidenceDocIds");
    expect(JSON.stringify(body)).not.toContain("DOC-SECRET-0001");
    expect(JSON.stringify(body)).not.toContain("verifiedAt");
    expect(JSON.stringify(body)).not.toContain("createdAt");
    expect(JSON.stringify(body)).not.toContain("updatedAt");
  });

  it("propagates a generic 500 when ownership lookup fails, never leaking the underlying error", async () => {
    listOwnershipRecordsMock.mockRejectedValue(new Error("db exploded: secret detail"));
    const response = await GET(new Request("http://localhost/api/v1/properties/PROP-0001/ownership"), params());
    expect(response.status).toBe(500);
    const body = await response.json();
    expect(body.error.code).toBe("internal_error");
    expect(JSON.stringify(body)).not.toContain("secret detail");
  });
});
