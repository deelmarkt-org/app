/**
 * Shared Upstash Redis utility for Edge Functions.
 *
 * R-11: Centralised Redis client — eliminates duplication across webhooks.
 * Uses Upstash REST API (no SDK dependency, works in Deno runtime).
 *
 * Reference: docs/epics/E07-infrastructure.md §External Services
 */

// ---------------------------------------------------------------------------
// Credentials
// ---------------------------------------------------------------------------

export interface RedisCredentials {
  url: string;
  token: string;
}

/**
 * Read Upstash Redis credentials from environment.
 * Throws if not configured — Redis is mandatory for idempotency (§9).
 */
export function getRedisCredentials(): RedisCredentials {
  const url = Deno.env.get("UPSTASH_REDIS_REST_URL");
  const token = Deno.env.get("UPSTASH_REDIS_REST_TOKEN");

  if (!url || !token) {
    throw new Error("Upstash Redis not configured — UPSTASH_REDIS_REST_URL and UPSTASH_REDIS_REST_TOKEN are required");
  }

  return { url, token };
}

// ---------------------------------------------------------------------------
// Cache tier TTLs (E07 §External Services)
// ---------------------------------------------------------------------------

/** Cache TTLs in seconds, per E07 epic specification. */
export const CACHE_TTL = {
  /** Listing detail — 5 min. Invalidated by listing.updated/sold/deleted. */
  LISTING_DETAIL: 300,
  /** Search results — 2 min. Invalidated by listing.created/updated. */
  SEARCH_RESULTS: 120,
  /** User profile — 10 min. Invalidated by user.updated, review added. */
  USER_PROFILE: 600,
  /** Idempotency keys — 24 hours. */
  IDEMPOTENCY: 86400,
} as const;

// ---------------------------------------------------------------------------
// Core operations
// ---------------------------------------------------------------------------

/**
 * SET a key with optional TTL. Returns true if the key was set.
 *
 * @param creds  - Redis credentials
 * @param key    - Cache key
 * @param value  - Value to store
 * @param ttl    - TTL in seconds (omit for no expiry)
 * @param nx     - Only set if key does not exist (for idempotency)
 */
export async function redisSet(
  creds: RedisCredentials,
  key: string,
  value: string,
  ttl?: number,
  nx?: boolean,
): Promise<boolean> {
  const parts = [creds.url, "set", encodeURIComponent(key), encodeURIComponent(value)];
  if (ttl) parts.push("EX", String(ttl));
  if (nx) parts.push("NX");

  const response = await fetch(parts.join("/"), {
    headers: { Authorization: `Bearer ${creds.token}` },
  });
  const data = await response.json();
  return data.result === "OK";
}

/**
 * GET a key. Returns the value or null if not found.
 */
export async function redisGet(
  creds: RedisCredentials,
  key: string,
): Promise<string | null> {
  const response = await fetch(
    `${creds.url}/get/${encodeURIComponent(key)}`,
    { headers: { Authorization: `Bearer ${creds.token}` } },
  );
  const data = await response.json();
  return data.result ?? null;
}

/**
 * DEL a key. Returns the number of keys deleted.
 */
export async function redisDel(
  creds: RedisCredentials,
  key: string,
): Promise<number> {
  const response = await fetch(
    `${creds.url}/del/${encodeURIComponent(key)}`,
    { headers: { Authorization: `Bearer ${creds.token}` } },
  );
  const data = await response.json();
  return data.result ?? 0;
}

// ---------------------------------------------------------------------------
// Idempotency helpers
// ---------------------------------------------------------------------------

/**
 * Atomic idempotency check via SET NX.
 * Returns true if this is a NEW event (key was set).
 * Returns false if the event was already processed (key exists).
 */
export async function checkIdempotency(
  creds: RedisCredentials,
  key: string,
  ttl = CACHE_TTL.IDEMPOTENCY,
): Promise<boolean> {
  return redisSet(creds, key, "1", ttl, true);
}

/**
 * Rollback an idempotency key on failure so retries succeed.
 * Best-effort — errors are silently caught.
 */
export async function rollbackIdempotency(
  creds: RedisCredentials,
  key: string,
): Promise<void> {
  try {
    await redisDel(creds, key);
  } catch {
    // Best-effort — carrier/payment provider will retry
  }
}
