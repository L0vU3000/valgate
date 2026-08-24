import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import type { Ctx } from "@/lib/services/_mapping";

const { resolveApiV1CtxMock, getPropertyMock, presignUploadMock, createDocumentMock } = vi.hoisted(() => ({
  resolveApiV1CtxMock: vi.fn(),
  getPropertyMock: vi.fn(),
  presignUploadMock: vi.fn(),
  createDocumentMock: vi.fn(),
}));

vi.mock("./auth", () => ({
  resolveApiV1Ctx: resolveApiV1CtxMock,
}));

vi.mock("@/lib/services/properties", () => ({
  getProperty: getPropertyMock,
}));

vi.mock("@/lib/services/storage", () => ({
  presignUpload: presignUploadMock,
}));

vi.mock("@/lib/services/documents", () => ({
  createDocument: createDocumentMock,
}));

import { POST } from "@/app/api/v1/properties/[id]/documents/route";

const CTX: Ctx = { userId: "USR-0001", orgId: "ORG-0001", orgRole: "owner" };
const PROPERTY = { id: "PROP-0001" };
const DOCUMENT = {
  id: "DOC-0001",
  propertyId: "PROP-0001",
  name: "title.pdf",
  kind: "document",
  mimeType: "application/pdf",
  sizeBytes: 3,
  storageId: "ORG-0001/DOC-0001/title.pdf",
  thumbStorageId: "ORG-0001/DOC-0001/thumb.jpg",
  uploadedAt: 1_725_000_000_000,
};

const fetchMock = vi.fn();

function params(id = "PROP-0001") {
  return { params: Promise.resolve({ id }) };
}

function multipartRequest(file: File | null, extra: Record<string, string> = {}) {
  const body = new FormData();
  if (file) body.append("file", file);
  for (const [key, value] of Object.entries(extra)) body.append(key, value);
  return new Request("http://localhost/api/v1/properties/PROP-0001/documents", {
    method: "POST",
    body,
  });
}

beforeEach(() => {
  vi.stubGlobal("fetch", fetchMock);
  vi.clearAllMocks();
  resolveApiV1CtxMock.mockResolvedValue({ ok: true, ctx: CTX });
  getPropertyMock.mockResolvedValue(PROPERTY);
  presignUploadMock.mockResolvedValue({
    url: "https://storage.invalid/upload",
    fields: { key: "server-generated" },
    storageId: DOCUMENT.storageId,
  });
  createDocumentMock.mockResolvedValue(DOCUMENT);
  fetchMock.mockResolvedValue({ ok: true });
});

afterEach(() => {
  vi.unstubAllGlobals();
});

describe("POST /api/v1/properties/[id]/documents", () => {
  it("returns the auth seam response before parsing or touching storage", async () => {
    resolveApiV1CtxMock.mockResolvedValue({
      ok: false,
      response: new Response(JSON.stringify({ error: { code: "unauthorized" } }), { status: 401 }),
    });

    const response = await POST(multipartRequest(new File(["pdf"], "title.pdf", { type: "application/pdf" })), params());

    expect(response.status).toBe(401);
    expect(getPropertyMock).not.toHaveBeenCalled();
    expect(presignUploadMock).not.toHaveBeenCalled();
    expect(createDocumentMock).not.toHaveBeenCalled();
  });

  it("uploads a valid same-org file and returns a public document DTO with no storage identifiers", async () => {
    const response = await POST(
      multipartRequest(new File(["pdf"], "title.pdf", { type: "application/pdf" })),
      params(),
    );

    expect(response.status).toBe(201);
    expect(presignUploadMock).toHaveBeenCalledWith(CTX, {
      name: "title.pdf",
      mimeType: "application/pdf",
      sizeBytes: 3,
    });
    expect(fetchMock).toHaveBeenCalledWith("https://storage.invalid/upload", expect.objectContaining({
      method: "POST",
    }));
    expect(createDocumentMock).toHaveBeenCalledWith(CTX, expect.objectContaining({
      propertyId: "PROP-0001",
      storageId: DOCUMENT.storageId,
      kind: "document",
    }));
    const body = await response.json();
    expect(body).toEqual({
      id: DOCUMENT.id,
      propertyId: DOCUMENT.propertyId,
      name: DOCUMENT.name,
      kind: DOCUMENT.kind,
      mimeType: DOCUMENT.mimeType,
      sizeBytes: DOCUMENT.sizeBytes,
      uploadedAt: DOCUMENT.uploadedAt,
    });
    expect(JSON.stringify(body)).not.toContain("storageId");
    expect(JSON.stringify(body)).not.toContain("thumbStorageId");
  });

  it("returns 404 before storage when the property is missing or outside the caller org", async () => {
    getPropertyMock.mockResolvedValue(null);

    const response = await POST(
      multipartRequest(new File(["pdf"], "title.pdf", { type: "application/pdf" })),
      params(),
    );

    expect(response.status).toBe(404);
    expect(presignUploadMock).not.toHaveBeenCalled();
    expect(createDocumentMock).not.toHaveBeenCalled();
  });

  it("rejects client-supplied storage IDs before storage or persistence", async () => {
    const response = await POST(
      multipartRequest(
        new File(["pdf"], "title.pdf", { type: "application/pdf" }),
        { storageId: "ORG-OTHER/SECRET.pdf" },
      ),
      params(),
    );

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body.error.code).toBe("invalid_request");
    expect(presignUploadMock).not.toHaveBeenCalled();
    expect(createDocumentMock).not.toHaveBeenCalled();
  });

  it("rejects disallowed files before storage or persistence", async () => {
    const response = await POST(
      multipartRequest(new File(["unsafe"], "malware.exe", { type: "application/x-msdownload" })),
      params(),
    );

    expect(response.status).toBe(400);
    const body = await response.json();
    expect(body.error.code).toBe("invalid_request");
    expect(presignUploadMock).not.toHaveBeenCalled();
    expect(createDocumentMock).not.toHaveBeenCalled();
  });

  it("returns a generic 500 and creates no document when object storage rejects the presigned upload", async () => {
    fetchMock.mockResolvedValue({ ok: false });

    const response = await POST(
      multipartRequest(new File(["pdf"], "title.pdf", { type: "application/pdf" })),
      params(),
    );

    expect(response.status).toBe(500);
    const body = await response.json();
    expect(body.error.code).toBe("internal_error");
    expect(createDocumentMock).not.toHaveBeenCalled();
  });
});
