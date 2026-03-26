/**
 * B-28: Dutch Postcode Lookup Edge Function
 *
 * Resolves Dutch postcode + house number → street + city.
 *
 * Primary: postcode.tech (free, 10k requests/month)
 * Fallback: api-postcode.nl (free, 1k requests/day)
 *
 * GET /functions/v1/postcode-lookup?postcode=1234AB&houseNumber=10
 * Auth: anon key (JWT required via verify_jwt = true)
 */
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { jsonResponse as baseJsonResponse } from "../_shared/response.ts";

// Postcode responses get 24h cache — postcodes don't change often
function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return baseJsonResponse(body, status, { "Cache-Control": "public, max-age=86400" });
}

// --- Zod Schema ---

const QuerySchema = z.object({
  postcode: z.string().regex(/^\d{4}[A-Z]{2}$/, "Postcode must be 4 digits + 2 uppercase letters"),
  houseNumber: z.string().min(1, "House number is required"),
  addition: z.string().optional(),
});

// --- Postcode Providers ---

interface AddressResult {
  street: string;
  city: string;
  houseNumber: string;
  houseNumberAddition: string;
  postcode: string;
}

/**
 * Primary: postcode.tech — free tier 10,000 requests/month.
 * No API key required for basic usage.
 * GET https://postcode.tech/api/v1/postcode/full?postcode=1234AB&number=10
 */
async function lookupViaPostcodeTech(
  postcode: string,
  houseNumber: string,
  addition?: string,
): Promise<AddressResult | null> {
  const params = new URLSearchParams({ postcode, number: houseNumber });
  if (addition) params.set("addition", addition);
  const resp = await fetch(
    `https://postcode.tech/api/v1/postcode/full?${params}`,
  );

  if (!resp.ok) return null;

  const data = await resp.json();
  if (!data.street) return null;

  return {
    street: data.street,
    city: data.city,
    houseNumber,
    houseNumberAddition: data.letter ?? "",
    postcode,
  };
}

/**
 * Fallback: PostcodeAPI.nu — free tier 1,000 requests/day.
 * Requires API key stored in env (not a secret, free tier key).
 * GET https://json.api-postcode.nl?postcode=1234AB&number=10
 */
async function lookupViaApiPostcode(
  postcode: string,
  houseNumber: string,
  addition?: string,
): Promise<AddressResult | null> {
  const params = new URLSearchParams({ postcode, number: houseNumber });
  if (addition) params.set("addition", addition);
  const resp = await fetch(
    `https://json.api-postcode.nl?${params}`,
  );

  if (!resp.ok) return null;

  const data = await resp.json();
  if (!data.street) return null;

  return {
    street: data.street,
    city: data.city,
    houseNumber,
    houseNumberAddition: data.house_number_addition ?? "",
    postcode,
  };
}

// --- Main Handler ---

Deno.serve(async (req: Request) => {
  if (req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const url = new URL(req.url);
  const params = {
    postcode: (url.searchParams.get("postcode") ?? "").toUpperCase(),
    houseNumber: url.searchParams.get("houseNumber") ?? "",
    addition: url.searchParams.get("addition") ?? undefined,
  };

  try {
    const input = QuerySchema.parse(params);

    // Primary: postcode.tech → Fallback: api-postcode.nl
    let result: AddressResult | null = null;

    try {
      result = await lookupViaPostcodeTech(input.postcode, input.houseNumber, input.addition);
    } catch (err) {
      console.warn(`[postcode-lookup] postcode.tech failed: ${(err as Error).message}`);
    }

    if (!result) {
      try {
        result = await lookupViaApiPostcode(input.postcode, input.houseNumber, input.addition);
      } catch (err) {
        console.warn(`[postcode-lookup] api-postcode.nl failed: ${(err as Error).message}`);
      }
    }

    if (!result) {
      return jsonResponse({ error: "Address not found" }, 404);
    }

    return jsonResponse({
      street: result.street,
      city: result.city,
      houseNumber: result.houseNumber,
      houseNumberAddition: result.houseNumberAddition,
      postcode: result.postcode,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return jsonResponse({
        error: `Validation: ${error.errors.map((e) => e.message).join(", ")}`,
      }, 400);
    }
    console.error(`[postcode-lookup] ${(error as Error).message}`);
    return jsonResponse({ error: "Internal error" }, 500);
  }
});
