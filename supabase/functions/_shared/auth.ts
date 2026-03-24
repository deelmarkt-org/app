/**
 * Verify that the request has a valid service_role Authorization header.
 * Used by cron-triggered and internal functions where verify_jwt = false.
 *
 * Exact string match with auto-injected SUPABASE_SERVICE_ROLE_KEY.
 * No JWT decoding — prevents forged unsigned token attacks.
 */
export function verifyServiceRole(req: Request): boolean {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return false;
  const token = authHeader.replace("Bearer ", "");
  return token === Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
}
