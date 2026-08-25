import "server-only";
import { NextResponse } from "next/server";
import { resolveApiV1Ctx } from "@/lib/api/v1/auth";
import { apiError } from "@/lib/api/v1/http";
import { toLeaseSummaryDto } from "@/lib/api/v1/dto";
import { getProperty } from "@/lib/services/properties";
import { listLeases } from "@/lib/services/leases";
import { logger } from "@/lib/logger";

// This route hits the database per request — never statically prerender.
export const dynamic = "force-dynamic";

// GET /api/v1/properties/[id]/leases — org-scoped lease listing, public summary fields only.
export async function GET(request: Request, { params }: { params: Promise<{ id: string }> }) {
  const authResult = await resolveApiV1Ctx();
  if (!authResult.ok) return authResult.response;

  const { id } = await params;

  try {
    // getProperty is org-scoped, so a missing/cross-org property is a plain 404 — resolved
    // before leases are ever listed.
    const property = await getProperty(authResult.ctx, id);
    if (!property) {
      return apiError(404, "not_found", "Property not found.");
    }

    const leases = await listLeases(authResult.ctx, id);
    return NextResponse.json(leases.map(toLeaseSummaryDto));
  } catch (err) {
    logger.error("GET /api/v1/properties/[id]/leases failed", { error: String(err) });
    return apiError(500, "internal_error", "Something went wrong. Please try again.");
  }
}
