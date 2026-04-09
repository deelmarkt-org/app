/**
 * Tests for the scam detection HTTP handler (R-35 / E06).
 *
 * Tests Zod validation and auth checks via the handler contract.
 * The scan engine logic is tested separately in scan_engine_test.ts
 * and scan_scoring_test.ts.
 */

import {
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// ---------------------------------------------------------------------------
// Inline copy of Zod schema from index.ts
// (avoids importing index.ts which triggers Deno.serve at module scope)
// ---------------------------------------------------------------------------

const ScanRequestSchema = z.object({
  message_id: z.string().uuid("message_id must be a valid UUID"),
  conversation_id: z.string().uuid("conversation_id must be a valid UUID"),
  text: z.string().max(10000, "text exceeds max length"),
});

// ---------------------------------------------------------------------------
// Inline copy of verifyServiceRole from _shared/auth.ts
// ---------------------------------------------------------------------------

function verifyServiceRole(req: Request, serviceRoleKey: string): boolean {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader?.startsWith("Bearer ")) return false;
  const token = authHeader.replace("Bearer ", "");
  return token === serviceRoleKey;
}

// ===========================================================================
// Zod validation tests
// ===========================================================================

describe("ScanRequestSchema — Zod validation", () => {
  it("accepts valid UUIDs and text", () => {
    const result = ScanRequestSchema.safeParse({
      message_id: "550e8400-e29b-41d4-a716-446655440000",
      conversation_id: "660e8400-e29b-41d4-a716-446655440000",
      text: "Hello",
    });
    assert(result.success);
  });

  it("rejects missing message_id", () => {
    const result = ScanRequestSchema.safeParse({
      conversation_id: "660e8400-e29b-41d4-a716-446655440000",
      text: "Hello",
    });
    assert(!result.success);
  });

  it("rejects non-UUID message_id", () => {
    const result = ScanRequestSchema.safeParse({
      message_id: "not-a-uuid",
      conversation_id: "660e8400-e29b-41d4-a716-446655440000",
      text: "Hello",
    });
    assert(!result.success);
  });

  it("rejects non-UUID conversation_id", () => {
    const result = ScanRequestSchema.safeParse({
      message_id: "550e8400-e29b-41d4-a716-446655440000",
      conversation_id: "bad",
      text: "Hello",
    });
    assert(!result.success);
  });

  it("rejects text exceeding 10000 chars", () => {
    const result = ScanRequestSchema.safeParse({
      message_id: "550e8400-e29b-41d4-a716-446655440000",
      conversation_id: "660e8400-e29b-41d4-a716-446655440000",
      text: "a".repeat(10001),
    });
    assert(!result.success);
  });

  it("accepts empty text (message could be empty after trim)", () => {
    const result = ScanRequestSchema.safeParse({
      message_id: "550e8400-e29b-41d4-a716-446655440000",
      conversation_id: "660e8400-e29b-41d4-a716-446655440000",
      text: "",
    });
    assert(result.success);
  });

  it("rejects null input", () => {
    const result = ScanRequestSchema.safeParse(null);
    assert(!result.success);
  });

  it("rejects non-object input", () => {
    const result = ScanRequestSchema.safeParse("not an object");
    assert(!result.success);
  });
});

// ===========================================================================
// Auth verification tests
// ===========================================================================

describe("verifyServiceRole — auth check", () => {
  const SERVICE_KEY = "test-service-role-key-123"; // pragma: allowlist secret

  it("accepts valid service_role bearer token", () => {
    const req = new Request("http://localhost", {
      headers: { Authorization: `Bearer ${SERVICE_KEY}` },
    });
    assert(verifyServiceRole(req, SERVICE_KEY));
  });

  it("rejects missing Authorization header", () => {
    const req = new Request("http://localhost");
    assert(!verifyServiceRole(req, SERVICE_KEY));
  });

  it("rejects wrong token", () => {
    const req = new Request("http://localhost", {
      headers: { Authorization: "Bearer wrong-token" },
    });
    assert(!verifyServiceRole(req, SERVICE_KEY));
  });

  it("rejects non-Bearer auth scheme", () => {
    const req = new Request("http://localhost", {
      headers: { Authorization: `Basic ${SERVICE_KEY}` },
    });
    assert(!verifyServiceRole(req, SERVICE_KEY));
  });

  it("rejects empty Bearer token", () => {
    const req = new Request("http://localhost", {
      headers: { Authorization: "Bearer " },
    });
    assert(!verifyServiceRole(req, SERVICE_KEY));
  });
});
