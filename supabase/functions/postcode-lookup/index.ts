/**
 * B-28: Dutch Postcode Lookup Edge Function
 *
 * Resolves Dutch postcode + house number → street + city
 * via PostNL Adrescheck Nederland v4 API.
 *
 * GET /functions/v1/postcode-lookup?postcode=1234AB&houseNumber=10
 * Auth: anon key (public, user-facing for address auto-fill)
 */
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";

// --- Zod Schema ---

const QuerySchema = z.object({
  postcode: z.string().regex(/^\d{4}[A-Z]{2}$/, "Postcode must be 4 digits + 2 uppercase letters"),
  houseNumber: z.string().min(1, "House number is required"),
  addition: z.string().optional(),
});

// --- Helpers ---

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "public, max-age=86400", // 24h — postcodes don't change often
    },
  });
}

// --- Main Handler ---

Deno.serve(async (req: Request) => {
  if (req.method !== "GET") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const url = new URL(req.url);
  const params = {
    postcode: url.searchParams.get("postcode") ?? "",
    houseNumber: url.searchParams.get("houseNumber") ?? "",
    addition: url.searchParams.get("addition") ?? undefined,
  };

  try {
    const input = QuerySchema.parse(params);

    const postnlKey = Deno.env.get("POSTNL_API_KEY");
    if (!postnlKey) {
      console.error("[postcode-lookup] Missing POSTNL_API_KEY");
      return jsonResponse({ error: "Internal configuration error" }, 500);
    }

    const baseUrl = postnlKey.startsWith("test_")
      ? "https://api-sandbox.postnl.nl"
      : "https://api.postnl.nl";

    const queryParams = new URLSearchParams({
      postalCode: input.postcode,
      houseNumber: input.houseNumber,
    });
    if (input.addition) {
      queryParams.set("houseNumberAddition", input.addition);
    }

    const resp = await fetch(
      `${baseUrl}/v4/address/netherlands?${queryParams}`,
      {
        headers: { "apikey": postnlKey },
      },
    );

    if (!resp.ok) {
      if (resp.status === 404) {
        return jsonResponse({ error: "Address not found" }, 404);
      }
      const text = await resp.text();
      console.error(`[postcode-lookup] PostNL API error (${resp.status}): ${text}`);
      return jsonResponse({ error: "Address lookup failed" }, 502);
    }

    const data = await resp.json();
    const addresses = data.Addresses ?? data.addresses ?? [];

    if (addresses.length === 0) {
      return jsonResponse({ error: "Address not found" }, 404);
    }

    // Return first match (most specific)
    const addr = addresses[0];
    return jsonResponse({
      street: addr.Street ?? addr.street ?? "",
      city: addr.City ?? addr.city ?? "",
      houseNumber: addr.HouseNumber ?? addr.houseNumber ?? input.houseNumber,
      houseNumberAddition: addr.HouseNumberAddition ?? addr.houseNumberAddition ?? "",
      postcode: input.postcode,
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
