import "server-only";
import { NextResponse } from "next/server";
import { resolveApiV1Ctx } from "@/lib/api/v1/auth";
import { apiError } from "@/lib/api/v1/http";
import { toValuationSummaryDto } from "@/lib/api/v1/dto";
import { getProperty } from "@/lib/services/properties";
import { listPropertyValuations } from "@/lib/services/property-valuations";
import { logger } from "@/lib/logger";

// This route hits the database per request — never statically prerender.
export const dynamic = "force-dynamic";

// GET /api/v1/properties/[id]/valuations — org-scoped valuation listing, public fields only.
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  try {
    // getProperty is org-scoped, so a missing/cross-org property is a plain 404 — resolved
    // before valuations are ever listed.
    const property = await getProperty(authResult.ctx, id);
    if (!property) {
      return apiError(404, "not_found", "Property not found.");
    }

    const valuations = await listPropertyValuations(authResult.ctx, id);
    return NextResponse.json(valuations.map(toValuationSummaryDto));
  } catch (err) {
    logger.error("GET /api/v1/properties/[id]/valuations failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}
