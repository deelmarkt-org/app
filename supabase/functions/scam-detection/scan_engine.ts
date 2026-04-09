/**
 * Scam Detection Scan Engine (R-35 / E06)
 *
 * Pure scoring logic — no HTTP, no Deno.serve, no Supabase.
 * Importable by both index.ts (handler) and tests without side-effects.
 *
 * Reason strings MUST match `ScamReason.fromDb()` in
 * `lib/core/domain/entities/scam_reason.dart` — the frontend enum is
 * the single source of truth for reason type naming (CLAUDE.md §3.3).
 *
 * Detection categories:
 *   1. External links (URLs, shortened links)
 *   2. Phone numbers / WhatsApp / Telegram references
 *   3. Off-platform payment requests (Tikkie, bank transfer, crypto)
 *   4. NLP keyword patterns (common Dutch + English scam phrases)
 *   5. Prohibited items keywords
 *
 * Scoring: each matched rule adds a weight. Total score maps to confidence:
 *   - 0        → "none"  (clean)
 *   - 1–39     → "low"   (suspicious, visible to moderators)
 *   - 40+      → "high"  (likely scam, warning shown to recipient)
 */

// ---------------------------------------------------------------------------
// Types
// ---------------------------------------------------------------------------

export interface ScanResult {
  confidence: "none" | "low" | "high";
  reasons: string[];
  score: number;
}

interface RuleMatch {
  reason: string;
  weight: number;
}

// ---------------------------------------------------------------------------
// Reason constants — MUST match ScamReason.fromDb() in scam_reason.dart
// ---------------------------------------------------------------------------

const REASON = {
  EXTERNAL_PAYMENT_LINK: "external_payment_link",
  OFF_SITE_CONTACT: "off_site_contact",
  PHONE_NUMBER_REQUEST: "phone_number_request",
  SUSPICIOUS_PRICING: "suspicious_pricing",
  URGENCY_PRESSURE: "urgency_pressure",
  CREDENTIAL_HARVESTING: "credential_harvesting",
  ADVANCE_PAYMENT_REQUEST: "advance_payment_request",
  FAKE_ESCROW: "fake_escrow",
  SHIPPING_SCAM: "shipping_scam",
  PROHIBITED_ITEM: "prohibited_item",
} as const;

// ---------------------------------------------------------------------------
// Detection rules
// ---------------------------------------------------------------------------

/** URL patterns — catches http(s), www, and common shortened domains. */
const URL_PATTERN =
  /https?:\/\/[^\s]+|www\.[^\s]+|bit\.ly\/[^\s]+|tinyurl\.com\/[^\s]+|t\.co\/[^\s]+|goo\.gl\/[^\s]+|is\.gd\/[^\s]+|rb\.gy\/[^\s]+/gi;

/** Phone number patterns — Dutch (+31 / 06) and international formats. */
const PHONE_PATTERN =
  /(?:\+31|0031|06)\s*[-.]?\s*\d[\d\s\-./]{6,12}\d|\+\d{1,3}\s*[-.]?\s*\d[\d\s\-./]{6,12}\d/g;

/** Email pattern — offering off-platform contact. */
const EMAIL_PATTERN = /[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}/g;

/** Off-platform messaging references. */
const OFFPLATFORM_MESSAGING_PATTERN =
  /\b(whatsapp|telegram|signal|viber|facebook\s*messenger|fb\s*messenger|sms|bel\s+me|app\s+me|stuur.*(?:bericht|sms))\b/gi;

/** Off-platform payment methods. */
const OFFPLATFORM_PAYMENT_PATTERN =
  /\b(tikkie|bank\s*overschrijving|bank\s*transfer|iban|over\s*maken|wire\s*transfer|western\s*union|moneygram|crypto|bitcoin|btc|eth|usdt|paypal(?:\.me)?|venmo|zelle|cash\s*app)\b/gi;

/**
 * NLP keyword patterns — common scam phrases in Dutch and English.
 * Each entry: [pattern, reason label (matching REASON constants), weight].
 */
const KEYWORD_RULES: Array<[RegExp, string, number]> = [
  // Urgency / pressure tactics
  [/\b(urgent|dringend|snel|haast|nu\s+betalen|pay\s+now|immediately|meteen)\b/gi, REASON.URGENCY_PRESSURE, 15],
  [/\b(laatste\s+kans|last\s+chance|beperkt\s+aanbod|limited\s+offer|only\s+today)\b/gi, REASON.URGENCY_PRESSURE, 20],

  // Too-good-to-be-true → maps to suspicious_pricing
  [/\b(gratis|free|gewonnen|you\s+won|congratulations|gefeliciteerd|prijs\s+gewonnen)\b/gi, REASON.SUSPICIOUS_PRICING, 20],
  [/\b(50%\s*(?:off|korting)|70%\s*(?:off|korting)|90%\s*(?:off|korting))\b/gi, REASON.SUSPICIOUS_PRICING, 15],

  // Advance payment / deposit requests
  [/\b(aanbetaling|deposit|vooruit\s*betalen|pay\s+(?:in\s+)?advance|prepay|upfront\s+payment)\b/gi, REASON.ADVANCE_PAYMENT_REQUEST, 25],
  [/\b(stuur\s+(?:geld|money)|send\s+(?:geld|money))\b/gi, REASON.ADVANCE_PAYMENT_REQUEST, 30],

  // Identity / credential harvesting
  [/\b(wachtwoord|password|inloggegevens|login\s*details|creditcard|credit\s*card|pin\s*code|bsn|burgerservicenummer|sofi\s*nummer)\b/gi, REASON.CREDENTIAL_HARVESTING, 35],
  [/\b(id\s*bewijs|passport|rijbewijs|identity\s*card|kopie\s+id|scan.*(?:id|passport))\b/gi, REASON.CREDENTIAL_HARVESTING, 25],

  // Shipping scams
  [/\b(verzendkosten\s+(?:betalen|vooruit)|shipping\s+(?:fee|cost)\s+(?:first|upfront))\b/gi, REASON.SHIPPING_SCAM, 20],
  [/\b(tracking\s+(?:code|nummer).*betaal|pay.*tracking)\b/gi, REASON.SHIPPING_SCAM, 25],

  // Fake escrow / external escrow
  [/\b(escrow\s*(?:service|platform|website)|externe\s+escrow|external\s+escrow)\b/gi, REASON.FAKE_ESCROW, 30],
];

/** Prohibited items keywords (Dutch marketplace context). */
const PROHIBITED_ITEMS_PATTERN =
  /\b(wapen|weapon|drugs|verdovende\s+middelen|namaak|counterfeit|fake\s+brand|replica|gestolen|stolen|illegaal|illegal)\b/gi;

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/** Add a match only if this reason hasn't been recorded yet. */
function addUnique(matches: RuleMatch[], reason: string, weight: number): void {
  if (!matches.some((m) => m.reason === reason)) {
    matches.push({ reason, weight });
  }
}

// ---------------------------------------------------------------------------
// Scoring engine
// ---------------------------------------------------------------------------

export function scanMessage(text: string): ScanResult {
  const matches: RuleMatch[] = [];
  const normalised = text.toLowerCase();

  // 1. External links
  const urlMatches = text.match(URL_PATTERN);
  if (urlMatches) {
    const externalUrls = urlMatches.filter(
      (u) => !u.toLowerCase().includes("deelmarkt.nl"),
    );
    if (externalUrls.length > 0) {
      addUnique(
        matches,
        REASON.EXTERNAL_PAYMENT_LINK,
        externalUrls.length >= 2 ? 25 : 15,
      );
    }
  }

  // 2. Phone numbers
  const phoneMatches = text.match(PHONE_PATTERN);
  if (phoneMatches && phoneMatches.length > 0) {
    addUnique(matches, REASON.PHONE_NUMBER_REQUEST, 20);
  }

  // 3. Email addresses (off-platform contact)
  const emailMatches = text.match(EMAIL_PATTERN);
  if (emailMatches) {
    const externalEmails = emailMatches.filter(
      (e) => !e.toLowerCase().endsWith("@deelmarkt.nl"),
    );
    if (externalEmails.length > 0) {
      addUnique(matches, REASON.OFF_SITE_CONTACT, 15);
    }
  }

  // 4. Off-platform messaging (also maps to off_site_contact)
  OFFPLATFORM_MESSAGING_PATTERN.lastIndex = 0;
  if (OFFPLATFORM_MESSAGING_PATTERN.test(normalised)) {
    addUnique(matches, REASON.OFF_SITE_CONTACT, 20);
  }

  // 5. Off-platform payment
  OFFPLATFORM_PAYMENT_PATTERN.lastIndex = 0;
  if (OFFPLATFORM_PAYMENT_PATTERN.test(normalised)) {
    addUnique(matches, REASON.EXTERNAL_PAYMENT_LINK, 25);
  }

  // 6. NLP keyword rules
  for (const [pattern, reason, weight] of KEYWORD_RULES) {
    pattern.lastIndex = 0;
    if (pattern.test(text)) {
      addUnique(matches, reason, weight);
    }
  }

  // 7. Prohibited items
  PROHIBITED_ITEMS_PATTERN.lastIndex = 0;
  if (PROHIBITED_ITEMS_PATTERN.test(text)) {
    addUnique(matches, REASON.PROHIBITED_ITEM, 10);
  }

  // Calculate total score
  const score = matches.reduce((sum, m) => sum + m.weight, 0);
  const reasons = matches.map((m) => m.reason);

  let confidence: "none" | "low" | "high";
  if (score === 0) {
    confidence = "none";
  } else if (score < 40) {
    confidence = "low";
  } else {
    confidence = "high";
  }

  return { confidence, reasons, score };
}
