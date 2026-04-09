/**
 * R-07: Health check Edge Function
 * GET /functions/v1/health → 200 OK
 *
 * verify_jwt = false — called by Betterstack uptime monitor (anonymous).
 * No auth required — this endpoint is intentionally public so external
 * monitoring can probe without credentials.
 *
 * Checks:
 * - Edge Function runtime is alive
 * - Supabase DB connection (via service_role)
 * - Timestamp for uptime monitoring (Betterstack)
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { jsonResponse } from "../_shared/response.ts";

// Module-scope client — reused across requests (L2)
const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, serviceRoleKey);

Deno.serve(async (req: Request) => {
  if (req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const checks: Record<string, string> = {
    runtime: "ok",
    database: "unknown",
  };
  let status = 200;

  // DB connectivity probe — query existing table with zero rows returned
  try {
    const { error } = await supabase
      .from("transactions")
      .select("id")
      .limit(0);

    if (error) throw error;
    checks.database = "ok";
  } catch (_e) {
    checks.database = "error";
    status = 503;
  }

  return jsonResponse({
    status: status === 200 ? "healthy" : "degraded",
    checks,
    timestamp: new Date().toISOString(),
    version: "0.1.0",
  }, status);
});
