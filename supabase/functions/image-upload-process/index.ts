/**
 * Image Upload Process Edge Function (R-27 / E01)
 *
 * Pipeline: Supabase Storage (source of truth) → Cloudmersive virus scan
 *  → Cloudinary signed upload (strip EXIF + WebP/AVIF delivery) → return URL.
 *
 * Invocation contract (client responsibility):
 *  1. Client picks an image and uploads it to
 *     `listings-images/<user_id>/<uuid>.<ext>` in Supabase Storage
 *     (direct upload — RLS enforces folder ownership).
 *  2. Client calls this EF with `{ storage_path }` — the full object
 *     path inside the `listings-images` bucket.
 *  3. This EF verifies the authenticated user owns the path, scans the
 *     bytes, uploads to Cloudinary, and returns the delivery URL.
 *  4. Client stores the URL in `ListingCreationState.uploadedImageUrls`
 *     (see GH issue #TBD for pizmam sell-screen wiring).
 *
 * On virus scan failure, the Storage object is deleted to prevent
 * orphan infected files from sitting in the bucket.
 *
 * Auth: verify_jwt = true. The Supabase gateway validates the JWT and
 * we additionally compare the `sub` claim to the storage path's first
 * segment so users can't process each other's uploads.
 *
 * Reference: docs/epics/E01-listing-management.md §"Image Processing Pipeline"
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "@supabase/supabase-js";
import { z } from "zod";
import { jsonResponse } from "../_shared/response.ts";
import { getVaultSecret } from "../_shared/vault.ts";
import { describeThreat, scanImage } from "./cloudmersive.ts";
import { type CloudinaryCredentials, uploadImage } from "./cloudinary.ts";

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const BUCKET = "listings-images";
const MAX_BYTES = 15 * 1024 * 1024; // 15 MiB — matches bucket policy

// ---------------------------------------------------------------------------
// Zod input validation (§9)
// ---------------------------------------------------------------------------

const ProcessRequestSchema = z.object({
  // Must be a relative path inside BUCKET, no leading slash, no `..`
  // segments. Enforced by regex before further parsing.
  storage_path: z.string()
    .min(3)
    .max(512)
    .regex(
      /^[a-f0-9-]{36}\/[A-Za-z0-9._-]+\.[A-Za-z0-9]{2,5}$/,
      "storage_path must be <user_id>/<filename>.<ext>",
    ),
});

// ---------------------------------------------------------------------------
// Main handler
// ---------------------------------------------------------------------------

Deno.serve(async (req: Request): Promise<Response> => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const anonKey = Deno.env.get("SUPABASE_ANON_KEY");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !anonKey || !serviceRoleKey) {
    console.error("[image-upload-process] missing Supabase env vars");
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return jsonResponse({ error: "Missing Authorization header" }, 401);
  }

  // ── Parse + validate input ────────────────────────────────────────────
  let body: unknown;
  try {
    body = await req.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON body" }, 400);
  }
  const parsed = ProcessRequestSchema.safeParse(body);
  if (!parsed.success) {
    return jsonResponse({ error: parsed.error.flatten() }, 400);
  }
  const { storage_path } = parsed.data;

  // ── Auth: verify path ownership via JWT subject claim ─────────────────
  const userClient = createClient(supabaseUrl, anonKey, {
    global: { headers: { Authorization: authHeader } },
  });
  const { data: { user }, error: userError } = await userClient.auth.getUser();
  if (userError || !user) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const pathOwner = storage_path.split("/")[0];
  if (pathOwner !== user.id) {
    return jsonResponse({ error: "Path ownership mismatch" }, 403);
  }

  // ── Load secrets ──────────────────────────────────────────────────────
  const serviceClient = createClient(supabaseUrl, serviceRoleKey);
  let cloudmersiveKey: string;
  let cloudinary: CloudinaryCredentials;
  try {
    cloudmersiveKey = await getVaultSecret(
      serviceClient,
      "CLOUDMERSIVE_API_KEY",
    );
    cloudinary = {
      cloud_name: await getVaultSecret(serviceClient, "CLOUDINARY_CLOUD_NAME"),
      api_key: await getVaultSecret(serviceClient, "CLOUDINARY_API_KEY"),
      api_secret: await getVaultSecret(serviceClient, "CLOUDINARY_API_SECRET"),
    };
  } catch (err) {
    console.error(`[image-upload-process] vault read failed: ${err}`);
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  // ── Download bytes from Storage ───────────────────────────────────────
  const { data: blob, error: downloadError } = await serviceClient.storage
    .from(BUCKET)
    .download(storage_path);
  if (downloadError || !blob) {
    console.error(
      `[image-upload-process] storage download failed for ${storage_path}: ${downloadError?.message}`,
    );
    return jsonResponse({ error: "Storage object not found" }, 404);
  }
  if (blob.size > MAX_BYTES) {
    await serviceClient.storage.from(BUCKET).remove([storage_path]);
    return jsonResponse({ error: "File exceeds 15 MiB limit" }, 413);
  }
  const bytes = new Uint8Array(await blob.arrayBuffer());
  const filename = storage_path.split("/").pop() ?? "image";

  // ── Virus scan (fail-closed) ──────────────────────────────────────────
  let scanResult;
  try {
    scanResult = await scanImage(cloudmersiveKey, bytes, filename);
  } catch (err) {
    console.error(`[image-upload-process] scan failed: ${err}`);
    // Fail-closed: delete the object so a scan outage can't become a
    // back door for bypassing virus detection.
    await serviceClient.storage.from(BUCKET).remove([storage_path]);
    return jsonResponse({ error: "Virus scan unavailable" }, 503);
  }
  if (!scanResult.clean_result) {
    const threat = describeThreat(scanResult);
    console.warn(
      `[image-upload-process] threat blocked for ${user.id}: ${threat}`,
    );
    await serviceClient.storage.from(BUCKET).remove([storage_path]);
    return jsonResponse({ error: `Image blocked: ${threat}` }, 422);
  }

  // ── Upload to Cloudinary with metadata stripped ───────────────────────
  let cloudinaryResult;
  try {
    cloudinaryResult = await uploadImage(
      cloudinary,
      bytes,
      filename,
      `listings/${user.id}`,
    );
  } catch (err) {
    console.error(`[image-upload-process] cloudinary upload failed: ${err}`);
    return jsonResponse({ error: "Image upload failed" }, 502);
  }

  return jsonResponse({
    storage_path,
    delivery_url: cloudinaryResult.secure_url,
    public_id: cloudinaryResult.public_id,
    width: cloudinaryResult.width,
    height: cloudinaryResult.height,
    bytes: cloudinaryResult.bytes,
    format: cloudinaryResult.format,
  });
});
