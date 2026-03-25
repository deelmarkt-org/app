/**
 * B-25 + B-26: Create Shipping Label Edge Function
 *
 * Creates a shipping label via Ectaro Partner API (primary, cheaper rates)
 * with direct PostNL Shipment V4 as failover.
 *
 * POST /functions/v1/create-shipping-label
 * Auth: service_role (called from app via authenticated endpoint)
 *
 * Carriers: PostNL, DHL (selected per request)
 * QR data: generated from tracking code for label-free service point drop-off
 */
import { createClient } from "jsr:@supabase/supabase-js@2";
import { z } from "https://deno.land/x/zod@v3.22.4/mod.ts";
import { verifyServiceRole } from "../_shared/auth.ts";

// --- Types ---

interface LabelResult {
  trackingNumber: string;
  qrData: string;
  carrier: string;
  trackingUrl: string;
  labelPdf?: string;
}

// --- Zod Schemas ---

const AddressSchema = z.object({
  name: z.string().min(1),
  street: z.string().min(1),
  houseNumber: z.string().min(1),
  houseNumberAddition: z.string().optional(),
  postcode: z.string().regex(/^\d{4}[A-Z]{2}$/),
  city: z.string().min(1),
  countryCode: z.string().length(2).default("NL"),
});

const CreateLabelSchema = z.object({
  transactionId: z.string().uuid(),
  carrier: z.enum(["postnl", "dhl"]),
  sender: AddressSchema,
  recipient: AddressSchema,
  weightGrams: z.number().int().positive().max(30000),
  description: z.string().max(255).optional(),
});

type CreateLabelInput = z.infer<typeof CreateLabelSchema>;

// --- Helpers ---

function jsonResponse(body: Record<string, unknown>, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

function buildTrackingUrl(carrier: string, trackingNumber: string): string {
  if (carrier === "postnl") {
    return `https://postnl.nl/tracktrace/?B=${trackingNumber}&P=&D=&T=C`;
  }
  return `https://www.dhl.nl/nl/particulier/tracking.html?tracking-id=${trackingNumber}`;
}

// --- Ectaro API (primary — cheaper rates) ---

async function createViaEctaro(
  input: CreateLabelInput,
  apiKey: string,
): Promise<LabelResult> {
  const carrierMap: Record<string, string> = {
    postnl: "PostNL",
    dhl: "DHL",
  };

  const payload = {
    carrier: carrierMap[input.carrier],
    service: "standard",
    sender: {
      name: input.sender.name,
      street: input.sender.street,
      houseNumber: input.sender.houseNumber,
      houseNumberAddition: input.sender.houseNumberAddition ?? "",
      postalCode: input.sender.postcode,
      city: input.sender.city,
      countryCode: input.sender.countryCode,
    },
    receiver: {
      name: input.recipient.name,
      street: input.recipient.street,
      houseNumber: input.recipient.houseNumber,
      houseNumberAddition: input.recipient.houseNumberAddition ?? "",
      postalCode: input.recipient.postcode,
      city: input.recipient.city,
      countryCode: input.recipient.countryCode,
    },
    weight: input.weightGrams,
    description: input.description ?? "DeelMarkt order",
    reference: input.transactionId,
  };

  const resp = await fetch(
    "https://partnerapi.ectaro.com/api/v1/shipping/label",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify(payload),
    },
  );

  const data = await resp.json();

  // Ectaro returns 200 even on failure — check response body
  if (!resp.ok || data.error || !data.trackingCode) {
    throw new Error(
      `Ectaro label creation failed: ${data.error ?? data.message ?? resp.statusText}`,
    );
  }

  return {
    trackingNumber: data.trackingCode,
    qrData: data.qrData ?? data.trackingCode,
    carrier: input.carrier,
    trackingUrl: data.trackingUrl ??
      buildTrackingUrl(input.carrier, data.trackingCode),
    labelPdf: data.label ?? undefined,
  };
}

// --- PostNL Shipment V4 API (failover for PostNL labels) ---

async function createViaPostNL(
  input: CreateLabelInput,
  apiKey: string,
): Promise<LabelResult> {
  const payload = {
    Customer: {
      CustomerCode: "DEVC",
      CustomerNumber: "11223344",
    },
    Message: {
      MessageID: crypto.randomUUID(),
      MessageTimeStamp: new Date().toISOString(),
    },
    Shipments: [{
      Addresses: [
        {
          AddressType: "01",
          FirstName: input.recipient.name,
          Street: input.recipient.street,
          HouseNr: input.recipient.houseNumber,
          HouseNrExt: input.recipient.houseNumberAddition ?? "",
          Zipcode: input.recipient.postcode,
          City: input.recipient.city,
          Countrycode: input.recipient.countryCode,
        },
        {
          AddressType: "02",
          FirstName: input.sender.name,
          Street: input.sender.street,
          HouseNr: input.sender.houseNumber,
          HouseNrExt: input.sender.houseNumberAddition ?? "",
          Zipcode: input.sender.postcode,
          City: input.sender.city,
          Countrycode: input.sender.countryCode,
        },
      ],
      Dimension: { Weight: input.weightGrams },
      ProductCodeDelivery: "3085",
      Reference: input.transactionId,
    }],
  };

  const baseUrl = apiKey.startsWith("test_")
    ? "https://api-sandbox.postnl.nl"
    : "https://api.postnl.nl";

  const resp = await fetch(`${baseUrl}/v4/shipment`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      "apikey": apiKey,
    },
    body: JSON.stringify(payload),
  });

  if (!resp.ok) {
    const text = await resp.text();
    throw new Error(`PostNL Shipment V4 failed (${resp.status}): ${text}`);
  }

  const data = await resp.json();
  const shipment = data.ResponseShipments?.[0];
  const barcode = shipment?.Barcode;

  if (!barcode) {
    throw new Error("PostNL response missing barcode");
  }

  return {
    trackingNumber: barcode,
    qrData: barcode,
    carrier: "postnl",
    trackingUrl: buildTrackingUrl("postnl", barcode),
    labelPdf: shipment?.Labels?.[0]?.Content,
  };
}

// --- Main Handler ---

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  if (!verifyServiceRole(req)) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!supabaseUrl || !serviceRoleKey) {
    console.error(
      "[create-shipping-label] Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY",
    );
    return jsonResponse({ error: "Internal configuration error" }, 500);
  }
  const supabase = createClient(supabaseUrl, serviceRoleKey);

  try {
    const body = await req.json();
    const input = CreateLabelSchema.parse(body);

    // Verify transaction exists and is in valid state
    const { data: txn, error: txnError } = await supabase
      .from("transactions")
      .select("id, status")
      .eq("id", input.transactionId)
      .single();

    if (txnError || !txn) {
      return jsonResponse({ error: "Transaction not found" }, 404);
    }
    if (txn.status !== "paid") {
      return jsonResponse({
        error: `Cannot create label: status is '${txn.status}', expected 'paid'`,
      }, 422);
    }

    // Idempotency: check for existing label
    const { data: existing } = await supabase
      .from("shipping_labels")
      .select("tracking_number, qr_data, carrier")
      .eq("transaction_id", input.transactionId)
      .maybeSingle();

    if (existing) {
      return jsonResponse({
        trackingNumber: existing.tracking_number,
        qrData: existing.qr_data,
        carrier: existing.carrier,
        message: "Label already exists",
      });
    }

    // Primary: Ectaro (cheaper) → Failover: direct PostNL
    let result: LabelResult;
    let provider: string;

    try {
      const ectaroKey = Deno.env.get("ECTARO_API_KEY");
      if (!ectaroKey) throw new Error("ECTARO_API_KEY not configured");
      result = await createViaEctaro(input, ectaroKey);
      provider = "ectaro";
    } catch (ectaroError) {
      console.warn(
        `[create-shipping-label] Ectaro failed: ${(ectaroError as Error).message}`,
      );

      if (input.carrier === "postnl") {
        const postnlKey = Deno.env.get("POSTNL_API_KEY");
        if (!postnlKey) {
          throw new Error("POSTNL_API_KEY not configured for failover");
        }
        result = await createViaPostNL(input, postnlKey);
        provider = "postnl-direct";
      } else {
        // DHL direct failover not yet implemented
        throw new Error(
          `DHL direct failover unavailable. Ectaro: ${(ectaroError as Error).message}`,
        );
      }
    }

    // Store label
    const shipByDeadline = new Date();
    shipByDeadline.setDate(shipByDeadline.getDate() + 5);

    const { error: insertError } = await supabase
      .from("shipping_labels")
      .insert({
        transaction_id: input.transactionId,
        carrier: input.carrier,
        tracking_number: result.trackingNumber,
        qr_data: result.qrData,
        tracking_url: result.trackingUrl,
        label_pdf: result.labelPdf ?? null,
        ship_by_deadline: shipByDeadline.toISOString(),
        provider,
      });

    if (insertError) {
      if (insertError.code === "23505") {
        // Race condition — label created between check and insert
        const { data: raceLabel } = await supabase
          .from("shipping_labels")
          .select("tracking_number, qr_data, carrier")
          .eq("transaction_id", input.transactionId)
          .single();

        return jsonResponse({
          trackingNumber: raceLabel?.tracking_number,
          qrData: raceLabel?.qr_data,
          carrier: raceLabel?.carrier,
          message: "Label already exists (concurrent request)",
        });
      }
      throw new Error(`Failed to store label: ${insertError.message}`);
    }

    // Transition: paid → shipped
    await supabase
      .from("transactions")
      .update({ status: "shipped", shipped_at: new Date().toISOString() })
      .eq("id", input.transactionId)
      .eq("status", "paid");

    console.log(
      `[create-shipping-label] ${provider} | ${input.carrier} | ${result.trackingNumber} | txn:${input.transactionId}`,
    );

    return jsonResponse({
      trackingNumber: result.trackingNumber,
      qrData: result.qrData,
      carrier: result.carrier,
      trackingUrl: result.trackingUrl,
      shipByDeadline: shipByDeadline.toISOString(),
      provider,
    });
  } catch (error) {
    if (error instanceof z.ZodError) {
      return jsonResponse({
        error: `Validation: ${error.errors.map((e) => e.message).join(", ")}`,
      }, 400);
    }
    console.error(
      `[create-shipping-label] ${(error as Error).message}`,
    );
    return jsonResponse({ error: "Internal error" }, 500);
  }
});
