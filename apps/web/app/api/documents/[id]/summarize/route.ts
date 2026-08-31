import type { NextRequest } from "next/server";
import { z } from "zod";
import { generateObject } from "ai";
import { openai } from "@ai-sdk/openai";
import { requireCtx } from "@/lib/auth/ctx";
import { getDocument, setDocumentAiStatus, saveDocumentSummary } from "@/lib/services/documents";
import { resolveDocumentUrl } from "@/lib/services/storage";
import { allowed, aiSummaryLimiter } from "@/lib/ratelimit";
import { log } from "@/lib/log";

export const runtime = "nodejs"; // S3 + Neon need the Node runtime (not Edge)
export const maxDuration = 60;   // give the model time to read the whole file

// The shape we ask the model to return. generateObject validates the model output against this
// Zod schema, so we never parse free-form text — `object` is already the right shape or it throws.
const SummarySchema = z.object({
  summary: z.string().describe("2-4 plain sentences: what this document is and says"),
  keyFields: z.array(z.object({ label: z.string(), value: z.string() })),
  pageCount: z.number().int().nonnegative(),
});

// POST /api/documents/[id]/summarize
//
// Generates an AI summary for a single document, ON CLICK ONLY. The whole job runs inside this
// one request: authorize → read the file from storage → ask the model → store the result on the
// document row. Because it is stored, the model runs once; every later page view just reads the row.
//
// Authorization: requireCtx() identifies the caller's org; getDocument() is org-scoped, so a
// document belonging to another org returns null and we answer 404 (no IDOR, no info leak).
//
// Rate limit: 5 summaries / minute / user, checked AFTER auth and BEFORE any storage read, model
// call, or ai_status write. Ordering matters twice over — an over-limit caller neither reaches the
// model nor leaves the row stuck in "generating". Fail-closed (see lib/ratelimit).
//
// What can go wrong (all handled): requireCtx throws if unauthenticated (surfaces as a 500 from the
// framework); the file fetch or the model call can fail or time out — the try/catch logs the real
// error server-side, flips ai_status to "failed", and returns a generic message to the client.
export async function POST(_req: NextRequest, { params }: { params: Promise<{ id: string }> }) {
  const { id } = await params; // Next.js 15: params is a Promise — always await it
  const ctx = await requireCtx();

  if (!(await allowed(aiSummaryLimiter, ctx.userId))) {
    log.warn("ratelimit.block", { edge: "ai-summary", userId: ctx.userId, id });
    return Response.json(
      { ok: false, error: "AI summary rate limit reached. Try again shortly." },
      { status: 429, headers: { "Retry-After": "60" } },
    );
  }

  // Ownership check: org-scoped lookup. Another org's id (or a missing id) returns null.
  const doc = await getDocument(ctx, id);
  if (!doc) {
    return Response.json({ ok: false, error: "Not found" }, { status: 404 });
  }

  // Flip to "generating" first so a reload during the model call shows the spinner, not the
  // idle button. The Summary tab reads ai_status to decide which of its four states to render.
  await setDocumentAiStatus(ctx, id, "generating");

  try {
    // Resolve a short-lived URL for the stored file, then download its bytes so we can hand the
    // raw file straight to the model (gpt-4o-mini accepts PDF and image inputs — no OCR step).
    const fileUrl = await resolveDocumentUrl(doc.storageId);
    const response = await fetch(fileUrl);
    const fileBytes = new Uint8Array(await response.arrayBuffer());

    // One model call. The file part carries the document bytes; generateObject returns `object`
    // already validated against SummarySchema.
    const { object } = await generateObject({
      model: openai("gpt-4o-mini"), // cheap OpenAI mini, file input + structured output
      schema: SummarySchema,
      messages: [
        {
          role: "user",
          content: [
            { type: "text", text: "Summarize this property document and extract its key fields." },
            { type: "file", data: fileBytes, mediaType: doc.mimeType ?? "application/pdf" },
          ],
        },
      ],
    });

    // Store the result and mark it ready in a single write.
    await saveDocumentSummary(ctx, id, { ...object, status: "ready" });
    return Response.json({ ok: true, summary: object });
  } catch (err) {
    // Never leak internals to the client: log the real error, return a generic message, and leave
    // the row in "failed" so the Summary tab shows the error state with a working Retry button.
    log.error("documents.summarize.failed", err, { id });
    await setDocumentAiStatus(ctx, id, "failed");
    return Response.json({ ok: false, error: "Could not summarize this document." }, { status: 500 });
  }
}
