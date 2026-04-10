/**
 * Cloudinary signed upload client (R-27).
 *
 * Uploads bytes to Cloudinary with `strip_metadata=true` (EXIF/GPS removal,
 * GDPR requirement per E01 epic) and `fetch_format=auto` (WebP/AVIF where
 * supported by the client). Variants (200/800/1600) are served via
 * on-the-fly delivery URL transforms at render time, so we persist only
 * the canonical delivery URL.
 *
 * Signature algorithm: SHA1 of the sorted param list + API secret.
 * Docs: https://cloudinary.com/documentation/upload_images#generating_authentication_signatures
 */

/** Cloudinary credentials — read from Supabase Vault by the caller. */
export interface CloudinaryCredentials {
  cloud_name: string;
  api_key: string;
  api_secret: string;
}

export interface CloudinaryUploadResult {
  public_id: string;
  version: number;
  format: string;
  width: number;
  height: number;
  bytes: number;
  secure_url: string;
  resource_type: string;
}

/**
 * Generates the Cloudinary SHA1 signature over [params] alphabetically
 * joined as `k1=v1&k2=v2...` + [apiSecret].
 *
 * Excludes `file`, `cloud_name`, `resource_type`, and `api_key` per
 * Cloudinary docs.
 */
async function signParams(
  params: Record<string, string>,
  apiSecret: string,
): Promise<string> {
  const toSign = Object.keys(params)
    .sort()
    .map((k) => `${k}=${params[k]}`)
    .join("&");

  const data = new TextEncoder().encode(toSign + apiSecret);
  const hashBuffer = await crypto.subtle.digest("SHA-1", data);
  return Array.from(new Uint8Array(hashBuffer))
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

/**
 * Uploads [bytes] to Cloudinary into [folder] with metadata stripped.
 *
 * Returns the delivery URL (`secure_url`) that is safe to store in
 * `listings.image_urls[]`. The EF's caller decides whether to use
 * delivery transforms (e.g. `w_800`) at render time.
 *
 * Throws on upload failure so the caller can fail the upload request.
 */
export async function uploadImage(
  credentials: CloudinaryCredentials,
  bytes: Uint8Array,
  filename: string,
  folder: string,
): Promise<CloudinaryUploadResult> {
  const timestamp = Math.floor(Date.now() / 1000).toString();

  // Params that get signed. Keep this list aligned with the params
  // actually sent in the form body below — any mismatch fails the sig.
  const signedParams: Record<string, string> = {
    folder,
    strip_metadata: "true",
    timestamp,
    use_filename: "false",
    unique_filename: "true",
  };

  const signature = await signParams(signedParams, credentials.api_secret);

  const formData = new FormData();
  formData.append(
    "file",
    new Blob([bytes as BlobPart], { type: "application/octet-stream" }),
    filename,
  );
  for (const [k, v] of Object.entries(signedParams)) {
    formData.append(k, v);
  }
  formData.append("api_key", credentials.api_key);
  formData.append("signature", signature);

  const response = await fetch(
    `https://api.cloudinary.com/v1_1/${credentials.cloud_name}/image/upload`,
    { method: "POST", body: formData },
  );

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Cloudinary upload failed (${response.status}): ${text.slice(0, 200)}`,
    );
  }

  return response.json() as Promise<CloudinaryUploadResult>;
}
