/**
 * R-11: Redis Health Check Edge Function
 * GET /functions/v1/redis-health → 200 OK
 *
 * Verifies Upstash Redis connectivity via a SET → GET → DEL cycle.
 * Protected by service_role auth (internal use only).
 *
 * Reference: docs/epics/E07-infrastructure.md §External Services
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { verifyServiceRole } from "../_shared/auth.ts";
import {
  getRedisCredentials,
  redisSet,
  redisGet,
  redisDel,
} from "../_shared/redis.ts";

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // Internal-only — require service_role JWT
  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const checks: Record<string, string> = {
    credentials: "unknown",
    set: "unknown",
    get: "unknown",
    delete: "unknown",
  };

  try {
    // 1. Verify credentials are configured
    const creds = getRedisCredentials();
    checks.credentials = "ok";

    // 2. SET → GET → DEL cycle with a probe key
    const probeKey = `health:probe:${Date.now()}`;
    const probeValue = "deelmarkt-redis-health";

    const setOk = await redisSet(creds, probeKey, probeValue, 60);
    checks.set = setOk ? "ok" : "error";

    const getResult = await redisGet(creds, probeKey);
    checks.get = getResult === probeValue ? "ok" : "error";

    await redisDel(creds, probeKey);
    checks.delete = "ok";
  } catch (error) {
    const failedCheck = Object.entries(checks).find(([_, v]) => v === "unknown");
    if (failedCheck) {
      checks[failedCheck[0]] = "error";
    }
    console.error(`[redis-health] ${(error as Error).message}`);
  }

  const allOk = Object.values(checks).every((v) => v === "ok");

  return jsonResponse(
    {
      status: allOk ? "healthy" : "degraded",
      checks,
      timestamp: new Date().toISOString(),
    },
    allOk ? 200 : 503,
  );
});

function jsonResponse(body: Record<string, unknown>, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}
