import "server-only";
import { NextResponse } from "next/server";
import { resolveApiV1Ctx } from "@/lib/api/v1/auth";
import { apiError } from "@/lib/api/v1/http";
import { toPropertyDetailDto } from "@/lib/api/v1/dto";
import { getProperty, updateProperty, deleteProperty } from "@/lib/services/properties";
import { PropertyPatchSchema } from "@/lib/data/types/property";
import { logger } from "@/lib/logger";

// This route hits the database per request and reads request auth — never statically prerender.
export const dynamic = "force-dynamic";

// GET /api/v1/properties/[id] — a single property's detail DTO, org-scoped.
export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  try {
    // getProperty is already org-scoped (WHERE orgId = ctx.orgId), so a property that doesn't
    // exist and one that exists in another org are indistinguishable here — both are a plain 404.
    const property = await getProperty(authResult.ctx, id);
    if (!property) {
      return apiError(404, "not_found", "Property not found.");
    }

    return NextResponse.json(toPropertyDetailDto(property));
  } catch (err) {
    // Fail closed: an unexpected service/serialization error is logged server-side and never
    // echoed to the client — the response is always the fixed, generic 500 envelope.
    logger.error("GET /api/v1/properties/[id] failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}

// PATCH /api/v1/properties/[id] — update a property, org-scoped.
export async function PATCH(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  let body: unknown;
  try {
    body = await request.json();
  } catch {
    return apiError(400, "invalid_request", "Request body must be valid JSON.");
  }

  const parsed = PropertyPatchSchema.safeParse(body);
  if (!parsed.success) {
    return apiError(400, "invalid_request", "Invalid property patch data.");
  }

  try {
    const property = await updateProperty(authResult.ctx, id, parsed.data);
    if (!property) {
      return apiError(404, "not_found", "Property not found.");
    }
    return NextResponse.json(toPropertyDetailDto(property));
  } catch (err) {
    logger.error("PATCH /api/v1/properties/[id] failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}

// DELETE /api/v1/properties/[id] — delete a property, org-scoped.
export async function DELETE(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  try {
    // deleteProperty is org-scoped and idempotent: deleting a non-existent or cross-org property
    // is silently treated as success (no leak that the id exists elsewhere).
    await deleteProperty(authResult.ctx, id);
    return new NextResponse(null, { status: 204 });
  } catch (err) {
    logger.error("DELETE /api/v1/properties/[id] failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}
