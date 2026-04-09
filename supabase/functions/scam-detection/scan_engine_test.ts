/**
 * Tests for the scam detection scan engine (R-35 / E06).
 *
 * Tests the pure scanning logic: pattern matching, scoring, and confidence
 * levels. No HTTP, no Supabase — just input text → ScanResult.
 */

import {
  assertEquals,
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";
import { scanMessage } from "./scan_engine.ts";

// ===========================================================================
// Clean messages — must return "none"
// ===========================================================================

describe("scanMessage — clean messages", () => {
  it("returns 'none' for a normal greeting", () => {
    const result = scanMessage("Hoi, is dit item nog beschikbaar?");
    assertEquals(result.confidence, "none");
    assertEquals(result.reasons.length, 0);
    assertEquals(result.score, 0);
  });

  it("returns 'none' for a price negotiation", () => {
    const result = scanMessage("Zou je €25 accepteren in plaats van €30?");
    assertEquals(result.confidence, "none");
  });

  it("returns 'none' for a normal pickup arrangement", () => {
    const result = scanMessage("Ik kan morgen om 14:00 ophalen bij jou in Amsterdam");
    assertEquals(result.confidence, "none");
  });

  it("allows deelmarkt.nl links", () => {
    const result = scanMessage("Kijk op https://deelmarkt.nl/listing/123 voor meer info");
    assertEquals(result.confidence, "none");
  });

  it("allows deelmarkt.nl email addresses", () => {
    const result = scanMessage("Mail support@deelmarkt.nl als je vragen hebt");
    assertEquals(result.confidence, "none");
  });
});

// ===========================================================================
// Detection — external links
// ===========================================================================

describe("scanMessage — external links", () => {
  it("flags a single external URL", () => {
    const result = scanMessage("Bekijk het hier: https://suspicious-site.com/deal");
    assert(result.reasons.includes("external_payment_link"));
    assertEquals(result.confidence, "low");
  });

  it("flags multiple external URLs with higher weight", () => {
    const result = scanMessage("Check https://site1.com en https://site2.com");
    assert(result.reasons.includes("external_payment_link"));
    assertEquals(result.score, 25);
  });

  it("flags shortened URLs", () => {
    const result = scanMessage("Klik hier: bit.ly/abc123");
    assert(result.reasons.includes("external_payment_link"));
  });
});

// ===========================================================================
// Detection — phone numbers
// ===========================================================================

describe("scanMessage — phone numbers", () => {
  it("flags Dutch mobile numbers (06)", () => {
    const result = scanMessage("Bel me op 06 12345678");
    assert(result.reasons.includes("phone_number_request"));
  });

  it("flags Dutch numbers with +31 prefix", () => {
    const result = scanMessage("Mijn nummer is +31 6 12345678");
    assert(result.reasons.includes("phone_number_request"));
  });

  it("flags international numbers", () => {
    const result = scanMessage("Bel +44 7911 123456 voor snellere afhandeling");
    assert(result.reasons.includes("phone_number_request"));
  });
});

// ===========================================================================
// Detection — off-platform contact (email + messaging)
// ===========================================================================

describe("scanMessage — off-platform contact", () => {
  it("flags external email addresses as off_site_contact", () => {
    const result = scanMessage("Stuur me een mail op scammer@gmail.com");
    assert(result.reasons.includes("off_site_contact"));
  });

  it("does not flag deelmarkt.nl emails", () => {
    const result = scanMessage("Contact us at help@deelmarkt.nl");
    assert(!result.reasons.includes("off_site_contact"));
  });

  it("flags WhatsApp references", () => {
    const result = scanMessage("Stuur me een bericht op WhatsApp");
    assert(result.reasons.includes("off_site_contact"));
  });

  it("flags Telegram references", () => {
    const result = scanMessage("Contact me on Telegram for faster replies");
    assert(result.reasons.includes("off_site_contact"));
  });

  it("flags 'bel me' (call me)", () => {
    const result = scanMessage("Bel me even voor de details");
    assert(result.reasons.includes("off_site_contact"));
  });

  it("deduplicates email + messaging into one off_site_contact reason", () => {
    const result = scanMessage("Mail me op test@gmail.com of stuur een WhatsApp");
    const offSiteCount = result.reasons.filter((r) => r === "off_site_contact").length;
    assertEquals(offSiteCount, 1);
  });
});

// ===========================================================================
// Detection — off-platform payment
// ===========================================================================

describe("scanMessage — off-platform payment", () => {
  it("flags Tikkie references as external_payment_link", () => {
    const result = scanMessage("Ik stuur je een Tikkie");
    assert(result.reasons.includes("external_payment_link"));
  });

  it("flags bank transfer requests", () => {
    const result = scanMessage("Kun je het bedrag overmaken naar mijn IBAN?");
    assert(result.reasons.includes("external_payment_link"));
  });

  it("flags crypto payment requests", () => {
    const result = scanMessage("I accept Bitcoin payment only");
    assert(result.reasons.includes("external_payment_link"));
  });

  it("flags PayPal references", () => {
    const result = scanMessage("Send the money via PayPal please");
    assert(result.reasons.includes("external_payment_link"));
  });
});

// ===========================================================================
// Detection — NLP keyword patterns
// ===========================================================================

describe("scanMessage — NLP keyword patterns", () => {
  it("flags urgency language (Dutch)", () => {
    const result = scanMessage("Dit is dringend, je moet nu betalen!");
    assert(result.reasons.includes("urgency_pressure"));
  });

  it("flags too-good-to-be-true as suspicious_pricing", () => {
    const result = scanMessage("Congratulations! You won a free iPhone!");
    assert(result.reasons.includes("suspicious_pricing"));
  });

  it("flags advance payment requests", () => {
    const result = scanMessage("Je moet een aanbetaling doen van €50 voordat ik het verstuur");
    assert(result.reasons.includes("advance_payment_request"));
  });

  it("flags credential harvesting attempts", () => {
    const result = scanMessage("Stuur me je wachtwoord en inloggegevens");
    assert(result.reasons.includes("credential_harvesting"));
  });

  it("flags fake escrow references", () => {
    const result = scanMessage("Gebruik mijn escrow service voor veilige betaling");
    assert(result.reasons.includes("fake_escrow"));
  });
});

// ===========================================================================
// Detection — prohibited items
// ===========================================================================

describe("scanMessage — prohibited items", () => {
  it("flags weapon references", () => {
    const result = scanMessage("Ik heb een wapen te koop");
    assert(result.reasons.includes("prohibited_item"));
  });

  it("flags drug references", () => {
    const result = scanMessage("Selling some drugs here");
    assert(result.reasons.includes("prohibited_item"));
  });

  it("flags stolen goods references", () => {
    const result = scanMessage("Dit is niet gestolen, echt niet");
    assert(result.reasons.includes("prohibited_item"));
  });
});

// ===========================================================================
// Edge cases
// ===========================================================================

describe("scanMessage — edge cases", () => {
  it("handles empty string", () => {
    const result = scanMessage("");
    assertEquals(result.confidence, "none");
    assertEquals(result.score, 0);
  });

  it("handles very long messages without crashing", () => {
    const longText = "Dit is een normaal bericht. ".repeat(500);
    const result = scanMessage(longText);
    assertEquals(result.confidence, "none");
  });

  it("is case-insensitive for keywords", () => {
    const result = scanMessage("WHATSAPP me ASAP, very URGENT");
    assert(result.reasons.includes("off_site_contact"));
    assert(result.reasons.includes("urgency_pressure"));
  });
});
