/**
 * Scam Detection Edge Function (R-35 / E06)
 *
 * Synchronous per-message call from E04 messaging pipeline.
 * Delegates scanning to scan_engine.ts (pure logic, no side-effects).
 *
 * Auth: verify_jwt = false — called with service_role key by E04 backend.
 * Validation: Zod schema per CLAUDE.md §9.
 *
 * Latency target: <1s (no external API calls, pure regex + keyword matching).
 *
 * If confidence != "none", calls flag_message_scam RPC to atomically
 * update the message and insert into moderation_queue.
 *
 * Reference: docs/epics/E06-trust-moderation.md
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { verifyServiceRole } from "../_shared/auth.ts";
import { jsonResponse } from "../_shared/response.ts";
import { scanMessage } from "./scan_engine.ts";

// ---------------------------------------------------------------------------
// Zod schema — §9: Edge Functions use Zod for input validation
// ---------------------------------------------------------------------------

const ScanRequestSchema = z.object({
  message_id: z.string().uuid("message_id must be a valid UUID"),
  conversation_id: z.string().uuid("conversation_id must be a valid UUID"),
  text: z.string().max(10000, "text exceeds max length"),
});

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }

  const parsed = ScanRequestSchema.safeParse(body);
  if (!parsed.success) {
    return jsonResponse({ error: parsed.error.flatten() }, 400);
  }
  const request = parsed.data;

  // Scan the message
  const result = scanMessage(request.text);

  // If flagged, persist to DB via RPC.
  // The `persisted` field tells the caller whether the flag was written to
  // the moderation_queue. If false, the caller should retry or alert.
  let persisted: boolean | null = null;
  let dbError: string | undefined;

  if (result.confidence !== "none") {
    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      console.error("[scam-detection] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY");
      return jsonResponse({ error: "Internal server configuration error" }, 500);
    }

    try {
      const supabase = createClient(supabaseUrl, serviceRoleKey);

      const { error } = await supabase.rpc("flag_message_scam", {
        p_message_id: request.message_id,
        p_conversation_id: request.conversation_id,
        p_confidence: result.confidence,
        p_reasons: result.reasons,
      });

      if (error) {
        persisted = false;
        dbError = error.message;
        console.error(`[scam-detection] flag_message_scam RPC error: ${error.message}`);
      } else {
        persisted = true;
      }
    } catch (err) {
      persisted = false;
      dbError = (err as Error).message;
      console.error(`[scam-detection] DB error: ${dbError}`);
    }
  }

  return jsonResponse({
    message_id: request.message_id,
    confidence: result.confidence,
    reasons: result.reasons,
    score: result.score,
    ...(persisted !== null && { persisted }),
    ...(dbError && { db_error: dbError }),
  });
});
