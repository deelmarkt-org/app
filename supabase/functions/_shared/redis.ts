/** R-11: Shared Upstash Redis utility — credentials + core operations. */

// --- Credentials ---

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

// --- Cache TTLs ---

export const CACHE_TTL = {
  LISTING_DETAIL: 300,   // 5 min — invalidated by listing.updated/sold/deleted
  SEARCH_RESULTS: 120,   // 2 min — invalidated by listing.created/updated
  USER_PROFILE: 600,     // 10 min — invalidated by user.updated, review added
  IDEMPOTENCY: 86400,    // 24 hours
} as const;

// --- Core operations ---

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
  if (!response.ok) {
    throw new Error(`Redis SET failed (HTTP ${response.status}): ${await response.text()}`);
  }
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
  if (!response.ok) {
    throw new Error(`Redis GET failed (HTTP ${response.status}): ${await response.text()}`);
  }
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
  if (!response.ok) {
    throw new Error(`Redis DEL failed (HTTP ${response.status}): ${await response.text()}`);
  }
  const data = await response.json();
  return data.result ?? 0;
}
