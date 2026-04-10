/**
 * Unit tests for R-27 image-upload-process.
 *
 * These cover the Zod validation contract — the HTTP handler is exercised
 * at the integration level via the Supabase smoke test in
 * MANUAL-TASKS-BELENGAZ.md §R-27. We don't mock Cloudmersive or Cloudinary
 * here: those are external services and mocking their HTTP layer adds more
 * risk of drift than value.
 *
 * Importing index.ts directly would trigger Deno.serve at module load,
 * so the Zod schema is redeclared inline — same pattern as
 * scam-detection/index_test.ts.
 */

import { assert } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// Inline copy of the schema from index.ts — keep in sync by hand.
const ProcessRequestSchema = z.object({
  storage_path: z.string()
    .min(3)
    .max(512)
    .regex(
      /^[a-f0-9-]{36}\/[A-Za-z0-9._-]+\.[A-Za-z0-9]{2,5}$/,
      "storage_path must be <user_id>/<filename>.<ext>",
    ),
});

const validUserId = "550e8400-e29b-41d4-a716-446655440000";

describe("ProcessRequestSchema", () => {
  it("accepts a well-formed <user_id>/<filename>.<ext> path", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${validUserId}/my-photo.jpg`,
    });
    assert(result.success);
  });

  it("accepts lowercase uuid + png extension", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${validUserId}/abc123.png`,
    });
    assert(result.success);
  });

  it("rejects leading slash", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: `/${validUserId}/photo.jpg`,
    });
    assert(!result.success);
  });

  it("rejects path traversal with ..", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${validUserId}/../other-user/photo.jpg`,
    });
    assert(!result.success);
  });

  it("rejects missing extension", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${validUserId}/noext`,
    });
    assert(!result.success);
  });

  it("rejects an extension longer than 5 characters", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${validUserId}/photo.longext`,
    });
    assert(!result.success);
  });

  it("rejects a non-uuid user segment", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: "NOT-A-UUID/photo.jpg",
    });
    assert(!result.success);
  });

  it("rejects an extra path segment", () => {
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${validUserId}/subdir/photo.jpg`,
    });
    assert(!result.success);
  });

  it("rejects an empty object", () => {
    const result = ProcessRequestSchema.safeParse({});
    assert(!result.success);
  });
});
