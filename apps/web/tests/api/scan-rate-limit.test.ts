import { describe, it, expect, vi, beforeEach } from "vitest";
import type { NextRequest } from "next/server";
import { POST as scanHandler } from "@/app/api/add-property/scan/route";
import { requireCtx } from "@/lib/auth/ctx";
import { scanDocument } from "@/lib/services/document-scan";
import { allowed } from "@/lib/ratelimit";
import type { Ctx } from "@/lib/services/_mapping";
import type { ExtractedProperty } from "@/lib/services/document-scan";

vi.mock("@/lib/auth/ctx", () => ({
  requireCtx: vi.fn(),
}));

vi.mock("@/lib/services/document-scan", () => ({
  scanDocument: vi.fn(),
}));

vi.mock("@/lib/ratelimit", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/ratelimit")>();
  return {
    ...actual,
    allowed: vi.fn(),
    aiScanLimiter: { limit: vi.fn() },
  };
});

describe("POST /api/add-property/scan rate limiting", () => {
  const ctx = { userId: "user-123", orgId: "org-1", orgRole: "owner" } satisfies Ctx;
  const extracted = {
    propertyName: "Test",
    propertyType: null,
    status: null,
    addressLine: null,
    addressLine2: null,
    city: null,
    province: null,
    zip: null,
    country: null,
    yearBuilt: null,
    totalArea: null,
    bedrooms: null,
    bathrooms: null,
    parkingSpaces: null,
    purchasePrice: null,
    currentMarketValue: null,
    purchaseDate: null,
    ownershipStatus: null,
  } satisfies ExtractedProperty;

  // A Request body can only be read once, so each test builds its own — sharing one instance
  // across tests makes the second req.formData() throw and masks the real status code.
  function makeReq() {
    const formData = new FormData();
    formData.append("file", new File(["test content"], "test.pdf", { type: "application/pdf" }));
    return new Request("http://localhost/api/add-property/scan", { method: "POST", body: formData });
  }

  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(requireCtx).mockResolvedValue(ctx);
    vi.mocked(scanDocument).mockResolvedValue({
      extracted,
      lowConfidence: [],
    });
  });

  it("allows request when rate limit is not exceeded", async () => {
    vi.mocked(allowed).mockResolvedValue(true);

    const res = await scanHandler(makeReq() as unknown as NextRequest);
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.ok).toBe(true);
  });

  it("returns 429 when rate limit is exceeded", async () => {
    vi.mocked(allowed).mockResolvedValue(false);

    const res = await scanHandler(makeReq() as unknown as NextRequest);
    expect(res.status).toBe(429);
    const data = await res.json();
    expect(data.ok).toBe(false);
    expect(data.error).toContain("rate limit");
    // Crucially: scanDocument should NOT be called
    expect(scanDocument).not.toHaveBeenCalled();
  });
});
