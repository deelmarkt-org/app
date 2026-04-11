/**
 * R-18: iDIN identity verification initiation (E02 KYC).
 *
 * Initiates the iDIN bank-based identity verification flow for KYC level1 → level2.
 * Required when a user tries to list or transact at >= €500 (level2 gate).
 *
 * Flow:
 *   1. Verify JWT + rate limit (3/hour per user)
 *   2. Read current kyc_level — reject if already level2+
 *   3. Cancel any stale pending session for this user
 *   4. Generate cryptographically random session token
 *   5. Create idin_session record (audit trail)
 *   6a. [MOCK MODE]  Immediately upgrade to level2 + return mock redirect URL
 *   6b. [PRODUCTION] Call iDIN provider API to get real bank-selection redirect URL
 *   7. Return { redirect_url, session_token }
 *
 * Auth: verify_jwt = true (Supabase gateway validates before handler runs).
 *
 * IDIN_MOCK_MODE env var:
 *   true  — skips iDIN provider call; upgrades kyc_level to level2 immediately.
 *           Safe for dev/staging. Never set in production.
 *   false — production path (iDIN provider integration required).
 *
 * Reference: docs/epics/E02-user-auth-kyc.md §"KYC Level 2 — iDIN"
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "zod";
import { jsonResponse } from "../_shared/response.ts";
import { getRedisCredentials } from "../_shared/redis.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/** In mock mode, KYC level is upgraded immediately without a real bank redirect. */
const idinMockMode = Deno.env.get("IDIN_MOCK_MODE") === "true";

/**
 * Mock redirect URL returned in IDIN_MOCK_MODE.
 * Must be on an allowed host per InitiateIdinVerificationUseCase._allowedHosts.
 * Clients that open this URL will see the DeelMarkt domain — no real iDIN page.
 */
const MOCK_REDIRECT_URL = "https://auth.deelmarkt.nl/idin/mock-complete";

// ---------------------------------------------------------------------------
// Zod schemas
// ---------------------------------------------------------------------------

const AuthHeaderSchema = z.string().startsWith("Bearer ").min(8);

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  // ── Validate + extract JWT ─────────────────────────────────────────────
  const authHeader = req.headers.get("authorization");
  const parsedHeader = AuthHeaderSchema.safeParse(authHeader);
  if (!parsedHeader.success) {
    return jsonResponse({ error: "Invalid authorization header" }, 401);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey);
  const token = parsedHeader.data.replace("Bearer ", "");
  const {
    data: { user },
    error: authError,
  } = await supabase.auth.getUser(token);

  if (authError || !user) {
    return jsonResponse({ error: "Invalid or expired token" }, 401);
  }

  const userId = user.id;

  // ── Rate limit — 3 initiations per user per hour ───────────────────────
  try {
    const redisCreds = getRedisCredentials();
    const { allowed } = await checkRateLimit(
      redisCreds,
      userId,
      "initiate-idin",
      { maxRequests: 3, windowSeconds: 3600 },
    );
    if (!allowed) {
      return jsonResponse(
        { error: "Too many iDIN requests. Try again in an hour." },
        429,
      );
    }
  } catch (rateLimitErr) {
    // Redis unavailable — fail open (allow request, log warning)
    console.warn("Rate limit check failed:", rateLimitErr);
  }

  try {
    // ── Check current KYC level ──────────────────────────────────────────
    const { data: profile, error: profileError } = await supabase
      .from("user_profiles")
      .select("kyc_level")
      .eq("id", userId)
      .maybeSingle();

    if (profileError) {
      console.error("Failed to fetch user profile:", profileError);
      return jsonResponse({ error: "Failed to read KYC level" }, 500);
    }

    if (!profile) {
      return jsonResponse({ error: "User profile not found" }, 404);
    }

    const kycLevel: string = profile.kyc_level ?? "level0";
    if (
      kycLevel === "level2" || kycLevel === "level3" || kycLevel === "level4"
    ) {
      return jsonResponse(
        {
          error: "User is already at KYC level 2 or higher",
          kyc_level: kycLevel,
        },
        409,
      );
    }

    // ── Generate session token ───────────────────────────────────────────
    const sessionToken = generateSessionToken();

    // ── Create idin_session record (audit trail) ─────────────────────────
    const { error: sessionError } = await supabase.rpc("create_idin_session", {
      p_user_id: userId,
      p_session_token: sessionToken,
    });

    if (sessionError) {
      if (sessionError.message.includes("pending iDIN session")) {
        return jsonResponse(
          {
            error:
              "A verification is already in progress. Check your bank app.",
          },
          409,
        );
      }
      console.error("Failed to create iDIN session:", sessionError);
      return jsonResponse({ error: "Failed to initiate verification" }, 500);
    }

    // ── Initiate iDIN (mock or production) ──────────────────────────────
    if (idinMockMode) {
      return await handleMockMode(supabase, userId, sessionToken);
    }

    return handleProductionMode(sessionToken);
  } catch (err) {
    console.error("initiate-idin unexpected error:", err);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

// ---------------------------------------------------------------------------
// Mock mode — immediately upgrades KYC level and returns a mock URL.
// Never deployed to production (guarded by IDIN_MOCK_MODE env var).
// ---------------------------------------------------------------------------

async function handleMockMode(
  // deno-lint-ignore no-explicit-any
  supabase: any,
  userId: string,
  sessionToken: string,
): Promise<Response> {
  // Complete the session immediately (no real bank redirect needed in dev)
  const { error: completeError } = await supabase.rpc("complete_idin_session", {
    p_session_token: sessionToken,
  });

  if (completeError) {
    console.error("Mock: failed to complete iDIN session:", completeError);
    return jsonResponse({ error: "Mock completion failed" }, 500);
  }

  console.info(
    `[MOCK] iDIN verification completed for user ${userId} — kyc_level → level2`,
  );

  return jsonResponse({
    redirect_url: MOCK_REDIRECT_URL,
    session_token: sessionToken,
    mock: true,
  });
}

// ---------------------------------------------------------------------------
// Production stub — to be wired to the chosen iDIN provider (Signicat et al.)
// ---------------------------------------------------------------------------

function handleProductionMode(_sessionToken: string): Response {
  // TODO (R-18 production): Integrate with iDIN provider.
  //
  // Typical flow:
  //   1. POST to provider API with session_token as state parameter
  //   2. Provider returns a bank-selection redirect URL
  //   3. Return that URL to the client
  //   4. Client opens URL in WebView / external browser
  //   5. After completion, provider POSTs to complete-idin-callback EF
  //   6. Callback EF calls complete_idin_session(session_token)
  //
  // Example provider call (Signicat):
  //   const providerUrl = Deno.env.get("IDIN_PROVIDER_URL")!;
  //   const apiKey = Deno.env.get("IDIN_API_KEY")!;
  //   const response = await fetch(`${providerUrl}/sessions`, {
  //     method: "POST",
  //     headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
  //     body: JSON.stringify({ state: sessionToken, callback_url: Deno.env.get("IDIN_CALLBACK_URL")! }),
  //   });
  //   const { redirect_url } = await response.json();
  //   return jsonResponse({ redirect_url, session_token: sessionToken });

  console.error(
    "Production iDIN provider not configured. Set IDIN_MOCK_MODE=true for dev/staging.",
  );
  return jsonResponse(
    { error: "iDIN provider not configured" },
    503,
  );
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Generates a 32-byte cryptographically random session token (hex-encoded). */
function generateSessionToken(): string {
  const bytes = new Uint8Array(32);
  crypto.getRandomValues(bytes);
  return Array.from(bytes)
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}
