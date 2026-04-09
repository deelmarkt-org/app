/**
 * Idempotency helpers using Upstash Redis NX pattern.
 *
 * Extracted from redis.ts per §2.1 (utility files max 100 lines).
 * Used by mollie-webhook and tracking-webhook for duplicate detection.
 *
 * Reference: CLAUDE.md §9 — "Webhook handlers MUST be idempotent (Upstash Redis NX pattern)"
 */

import {
  CACHE_TTL,
  type RedisCredentials,
  redisDel,
  redisSet,
} from "./redis.ts";

/**
 * Atomic idempotency check via SET NX.
 * Returns true if this is a NEW event (key was set).
 * Returns false if the event was already processed (key exists).
 *
 * Throws on Redis errors (HTTP 429/503) so callers return 500
 * and the carrier retries — never silently drops events.
 */
export async function checkIdempotency(
  creds: RedisCredentials,
  key: string,
  ttl = CACHE_TTL.IDEMPOTENCY,
): Promise<boolean> {
  return await redisSet(creds, key, "1", ttl, true);
}

/**
 * Rollback an idempotency key on failure so carrier retries succeed.
 * Best-effort — errors are logged but not thrown.
 */
export async function rollbackIdempotency(
  creds: RedisCredentials,
  key: string,
): Promise<void> {
  try {
    await redisDel(creds, key);
  } catch (error) {
    console.error(
      `[redis] Failed to rollback idempotency key '${key}':`,
      error,
    );
    // Best-effort — carrier/payment provider will retry
  }
}
