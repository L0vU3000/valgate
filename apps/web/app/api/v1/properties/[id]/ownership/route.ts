import "server-only";
import { NextResponse } from "next/server";
import { resolveApiV1Ctx } from "@/lib/api/v1/auth";
import { apiError } from "@/lib/api/v1/http";
import { toOwnershipDto } from "@/lib/api/v1/dto";
import { getProperty } from "@/lib/services/properties";
import { listOwnershipRecords } from "@/lib/services/ownership-records";
import { logger } from "@/lib/logger";

// This route hits the database per request — never statically prerender.
export const dynamic = "force-dynamic";

// GET /api/v1/properties/[id]/ownership — org-scoped ownership record, public fields only.
export async function GET(_request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  try {
    // getProperty is org-scoped, so a missing/cross-org property is a plain 404 — resolved
    // before the ownership record is ever looked up.
    const property = await getProperty(authResult.ctx, id);
    if (!property) {
      return apiError(404, "not_found", "Property not found.");
    }

    // Ownership records are one-per-property in practice; a property that hasn't set one
    // up yet returns null rather than 404 (the property itself was found).
    const [record] = await listOwnershipRecords(authResult.ctx, id);
    return NextResponse.json(record ? toOwnershipDto(record) : null);
  } catch (err) {
    logger.error("GET /api/v1/properties/[id]/ownership failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}
