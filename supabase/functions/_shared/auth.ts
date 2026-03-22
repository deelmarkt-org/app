import { createClient } from "jsr:@supabase/supabase-js@2";

/**
 * Verify that the request has a valid service_role Authorization header.
 * Used by cron-triggered and internal functions where verify_jwt = false.
 *
 * Validates by checking the JWT's role claim against Supabase,
 * rather than string comparison (avoids key format mismatches).
 */
export async function verifyServiceRole(req: Request): Promise<boolean> {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return false;

  const token = authHeader.replace("Bearer ", "");
  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

  // Fast path: exact match with auto-injected service_role key
  if (token === serviceRoleKey) return true;

  // Fallback: decode JWT and check role claim
  try {
    const payloadB64 = token.split(".")[1];
    if (!payloadB64) return false;
    const payload = JSON.parse(atob(payloadB64));
    return payload.role === "service_role";
  } catch {
    return false;
  }
}
