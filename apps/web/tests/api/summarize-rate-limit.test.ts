import { describe, it, expect, vi, beforeEach } from "vitest";
import type { NextRequest } from "next/server";
import { POST as summarizeHandler } from "@/app/api/documents/[id]/summarize/route";
import { requireCtx } from "@/lib/auth/ctx";
import { getDocument, setDocumentAiStatus, saveDocumentSummary } from "@/lib/services/documents";
import { resolveDocumentUrl } from "@/lib/services/storage";
import { generateObject } from "ai";
import { allowed, aiSummaryLimiter } from "@/lib/ratelimit";

vi.mock("@/lib/auth/ctx", () => ({
  requireCtx: vi.fn(),
}));

vi.mock("@/lib/services/documents", () => ({
  getDocument: vi.fn(),
  setDocumentAiStatus: vi.fn(),
  saveDocumentSummary: vi.fn(),
}));

vi.mock("@/lib/services/storage", () => ({
  resolveDocumentUrl: vi.fn(),
}));

vi.mock("ai", () => ({
  generateObject: vi.fn(),
}));

vi.mock("@ai-sdk/openai", () => ({
  openai: vi.fn(() => "mock-model"),
}));

vi.mock("@/lib/ratelimit", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/ratelimit")>();
  return {
    ...actual,
    allowed: vi.fn(),
    aiSummaryLimiter: { limit: vi.fn() },
  };
});

describe("POST /api/documents/[id]/summarize rate limiting", () => {
  const ctx = { userId: "user-123", orgId: "org-1", orgRole: "owner" };
  const params = Promise.resolve({ id: "doc-1" });
  const req = new Request("http://localhost/api/documents/doc-1/summarize", { method: "POST" });

  const summary = { summary: "A lease.", keyFields: [], pageCount: 2 };

  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(requireCtx).mockResolvedValue(ctx);
    vi.mocked(getDocument).mockResolvedValue({ id: "doc-1", storageId: "s3-key", mimeType: "application/pdf" });
    vi.mocked(resolveDocumentUrl).mockResolvedValue("https://storage.test/doc-1");
    vi.mocked(generateObject).mockResolvedValue({ object: summary });
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ arrayBuffer: async () => new ArrayBuffer(8) }),
    );
  });

  it("allows request when rate limit is not exceeded", async () => {
    vi.mocked(allowed).mockResolvedValue(true);

    const res = await summarizeHandler(req as unknown as NextRequest, { params });
    expect(res.status).toBe(200);
    const data = await res.json();
    expect(data.ok).toBe(true);
    expect(data.summary).toEqual(summary);
    expect(generateObject).toHaveBeenCalledOnce();
    expect(saveDocumentSummary).toHaveBeenCalledWith(ctx, "doc-1", { ...summary, status: "ready" });
  });

  it("returns 429 when rate limit is exceeded", async () => {
    vi.mocked(allowed).mockResolvedValue(false);

    const res = await summarizeHandler(req as unknown as NextRequest, { params });
    expect(res.status).toBe(429);
    const data = await res.json();
    expect(data.ok).toBe(false);
    expect(data.error).toContain("rate limit");

    // The point of the limit: rejected BEFORE the model call, and before any storage/DB work.
    expect(generateObject).not.toHaveBeenCalled();
    expect(resolveDocumentUrl).not.toHaveBeenCalled();
    expect(getDocument).not.toHaveBeenCalled();
    // ...so a rejected request never leaves the row stuck in "generating".
    expect(setDocumentAiStatus).not.toHaveBeenCalled();
  });

  it("checks the summary limiter keyed on the caller's userId, after auth", async () => {
    vi.mocked(allowed).mockResolvedValue(false);

    await summarizeHandler(req as unknown as NextRequest, { params });
    expect(allowed).toHaveBeenCalledWith(aiSummaryLimiter, "user-123");
  });
});
