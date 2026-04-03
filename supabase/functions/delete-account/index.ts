/**
 * R-20: Account deletion Edge Function (GDPR right-to-erasure).
 *
 * Flow:
 *   1. Verify JWT (user must be authenticated — re-auth done client-side)
 *   2. Check for existing pending deletion request (prevent duplicates)
 *   3. Soft-delete: anonymize user_profiles PII, mark deleted_at
 *   4. Soft-delete: hide user's listings (set deleted_at)
 *   5. Queue hard-delete in gdpr_deletion_queue (30 days)
 *   6. Log to audit_logs
 *   7. Delete Supabase Auth user (disables login immediately)
 *
 * The client calls this with NO body — only the JWT from signInWithPassword.
 * Password is never sent to this function (OWASP ASVS §4.2.1).
 *
 * Reference: docs/COMPLIANCE.md, docs/epics/E02-user-auth-kyc.md
 */
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { jsonResponse } from "../_shared/response.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

Deno.serve(async (req: Request) => {
  // ── Method check ───────────────────────────────────────────────────
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // ── Extract user from JWT ──────────────────────────────────────────
  const authHeader = req.headers.get("authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing authorization header" }, 401);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  // Verify JWT and extract user_id
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
    // ── Check for existing pending deletion ────────────────────────────
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

    // ── Delete user addresses ──────────────────────────────────────────
    await supabase
      .from("user_addresses")
      .delete()
      .eq("user_id", userId);

    // ── Delete notification preferences ────────────────────────────────
    await supabase
      .from("notification_preferences")
      .delete()
      .eq("user_id", userId);

    // ── Delete favourites ──────────────────────────────────────────────
    await supabase
      .from("favourites")
      .delete()
      .eq("user_id", userId);

    // ── Queue hard-delete (30 days) ────────────────────────────────────
    const { error: queueError } = await supabase
      .from("gdpr_deletion_queue")
      .insert({
        user_id: userId,
        status: "pending",
      });

    if (queueError) {
      console.error("Failed to queue deletion:", queueError);
      // Non-fatal — soft-delete already happened
    }

    // ── Audit log ──────────────────────────────────────────────────────
    await supabase.from("audit_logs").insert({
      user_id: userId,
      action: "account_deletion_requested",
      metadata: {
        email_hash: await hashEmail(userEmail),
        ip: req.headers.get("x-forwarded-for") ?? "unknown",
        user_agent: req.headers.get("user-agent") ?? "unknown",
      },
    });

    // ── Delete auth user (disables login immediately) ──────────────────
    const { error: deleteAuthError } =
      await supabase.auth.admin.deleteUser(userId);

    if (deleteAuthError) {
      console.error("Failed to delete auth user:", deleteAuthError);
      // Profile is already soft-deleted — cron will clean up auth later
    }

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
 * Hash email for audit log — preserves audit trail without storing PII.
 * Uses SHA-256 to allow pattern matching in investigations.
 */
async function hashEmail(email: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(email.toLowerCase());
  const hash = await crypto.subtle.digest("SHA-256", data);
  return Array.from(new Uint8Array(hash))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
