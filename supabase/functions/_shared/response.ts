/**
 * Shared HTTP response helper for Edge Functions.
 * Avoids duplicating jsonResponse() across functions (§3.3 DRY).
 */

export function jsonResponse(
  body: Record<string, unknown>,
  status = 200,
  headers?: Record<string, string>,
): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      ...headers,
    },
  });
}
