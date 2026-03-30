/**
 * Tier-1 Audit M-01: Per-user rate limiting via Upstash Redis.
 *
 * Sliding window counter pattern. Each user gets a key like
 * `ratelimit:{endpoint}:{userId}` with a counter and TTL.
 *
 * Usage:
 * ```ts
 * const { allowed, remaining, resetSeconds } = await checkRateLimit(
 *   creds, user.id, "create-payment", { maxRequests: 10, windowSeconds: 3600 }
 * );
 * if (!allowed) return jsonError("Too many requests", 429);
 * ```
 */

import { type RedisCredentials } from "./redis.ts";

export interface RateLimitConfig {
  /** Maximum requests allowed in the window. */
  maxRequests: number;
  /** Window size in seconds. */
  windowSeconds: number;
}

export interface RateLimitResult {
  /** Whether the request is allowed. */
  allowed: boolean;
  /** Remaining requests in this window. */
  remaining: number;
  /** Seconds until the window resets. */
  resetSeconds: number;
}

/**
 * Check rate limit for a user on a specific endpoint.
 *
 * Uses Redis INCR + EXPIRE for atomic counter increment.
 * If the key doesn't exist, INCR creates it with value 1.
 * EXPIRE sets the TTL only on the first request in a window.
 */
export async function checkRateLimit(
  creds: RedisCredentials,
  userId: string,
  endpoint: string,
  config: RateLimitConfig,
): Promise<RateLimitResult> {
  const key = `ratelimit:${endpoint}:${userId}`;

  // INCR — atomic increment, creates key with value 1 if it doesn't exist
  const incrResponse = await fetch(
    `${creds.url}/incr/${encodeURIComponent(key)}`,
    { headers: { Authorization: `Bearer ${creds.token}` } },
  );

  if (!incrResponse.ok) {
    // Redis unavailable — fail open (allow the request, log warning)
    console.warn(`[rate-limit] Redis INCR failed (HTTP ${incrResponse.status}), failing open`);
    return { allowed: true, remaining: config.maxRequests, resetSeconds: 0 };
  }

  const incrData = await incrResponse.json();
  const currentCount: number = incrData.result;

  // Set TTL on the first request in the window (count === 1)
  if (currentCount === 1) {
    await fetch(
      `${creds.url}/expire/${encodeURIComponent(key)}/${config.windowSeconds}`,
      { headers: { Authorization: `Bearer ${creds.token}` } },
    ).catch((err) => {
      console.warn(`[rate-limit] Redis EXPIRE failed: ${err}`);
    });
  }

  // Get TTL for reset time
  let resetSeconds = config.windowSeconds;
  try {
    const ttlResponse = await fetch(
      `${creds.url}/ttl/${encodeURIComponent(key)}`,
      { headers: { Authorization: `Bearer ${creds.token}` } },
    );
    if (ttlResponse.ok) {
      const ttlData = await ttlResponse.json();
      if (ttlData.result > 0) {
        resetSeconds = ttlData.result;
      }
    }
  } catch {
    // Non-critical — use default window
  }

  const remaining = Math.max(0, config.maxRequests - currentCount);

  return {
    allowed: currentCount <= config.maxRequests,
    remaining,
    resetSeconds,
  };
}
