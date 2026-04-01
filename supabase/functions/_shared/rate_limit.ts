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
 * Uses a Lua script via EVAL for atomic INCR + EXPIRE + TTL in a single
 * round-trip. This prevents the race condition where EXPIRE could fail
 * after INCR, leaving a key without TTL that persists forever.
 */
export async function checkRateLimit(
  creds: RedisCredentials,
  userId: string,
  endpoint: string,
  config: RateLimitConfig,
): Promise<RateLimitResult> {
  const key = `ratelimit:${endpoint}:${userId}`;

  // Lua script: atomically INCR, set EXPIRE on first request, return [count, ttl]
  const luaScript = [
    "local count = redis.call('INCR', KEYS[1])",
    "if count == 1 then redis.call('EXPIRE', KEYS[1], ARGV[1]) end",
    "local ttl = redis.call('TTL', KEYS[1])",
    "return {count, ttl}",
  ].join("\n");

  // Upstash REST API: POST body is [script, numkeys, ...keys, ...args]
  const evalResponse = await fetch(`${creds.url}/eval`, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${creds.token}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify([luaScript, 1, key, config.windowSeconds]),
  });

  if (!evalResponse.ok) {
    // Redis unavailable — fail open (allow the request, log warning)
    console.warn(`[rate-limit] Redis EVAL failed (HTTP ${evalResponse.status}), failing open`);
    return { allowed: true, remaining: config.maxRequests, resetSeconds: 0 };
  }

  const evalData = await evalResponse.json();
  const [currentCount, ttl] = evalData.result as [number, number];

  const resetSeconds = ttl > 0 ? ttl : config.windowSeconds;
  const remaining = Math.max(0, config.maxRequests - currentCount);

  return {
    allowed: currentCount <= config.maxRequests,
    remaining,
    resetSeconds,
  };
}
