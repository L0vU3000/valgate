import "server-only";
import { NextResponse } from "next/server";
import { resolveApiV1Ctx } from "@/lib/api/v1/auth";
import { apiError } from "@/lib/api/v1/http";
import { toDocumentUploadDto } from "@/lib/api/v1/dto";
import { getProperty } from "@/lib/services/properties";
import { presignUpload } from "@/lib/services/storage";
import { createDocument, listDocuments } from "@/lib/services/documents";
import { ALLOWED_MIME, MAX_BYTES } from "@/lib/upload-constants";
import { logger } from "@/lib/logger";

// This route hits the database and object storage per request — never statically prerender.
export const dynamic = "force-dynamic";

// POST /api/v1/properties/[id]/documents — mobile-safe single-file upload, org-scoped.
//
// Security contract: only one `file` multipart part is accepted — any other field (including
// a client-supplied storageId/thumbStorageId/category/verification data) or a second file value
// is rejected as invalid_request BEFORE the property lookup, presign, or persistence run. The
// file's MIME type and size are checked against the shared allow-list before storage. The
// property is resolved through the existing org-scoped getProperty first, so a missing or
// cross-org property is a 404 that never touches storage. Document `kind` is derived server-side
// from the file's MIME type — the client never supplies a storage key or id.
export async function POST(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  let formData: FormData;
  try {
    formData = await request.formData();
  } catch {
    return apiError(400, "invalid_request", "Request body must be multipart form data.");
  }

  let file: File | null = null;
  for (const [key, value] of formData.entries()) {
    if (key !== "file" || !(value instanceof File) || file) {
      return apiError(400, "invalid_request", "Only a single 'file' field is permitted.");
    }
    file = value;
  }
  if (!file || file.size === 0) {
    return apiError(400, "invalid_request", "A non-empty file is required.");
  }
  if (!ALLOWED_MIME.has(file.type) || file.size > MAX_BYTES) {
    return apiError(400, "invalid_request", "File type or size not allowed.");
  }

  try {
    // getProperty is org-scoped, so a missing/cross-org property is a plain 404 — resolved
    // before any storage or persistence call runs.
    const property = await getProperty(authResult.ctx, id);
    if (!property) {
      return apiError(404, "not_found", "Property not found.");
    }

    const presigned = await presignUpload(authResult.ctx, {
      name: file.name,
      mimeType: file.type,
      sizeBytes: file.size,
    });

    // Presigned-POST requires the fields first, file last.
    const uploadBody = new FormData();
    for (const [key, value] of Object.entries(presigned.fields)) {
      uploadBody.append(key, value);
    }
    uploadBody.append("file", file);
    const uploadResponse = await fetch(presigned.url, { method: "POST", body: uploadBody });
    if (!uploadResponse.ok) {
      return apiError(500, "internal_error", "Something went wrong. Please try again.");
    }

    const kind: "photo" | "document" = file.type.startsWith("image/") ? "photo" : "document";
    const created = await createDocument(authResult.ctx, {
      propertyId: id,
      name: file.name,
      kind,
      mimeType: file.type,
      sizeBytes: file.size,
      storageId: presigned.storageId,
      uploadedAt: Date.now(),
    });

    return NextResponse.json(toDocumentUploadDto(created), { status: 201 });
  } catch (err) {
    // Fail closed: never echo storage/service errors to the client — the response is always
    // the fixed, generic 500 envelope.
    logger.error("POST /api/v1/properties/[id]/documents failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}

// GET /api/v1/properties/[id]/documents — org-scoped document listing.
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  try {
    const property = await getProperty(authResult.ctx, id);
    if (!property) {
      return apiError(404, "not_found", "Property not found.");
    }

    const documents = await listDocuments(authResult.ctx, id);
    return NextResponse.json(documents.map(toDocumentUploadDto));
  } catch (err) {
    logger.error("GET /api/v1/properties/[id]/documents failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}
