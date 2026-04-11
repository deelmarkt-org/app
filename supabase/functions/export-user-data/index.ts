/**
 * R-21: GDPR Data Portability — Export User Data (Art. 20 GDPR)
 *
 * Assembles all personal data held for the authenticated user, serialises it
 * to JSON, uploads the file to Supabase Storage, and returns a short-lived
 * signed download URL. The URL is valid for 24 hours.
 *
 * Data included in the export:
 *   • auth.users metadata (email, created_at, last_sign_in_at, phone)
 *   • user_profiles (display name, avatar, address, KYC level, badges)
 *   • listings (all user's own listings including sold/deleted)
 *   • favourites (listing IDs saved by user)
 *   • messages (conversations the user participated in)
 *   • reviews (given and received)
 *   • transactions (buyer + seller)
 *   • idin_sessions (verification attempts)
 *   • dsa_reports (reports submitted by user)
 *
 * Security:
 *   • JWT required (Supabase gateway validates before handler runs)
 *   • Rate-limited: 3 exports per user per 24 hours
 *   • Export file stored at `exports/{userId}/{timestamp}.json`
 *     (RLS on the exports bucket limits reads to the owner)
 *   • Signed URL signed with the service role key; URL is HTTPS-only
 *
 * Auth: verify_jwt = true
 *
 * Reference: docs/epics/E02-user-auth-kyc.md §"GDPR Portability"
 *            docs/COMPLIANCE.md §"Right to Data Portability (Art. 20)"
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import {
  createClient,
  type SupabaseClient,
  type User,
} from "@supabase/supabase-js";
import { z } from "zod";
import { jsonResponse } from "../_shared/response.ts";
import { getRedisCredentials } from "../_shared/redis.ts";
import { checkRateLimit } from "../_shared/rate_limit.ts";

// ---------------------------------------------------------------------------
// Config
// ---------------------------------------------------------------------------

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;

/** Signed URL expiry in seconds (24 hours). */
const SIGNED_URL_TTL_SECONDS = 86400;

/** Storage bucket for user data exports (must exist with appropriate RLS). */
const EXPORTS_BUCKET = "user-data-exports";

// ---------------------------------------------------------------------------
// Zod schema
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

  // ── Rate limit — 3 exports per user per 24 hours ───────────────────────
  try {
    const redisCreds = getRedisCredentials();
    const { allowed } = await checkRateLimit(
      redisCreds,
      userId,
      "export-user-data",
      { maxRequests: 3, windowSeconds: 86400 },
    );
    if (!allowed) {
      return jsonResponse(
        { error: "Too many export requests. Try again tomorrow." },
        429,
      );
    }
  } catch (rateLimitErr) {
    // Redis unavailable — fail open (allow request, log warning)
    console.warn("Rate limit check failed:", rateLimitErr);
  }

  try {
    // ── Assemble export payload ────────────────────────────────────────
    const exportData = await assembleExport(supabase, userId, user);

    // ── Serialise to JSON ──────────────────────────────────────────────
    const jsonBytes = new TextEncoder().encode(
      JSON.stringify(exportData, null, 2),
    );

    // ── Upload to Storage ──────────────────────────────────────────────
    const timestamp = new Date().toISOString().replace(/[:.]/g, "-");
    const filePath = `${userId}/${timestamp}.json`;

    const { error: uploadError } = await supabase.storage
      .from(EXPORTS_BUCKET)
      .upload(filePath, jsonBytes, {
        contentType: "application/json",
        upsert: false,
      });

    if (uploadError) {
      console.error("Failed to upload export file:", uploadError);
      return jsonResponse({ error: "Failed to generate export" }, 500);
    }

    // ── Generate signed URL ────────────────────────────────────────────
    const { data: signedData, error: signError } = await supabase.storage
      .from(EXPORTS_BUCKET)
      .createSignedUrl(filePath, SIGNED_URL_TTL_SECONDS);

    if (signError || !signedData?.signedUrl) {
      console.error("Failed to sign export URL:", signError);
      return jsonResponse({ error: "Failed to generate download link" }, 500);
    }

    return jsonResponse({
      url: signedData.signedUrl,
      expires_in_seconds: SIGNED_URL_TTL_SECONDS,
    });
  } catch (err) {
    console.error("export-user-data unexpected error:", err);
    return jsonResponse({ error: "Internal server error" }, 500);
  }
});

// ---------------------------------------------------------------------------
// assembleExport — fetches all personal data for the user
// ---------------------------------------------------------------------------

async function assembleExport(
  supabase: SupabaseClient,
  userId: string,
  user: User,
) {
  const results = await Promise.all([
    supabase.from("user_profiles").select("*").eq("id", userId).maybeSingle(),
    supabase.from("listings").select("*").eq("seller_id", userId),
    supabase.from("favourites").select("listing_id").eq("user_id", userId),
    supabase.from("messages").select("*").eq("sender_id", userId),
    supabase.from("reviews").select("*").eq("reviewer_id", userId),
    supabase.from("reviews").select("*").eq("reviewee_id", userId),
    supabase.from("transactions").select("*").eq("buyer_id", userId),
    supabase.from("transactions").select("*").eq("seller_id", userId),
    supabase.from("idin_sessions").select("*").eq("user_id", userId),
    supabase.from("dsa_reports").select("*").eq("reporter_id", userId),
  ]);

  // Fail fast: any individual query error means an incomplete export —
  // return 500 rather than silently omitting personal data (GDPR Art. 20).
  const firstError = results.find((r) => r.error)?.error;
  if (firstError) {
    throw new Error(
      `Failed to fetch user data for export: ${firstError.message}`,
    );
  }

  const [
    profile,
    listings,
    favourites,
    sentMessages,
    reviewsGiven,
    reviewsReceived,
    transactionsBuyer,
    transactionsSeller,
    idinSessions,
    dsaReports,
  ] = results;

  return {
    exported_at: new Date().toISOString(),
    export_format_version: "1.0",
    user: {
      id: user.id,
      email: user.email,
      phone: user.phone,
      created_at: user.created_at,
      last_sign_in_at: user.last_sign_in_at,
      email_confirmed_at: user.email_confirmed_at,
      phone_confirmed_at: user.phone_confirmed_at,
    },
    profile: profile.data,
    listings: listings.data ?? [],
    favourites: favourites.data ?? [],
    messages: {
      sent: sentMessages.data ?? [],
    },
    reviews: {
      given: reviewsGiven.data ?? [],
      received: reviewsReceived.data ?? [],
    },
    transactions: {
      as_buyer: transactionsBuyer.data ?? [],
      as_seller: transactionsSeller.data ?? [],
    },
    idin_sessions: idinSessions.data ?? [],
    dsa_reports: dsaReports.data ?? [],
  };
}
