import { z } from "zod";
import { propertyStatusSchema, propertyTitleSchema, propertyTypeChoiceSchema } from "@/lib/data/types/property";

// Public HTTP boundary for POST /api/v1/properties — the exact request shape published in
// packages/api-spec/valgate-api-v1.yaml, and nothing more. `.strict()` rejects any other key
// (storage ids, evidence-doc ids, user/org/client ids, financial-verification internals, etc.)
// with 400 instead of silently accepting or stripping them, since NewPropertySchema alone is
// too permissive for a public caller — it's the *internal* create shape, shared with services.
export const PropertyCreateRequestSchema = z
  .object({
    name: z.string().min(1),
    type: propertyTypeChoiceSchema,
    status: propertyStatusSchema,
    lat: z.number().min(-90).max(90),
    lng: z.number().min(-180).max(180),
    buyNumeric: z.number().nonnegative(),
    totalArea: z.string(),
    title: propertyTitleSchema,
    addressLine: z.string().optional(),
    city: z.string().optional(),
    province: z.string().optional(),
    zip: z.string().optional(),
    country: z.string().optional(),
  })
  .strict();

export type PropertyCreateRequest = z.infer<typeof PropertyCreateRequestSchema>;

// Public HTTP boundary for PATCH /api/v1/properties/{id} — the same safe field set as
// PropertyCreateRequestSchema, but partial (any subset may be omitted) and still `.strict()`
// so internal fields (photoStorageIds, evidence-doc ids, verification flags, etc.) are rejected
// with 400 rather than silently accepted by the broader internal PropertyPatch shape.
export const PropertyPatchRequestSchema = PropertyCreateRequestSchema.partial();
export type PropertyPatchRequest = z.infer<typeof PropertyPatchRequestSchema>;
