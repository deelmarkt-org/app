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
      /^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}\/[A-Za-z0-9._-]+\.[A-Za-z0-9]{2,5}$/,
      "storage_path must be <uuid>/<filename>.<ext>",
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

  it("rejects 36 consecutive dashes (strict 8-4-4-4-12 layout)", () => {
    // The old loose regex `[a-f0-9-]{36}` would have accepted this.
    // The strict UUIDv4 layout requires the four dashes at fixed
    // offsets, so a pathological all-dashes string is now rejected
    // at the edge instead of relying on the downstream ownership
    // check. (Defence-in-depth per the Gemini review on PR #105.)
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${"-".repeat(36)}/photo.jpg`,
    });
    assert(!result.success);
  });

  it("rejects a 36-char hex blob with no dashes", () => {
    // Another case the old regex admitted — strict layout requires
    // dashes at positions 8/13/18/23.
    const result = ProcessRequestSchema.safeParse({
      storage_path: `${"a".repeat(36)}/photo.jpg`,
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
