/**
 * R-20: Account deletion Edge Function (GDPR right-to-erasure).
 *
 * Flow:
 *   1. Verify JWT + rate limit
 *   2. Check for active transactions (block if any)
 *   3. Check for existing pending deletion (409 on duplicate)
 *   4. Call soft_delete_account RPC (atomic transaction):
 *      - Anonymize profile PII, soft-delete listings
 *      - Delete addresses, notification prefs, favourites
 *      - Queue hard-delete (30 days), audit log
 *   5. Return 200 — hard erasure happens in the two-stage GDPR cron:
 *      Stage 1 (SQL cron, 30 days later): deletes profile + related PII.
 *      Stage 2 (gdpr-cleanup-auth Edge Function): deletes auth.users row.
 *
 * Auth user NOT deleted here — immediate deletion would CASCADE-wipe the
 * anonymized user_profiles row and destroy the 30-day grace period. RLS
 * hides the soft-deleted profile from reads in the interim.
 *
 * Password re-auth is done client-side (OWASP ASVS §4.2.1).
 */
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { jsonResponse } from "../_shared/response.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";
import { getRedisCredentials } from "../_shared/redis.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const hmacKey = Deno.env.get("AUDIT_HMAC_KEY");
if (!hmacKey) {
  console.error("FATAL: AUDIT_HMAC_KEY not configured");
  Deno.exit(1);
}

const ACTIVE_STATUSES = ["created", "paid", "shipped", "delivered"];

const AuthHeaderSchema = z.string().startsWith("Bearer ").min(8);

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // ── Validate + extract JWT ─────────────────────────────────────────
  const authHeader = req.headers.get("authorization");
  const parsed = AuthHeaderSchema.safeParse(authHeader);
  if (!parsed.success) {
    return jsonResponse({ error: "Invalid authorization header" }, 401);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const token = parsed.data.replace("Bearer ", "");
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return jsonResponse({ error: "Invalid or expired token" }, 401);
  }

  const userId = user.id;
  const userEmail = user.email ?? "unknown";

  // ── Rate limit ─────────────────────────────────────────────────────
  try {
    const redisCreds = await getRedisCredentials(supabase);
    const { allowed } = await checkRateLimit(
      redisCreds,
      userId,
      "delete-account",
      { maxRequests: 3, windowSeconds: 3600 },
    );
    if (!allowed) {
      return jsonResponse({ error: "Too many requests" }, 429);
    }
  } catch (rateLimitErr) {
    // Rate limit failure is non-blocking — log and continue
    console.warn("Rate limit check failed:", rateLimitErr);
  }

  try {
    // ── Check for active transactions ────────────────────────────────
    const { data: activeTxns } = await supabase
      .from("transactions")
      .select("id")
      .or(`buyer_id.eq.${userId},seller_id.eq.${userId}`)
      .in("status", ACTIVE_STATUSES)
      .limit(1);

    if (activeTxns && activeTxns.length > 0) {
      return jsonResponse(
        {
          error: "Cannot delete account while transactions are in progress",
          code: "ACTIVE_TRANSACTIONS",
        },
        409,
      );
    }

    // ── Check for existing pending deletion ──────────────────────────
    const { data: existing } = await supabase
      .from("gdpr_deletion_queue")
      .select("id")
      .eq("user_id", userId)
      .eq("status", "pending")
      .maybeSingle();

    if (existing) {
      return jsonResponse(
        { error: "Account deletion already requested" },
        409,
      );
    }

    // ── Atomic soft-delete via RPC (all-or-nothing transaction) ──────
    const emailHash = await hmacHashEmail(userEmail);

    const { error: rpcError } = await supabase.rpc("soft_delete_account", {
      p_user_id: userId,
      p_email_hash: emailHash,
      p_ip: req.headers.get("x-forwarded-for") ?? "unknown",
      p_user_agent: req.headers.get("user-agent") ?? "unknown",
    });

    if (rpcError) {
      console.error("soft_delete_account RPC failed:", rpcError);
      return jsonResponse({ error: "Failed to delete account" }, 500);
    }

    // Auth user NOT deleted here — deferred to cron job to avoid
    // CASCADE conflicts. Soft-delete + RLS hides the profile.

    return jsonResponse({
      status: "deleted",
      message: "Account scheduled for permanent deletion in 30 days",
    });
  } catch (err) {
    console.error("Account deletion failed:", err);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

async function hmacHashEmail(email: string): Promise<string> {
  const encoder = new TextEncoder();
  const key = await crypto.subtle.importKey(
    "raw",
    encoder.encode(hmacKey),
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  const signature = await crypto.subtle.sign(
    "HMAC",
    key,
    encoder.encode(email.toLowerCase()),
  );
  return Array.from(new Uint8Array(signature))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
