/**
 * R-20 Stage 2: GDPR auth.users cleanup.
 *
 * Triggered by pg_cron. Iterates queue entries where PII has been erased
 * (status='completed') but auth.users still holds the credential record
 * (auth_deleted=false), and calls the Supabase admin API to remove them.
 *
 * Split from Stage 1 (gdpr_hard_delete_expired SQL cron) because:
 *   - auth.users deletion requires the admin API, not SQL
 *   - PII erasure must not depend on admin API availability (GDPR priority)
 *   - Failed auth deletions retry on the next cron run without re-running PII erasure
 *
 * verify_jwt = false — invoked by pg_cron, authenticated via service_role
 * header (verifyServiceRole exact-match, not JWT decoding).
 *
 * Reference: docs/COMPLIANCE.md, docs/epics/E02-user-auth-kyc.md
 */
import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { jsonResponse } from "../_shared/response.ts";
import { verifyServiceRole } from "../_shared/auth.ts";

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

// Cap per invocation — keeps runtime bounded and lets the next cron run
// pick up the backlog if a spike lands. 100 × 30 days is far above steady
// state; tune if deletion volume grows.
const BATCH_LIMIT = 100;

Deno.serve(async (req: Request) => {
  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);

  const { data: pending, error: fetchError } = await supabase
    .from("gdpr_deletion_queue")
    .select("id, user_id")
    .eq("status", "completed")
    .eq("auth_deleted", false)
    .order("completed_at", { ascending: true })
    .limit(BATCH_LIMIT);

  if (fetchError) {
    console.error("gdpr-cleanup-auth: fetch failed", fetchError);
    return jsonResponse({ error: "Fetch failed" }, 500);
  }

  let deleted = 0;
  let failed = 0;

  for (const entry of pending ?? []) {
    const { error: deleteError } = await supabase.auth.admin.deleteUser(
      entry.user_id,
    );

    // "User not found" is a success — the auth row is already gone (manual
    // cleanup, prior run partial success, etc). Mark as deleted so we stop
    // retrying.
    const isNotFound =
      deleteError?.message?.toLowerCase().includes("not found") ?? false;

    if (deleteError && !isNotFound) {
      failed += 1;
      await supabase
        .from("gdpr_deletion_queue")
        .update({ auth_error: deleteError.message })
        .eq("id", entry.id);

      await supabase.from("audit_logs").insert({
        user_id: entry.user_id,
        action: "auth_delete_failed",
        metadata: { queue_id: entry.id, error: deleteError.message },
      });
      continue;
    }

    const { error: updateError } = await supabase
      .from("gdpr_deletion_queue")
      .update({
        auth_deleted: true,
        auth_deleted_at: new Date().toISOString(),
        auth_error: null,
      })
      .eq("id", entry.id);

    if (updateError) {
      // auth.users row was deleted but we failed to record the flag — this
      // is not a silent failure: log it so the next run can detect the row
      // is missing via the "not found" path and converge.
      console.error(
        "gdpr-cleanup-auth: queue flag update failed",
        entry.id,
        updateError,
      );
      failed += 1;
      continue;
    }

    await supabase.from("audit_logs").insert({
      user_id: entry.user_id,
      action: "auth_delete_completed",
      metadata: { queue_id: entry.id, already_absent: isNotFound },
    });
    deleted += 1;
  }

  return jsonResponse({ deleted, failed, scanned: pending?.length ?? 0 });
});
