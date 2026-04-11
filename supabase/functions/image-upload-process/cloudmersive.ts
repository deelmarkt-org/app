/**
 * Cloudmersive virus scan client (R-27).
 *
 * Uses the /virus/scan/file/advanced endpoint for image-level threat
 * detection. Advanced scan catches embedded scripts, polyglot files,
 * and JPG/PNG carriers for malware — matters because we serve these
 * images to other users.
 *
 * Docs: https://api.cloudmersive.com/docs/virus.asp
 *
 * The secret `CLOUDMERSIVE_API_KEY` is provisioned via Supabase Vault
 * by migration 20260410120000_r27_image_pipeline_vault.sql and seeded
 * manually per MANUAL-TASKS-BELENGAZ.md §R-27.
 */

const CLOUDMERSIVE_SCAN_URL =
  "https://api.cloudmersive.com/virus/scan/file/advanced";

export interface VirusScanResult {
  clean_result: boolean;
  found_viruses: Array<{ file_name: string; virus_name: string }> | null;
  contains_executable: boolean;
  contains_invalid_file: boolean;
  contains_script: boolean;
  contains_password_protected_file: boolean;
  contains_restricted_file_format: boolean;
  contains_macros: boolean;
  contains_xml_external_entities: boolean;
  contains_html: boolean;
  verified_file_format: string | null;
}

/**
 * Scans [bytes] against Cloudmersive. Throws on HTTP errors — the caller
 * must treat any thrown error as scan failure and reject the upload
 * (fail-closed for a security boundary).
 */
export async function scanImage(
  apiKey: string,
  bytes: Uint8Array,
  filename: string,
): Promise<VirusScanResult> {
  const formData = new FormData();
  formData.append(
    "inputFile",
    new Blob([bytes as BlobPart], { type: "application/octet-stream" }),
    filename,
  );

  const response = await fetch(CLOUDMERSIVE_SCAN_URL, {
    method: "POST",
    headers: {
      Apikey: apiKey,
      // Restrict to image formats — Cloudmersive blocks unknown formats
      // when this header is set, giving us an extra layer of validation.
      "restrictFileTypes": ".jpg,.jpeg,.png,.webp,.heic",
      "allowExecutables": "false",
      "allowInvalidFiles": "false",
      "allowScripts": "false",
      "allowPasswordProtectedFiles": "false", // pragma: allowlist secret
      "allowMacros": "false",
      "allowXmlExternalEntities": "false",
      "allowInsecureDeserialization": "false",
      "allowHtml": "false",
    },
    body: formData,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(
      `Cloudmersive scan failed (${response.status}): ${text.slice(0, 200)}`,
    );
  }

  return response.json() as Promise<VirusScanResult>;
}

/**
 * Extracts a human-readable failure reason from a scan result when
 * [clean_result] is false. Returned value is for logs and client errors.
 */
export function describeThreat(result: VirusScanResult): string {
  if (result.found_viruses && result.found_viruses.length > 0) {
    return `virus: ${result.found_viruses[0].virus_name}`;
  }
  if (result.contains_executable) return "executable payload";
  if (result.contains_script) return "embedded script";
  if (result.contains_macros) return "embedded macro";
  if (result.contains_xml_external_entities) return "XXE payload";
  if (result.contains_html) return "embedded HTML";
  if (result.contains_password_protected_file) return "password-protected";
  if (result.contains_restricted_file_format) return "restricted format";
  if (result.contains_invalid_file) return "invalid file";
  return "unknown threat";
}
