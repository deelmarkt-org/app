/**
 * B-25 + B-26: Create Shipping Label Edge Function
 *
 * Creates a shipping label via Ectaro Partner API (primary, cheaper rates)
 * with direct PostNL Shipment v2 as failover.
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
import { getVaultSecret } from "../_shared/vault.ts";
import { jsonResponse } from "../_shared/response.ts";

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
  postcode: z.string().transform((v) => v.toUpperCase()).pipe(z.string().regex(/^\d{4}[A-Z]{2}$/)),
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

// --- PostNL Shipment v2 API (failover for PostNL labels) ---
// Verified via sandbox testing 2026-03-29:
//   Barcode:  GET  /shipment/v1_1/barcode
//   Confirm:  POST /shipment/v2/confirm
//   Label:    POST /shipment/v2_2/label
//   Status:   GET  /shipment/v2/status/barcode/:barcode

/** PostNL base URL — sandbox or production based on POSTNL_ENV. */
function getPostNLBaseUrl(): string {
  const postnlEnv = Deno.env.get("POSTNL_ENV");
  if (!postnlEnv) {
    console.warn("[create-shipping-label] POSTNL_ENV not set — defaulting to sandbox. Set POSTNL_ENV=production for live API.");
  }
  const isSandbox = postnlEnv !== "production";
  return isSandbox
    ? "https://api-sandbox.postnl.nl"
    : "https://api.postnl.nl";
}

async function createViaPostNL(
  input: CreateLabelInput,
  apiKey: string,
): Promise<LabelResult> {
  // PostNL account details from env — never hardcoded (§9)
  const customerCode = Deno.env.get("POSTNL_CUSTOMER_CODE");
  const customerNumber = Deno.env.get("POSTNL_CUSTOMER_NUMBER");
  const collectionLocation = Deno.env.get("POSTNL_COLLECTION_LOCATION");
  if (!customerCode || !customerNumber || !collectionLocation) {
    throw new Error("Missing PostNL account config: POSTNL_CUSTOMER_CODE, POSTNL_CUSTOMER_NUMBER, POSTNL_COLLECTION_LOCATION");
  }

  const baseUrl = getPostNLBaseUrl();
  const headers = {
    "Content-Type": "application/json",
    "Accept": "application/json",
    "apikey": apiKey,
  };

  // Step 1: Generate barcode via GET /shipment/v1_1/barcode
  const barcodeUrl = `${baseUrl}/shipment/v1_1/barcode?CustomerCode=${customerCode}&CustomerNumber=${customerNumber}&Type=3S&Serie=000000000-999999999`;
  const barcodeResp = await fetch(barcodeUrl, { headers: { apikey: apiKey, Accept: "application/json" } });

  if (!barcodeResp.ok) {
    const text = await barcodeResp.text();
    throw new Error(`PostNL Barcode v1_1 failed (${barcodeResp.status}): ${text}`);
  }

  const barcodeData = await barcodeResp.json();
  const barcode = barcodeData.Barcode;
  if (!barcode) {
    throw new Error("PostNL barcode response missing Barcode field");
  }

  // PostNL timestamp format: DD-MM-YYYY HH:MM:SS
  const now = new Date();
  const pad = (n: number) => n.toString().padStart(2, "0");
  const messageTimestamp = `${pad(now.getDate())}-${pad(now.getMonth() + 1)}-${now.getFullYear()} ${pad(now.getHours())}:${pad(now.getMinutes())}:${pad(now.getSeconds())}`;

  const shipmentPayload = {
    Customer: {
      CustomerCode: customerCode,
      CustomerNumber: customerNumber,
      CollectionLocation: collectionLocation,
      Address: {
        AddressType: "02",
        CompanyName: input.sender.name,
        Street: input.sender.street,
        HouseNr: input.sender.houseNumber,
        HouseNrExt: input.sender.houseNumberAddition ?? "",
        Zipcode: input.sender.postcode,
        City: input.sender.city,
        Countrycode: input.sender.countryCode,
      },
    },
    Message: {
      MessageID: crypto.randomUUID(),
      MessageTimeStamp: messageTimestamp,
      Printertype: "GraphicFile|PDF",
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
      ],
      Barcode: barcode,
      Contacts: [{
        ContactType: "01",
        Email: "",
      }],
      Dimension: { Weight: input.weightGrams.toString() },
      ProductCodeDelivery: "3085",
      Reference: input.transactionId,
    }],
  };

  // Step 2: Confirm shipment via POST /shipment/v2/confirm
  const confirmResp = await fetch(`${baseUrl}/shipment/v2/confirm`, {
    method: "POST",
    headers,
    body: JSON.stringify(shipmentPayload),
  });

  if (!confirmResp.ok) {
    const text = await confirmResp.text();
    throw new Error(`PostNL Shipment v2/confirm failed (${confirmResp.status}): ${text}`);
  }

  const confirmData = await confirmResp.json();
  const errors = confirmData.ResponseShipments?.[0]?.Errors;
  if (errors && errors.length > 0) {
    throw new Error(`PostNL shipment errors: ${errors.map((e: { ErrorMsg: string }) => e.ErrorMsg).join(", ")}`);
  }

  // Step 3: Generate label via POST /shipment/v2_2/label
  const labelResp = await fetch(`${baseUrl}/shipment/v2_2/label`, {
    method: "POST",
    headers,
    body: JSON.stringify(shipmentPayload),
  });

  let labelPdf: string | undefined;
  if (labelResp.ok) {
    const labelData = await labelResp.json();
    labelPdf = labelData.ResponseShipments?.[0]?.Labels?.[0]?.Content;
  } else {
    console.warn(`[create-shipping-label] PostNL label generation failed (${labelResp.status}) — shipment confirmed but no PDF`);
  }

  return {
    trackingNumber: barcode,
    qrData: barcode,
    carrier: "postnl",
    trackingUrl: buildTrackingUrl("postnl", barcode),
    labelPdf,
  };
}

// --- B-27: PostNL Track & Trace ---
// PostNL webhooks are configured server-side by PostNL support (Chi-Ho, 2026-03-26).
// They push tracking events to our tracking-webhook Edge Function.
// No per-shipment registration needed — all barcodes for our customer number
// are automatically tracked once the webhook is configured.
//
// Fallback: poll /shipment/v2/status/barcode/:barcode for status updates.

async function pollPostNLStatus(
  barcode: string,
  postnlKey: string,
): Promise<{ status: string; timestamp: string } | null> {
  const baseUrl = getPostNLBaseUrl();
  const resp = await fetch(
    `${baseUrl}/shipment/v2/status/barcode/${encodeURIComponent(barcode)}`,
    { headers: { apikey: postnlKey, Accept: "application/json" } },
  );

  if (!resp.ok) return null;

  const data = await resp.json();
  const current = data.CurrentStatus;
  if (!current?.StatusCode) return null;

  return {
    status: current.StatusCode,
    timestamp: current.TimeStamp ?? new Date().toISOString(),
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
      .select("barcode, qr_data, carrier")
      .eq("transaction_id", input.transactionId)
      .maybeSingle();

    if (existing) {
      return jsonResponse({
        trackingNumber: existing.barcode,
        qrData: existing.qr_data,
        carrier: existing.carrier,
        message: "Label already exists",
      });
    }

    // Primary: Ectaro (cheaper) → Failover: direct PostNL
    let result: LabelResult;
    let provider: string;

    try {
      const ectaroKey = await getVaultSecret(supabase, "ECTARO_API_KEY");
      result = await createViaEctaro(input, ectaroKey);
      provider = "ectaro";
    } catch (ectaroError) {
      console.warn(
        `[create-shipping-label] Ectaro failed: ${(ectaroError as Error).message}`,
      );

      if (input.carrier === "postnl") {
        const postnlKey = await getVaultSecret(supabase, "POSTNL_API_KEY");
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
    // UTC is acceptable — PostNL API expects UTC timestamps. Dutch timezone offset
    // (CET/CEST +1/+2h) does not affect the 5-day shipping window significantly.
    const shipByDeadline = new Date(Date.now() + 5 * 24 * 60 * 60 * 1000);

    const { error: insertError } = await supabase
      .from("shipping_labels")
      .insert({
        transaction_id: input.transactionId,
        carrier: input.carrier,
        barcode: result.trackingNumber,
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
          .select("barcode, qr_data, carrier")
          .eq("transaction_id", input.transactionId)
          .single();

        return jsonResponse({
          trackingNumber: raceLabel?.barcode,
          qrData: raceLabel?.qr_data,
          carrier: raceLabel?.carrier,
          message: "Label already exists (concurrent request)",
        });
      }
      throw new Error(`Failed to store label: ${insertError.message}`);
    }

    // Transition: paid → shipped (shipped_at set by DB trigger)
    await supabase
      .from("transactions")
      .update({ status: "shipped" })
      .eq("id", input.transactionId)
      .eq("status", "paid");

    // B-27: PostNL tracking is handled via webhook (configured server-side by PostNL).
    // No per-shipment registration needed. Fallback polling available via pollPostNLStatus().

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
