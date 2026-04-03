/**
 * R-20: Account deletion Edge Function (GDPR right-to-erasure).
 *
 * Flow:
 *   1. Verify JWT
 *   2. Check for active transactions (block if any)
 *   3. Check for existing pending deletion (409 on duplicate)
 *   4. Soft-delete: anonymize user_profiles PII, mark deleted_at
 *   5. Soft-delete: hide user's listings (set deleted_at)
 *   6. Delete addresses, notification_preferences, favourites
 *   7. Queue hard-delete in gdpr_deletion_queue (30 days)
 *   8. Log to audit_logs (HMAC-SHA256 hashed email)
 *   9. Return 200 — auth user deletion deferred to cron job
 *
 * Auth user is NOT deleted here to avoid CASCADE conflicts with
 * user_profiles and listings FK references to auth.users.
 * The cron job handles auth.admin.deleteUser() after 30 days.
 *
 * Password re-auth is done client-side (OWASP ASVS §4.2.1).
 * No password is sent to this function.
 */
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { jsonResponse } from "../_shared/response.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// HMAC key for email hashing — loaded from env (set via Supabase Vault)
const hmacKey = Deno.env.get("AUDIT_HMAC_KEY") ?? serviceRoleKey;

// Active transaction statuses that block account deletion
const ACTIVE_STATUSES = ["created", "paid", "shipped", "delivered"];

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // ── Extract user from JWT ──────────────────────────────────────────
  const authHeader = req.headers.get("authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing authorization header" }, 401);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const token = authHeader.replace("Bearer ", "");
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return jsonResponse({ error: "Invalid or expired token" }, 401);
  }

  const userId = user.id;
  const userEmail = user.email ?? "unknown";

  try {
    // ── Check for active transactions ──────────────────────────────────
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

    // ── Check for existing pending deletion ────────────────────────────
    // Partial unique index also prevents duplicates at DB level (TOCTOU safe)
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

    // ── Soft-delete user profile ───────────────────────────────────────
    const now = new Date().toISOString();

    const { error: profileError } = await supabase
      .from("user_profiles")
      .update({
        display_name: "Verwijderd account",
        avatar_url: null,
        location: null,
        deleted_at: now,
        updated_at: now,
      })
      .eq("id", userId);

    if (profileError) {
      console.error("Failed to soft-delete profile:", profileError);
      return jsonResponse({ error: "Failed to delete account" }, 500);
    }

    // ── Soft-delete user's listings ────────────────────────────────────
    await supabase
      .from("listings")
      .update({ deleted_at: now })
      .eq("seller_id", userId)
      .is("deleted_at", null);

    // ── Delete user data ───────────────────────────────────────────────
    await supabase.from("user_addresses").delete().eq("user_id", userId);
    await supabase
      .from("notification_preferences")
      .delete()
      .eq("user_id", userId);
    await supabase.from("favourites").delete().eq("user_id", userId);

    // ── Queue hard-delete (30 days) ────────────────────────────────────
    const { error: queueError } = await supabase
      .from("gdpr_deletion_queue")
      .insert({ user_id: userId, status: "pending" });

    if (queueError) {
      console.error("Failed to queue deletion:", queueError);
    }

    // ── Audit log (HMAC-SHA256 hashed email — no raw PII) ──────────────
    await supabase.from("audit_logs").insert({
      user_id: userId,
      action: "account_deletion_requested",
      metadata: {
        email_hash: await hmacHashEmail(userEmail),
        ip: req.headers.get("x-forwarded-for") ?? "unknown",
        user_agent: req.headers.get("user-agent") ?? "unknown",
      },
    });

    // Auth user NOT deleted here — deferred to cron job to avoid
    // CASCADE conflicts (user_profiles, listings FK to auth.users).
    // Soft-delete + anonymized profile prevents meaningful access.

    return jsonResponse({
      status: "deleted",
      message: "Account scheduled for permanent deletion in 30 days",
    });
  } catch (err) {
    console.error("Account deletion failed:", err);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

/**
 * HMAC-SHA256 hash of email for audit log.
 * Uses a server-side key to prevent rainbow table reversal.
 */
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
