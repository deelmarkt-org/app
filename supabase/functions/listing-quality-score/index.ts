/**
 * Listing Quality Score Edge Function (R-26 / E01)
 *
 * Authoritative server-side quality score for a listing draft.
 * Returns 0–100 with per-field breakdown and a `can_publish` gate at
 * [PUBLISH_THRESHOLD] (40). The client runs the same calculation in
 * CalculateQualityScoreUseCase for real-time UI feedback, but the publish
 * gate enforced by SupabaseListingCreationRepository is this EF's response.
 *
 * Auth: verify_jwt = true — called by Flutter client with user JWT.
 * Supabase gateway validates the JWT before the handler runs.
 *
 * Validation: Zod schema per CLAUDE.md §9.
 *
 * Pure calculation — no DB reads or writes. The scoring logic lives in
 * scoring_engine.ts so it can be unit-tested without the HTTP runtime.
 *
 * Reference: docs/epics/E01-listing-management.md §"Listing Quality Score"
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { z } from "zod";
import { jsonResponse } from "../_shared/response.ts";
import { calculateQualityScore } from "./scoring_engine.ts";

// ---------------------------------------------------------------------------
// Zod schema — §9: Edge Functions use Zod for input validation
// ---------------------------------------------------------------------------

// `category_l2_id` rejects empty strings via `.uuid()`.
// `condition` rejects empty strings via `.min(1)` — both fields are
// scored as `!== null` in scoring_engine.ts (matching the Dart
// CalculateQualityScoreUseCase), so empty strings must never reach
// the scoring logic.
const DraftSchema = z.object({
  photo_count: z.number().int().min(0).max(12),
  title: z.string().max(200),
  description: z.string().max(5000),
  price_cents: z.number().int().min(0).max(100_000_000),
  category_l2_id: z.string().uuid().nullable(),
  condition: z.string().min(1).max(50).nullable(),
});

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const parsed = DraftSchema.safeParse(body);
  if (!parsed.success) {
    return jsonResponse({ error: parsed.error.flatten() }, 400);
  }

  const result = calculateQualityScore(parsed.data);
  return jsonResponse(result as unknown as Record<string, unknown>);
});
