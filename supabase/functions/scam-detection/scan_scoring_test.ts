/**
 * Tests for scam detection confidence scoring and combined scenarios (R-35).
 *
 * Verifies the score thresholds (none / low / high), multi-rule accumulation,
 * and realistic scam message patterns.
 */

import {
  assertEquals,
  assert,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";
import { scanMessage } from "./scan_engine.ts";

// ===========================================================================
// Confidence scoring thresholds
// ===========================================================================

describe("scanMessage — confidence scoring", () => {
  it("returns 'none' for score 0", () => {
    const result = scanMessage("Normale vraag over het product");
    assertEquals(result.confidence, "none");
    assertEquals(result.score, 0);
  });

  it("returns 'low' for score 1–39", () => {
    // Single external link = 15 points → low
    const result = scanMessage("Check https://example.com");
    assertEquals(result.confidence, "low");
    assert(result.score > 0);
    assert(result.score < 40);
  });

  it("returns 'high' for score >= 40", () => {
    // Phone (20) + off-platform payment (25) = 45 → high
    const result = scanMessage("Bel me op 06 12345678, ik stuur je een Tikkie");
    assertEquals(result.confidence, "high");
    assert(result.score >= 40);
  });

  it("accumulates multiple rule matches", () => {
    const result = scanMessage(
      "Urgent! Klik op https://fake.com, bel 06 12345678, betaal via Tikkie",
    );
    assertEquals(result.confidence, "high");
    assert(result.score >= 50);
    assert(result.reasons.length >= 3);
  });
});

// ===========================================================================
// Combined realistic scam scenarios
// ===========================================================================

describe("scanMessage — combined scam scenarios", () => {
  it("detects advance-fee scam pattern", () => {
    const result = scanMessage(
      "Ik wil het item kopen! Stuur geld voor verzendkosten via Western Union. Hier is mijn link: https://fake-escrow.com",
    );
    assertEquals(result.confidence, "high");
    assert(result.reasons.includes("advance_payment_request"));
    assert(result.reasons.includes("external_payment_link"));
  });

  it("detects phishing attempt", () => {
    const result = scanMessage(
      "Please send your password and credit card details to verify your account at https://phishing-site.com",
    );
    assertEquals(result.confidence, "high");
    assert(result.reasons.includes("credential_harvesting"));
    assert(result.reasons.includes("external_payment_link"));
  });

  it("detects off-platform redirect attempt", () => {
    const result = scanMessage(
      "Stuur me een bericht op WhatsApp +31 6 98765432 dan maak ik het geld over via Tikkie",
    );
    assertEquals(result.confidence, "high");
    assert(result.reasons.includes("off_site_contact"));
    assert(result.reasons.includes("phone_number_request"));
    assert(result.reasons.includes("external_payment_link"));
  });
});

// ===========================================================================
// Reason string alignment with frontend ScamReason.fromDb()
// ===========================================================================

describe("scanMessage — reason string alignment with frontend", () => {
  const VALID_FRONTEND_REASONS = [
    "external_payment_link",
    "off_site_contact",
    "phone_number_request",
    "suspicious_pricing",
    "urgency_pressure",
    "credential_harvesting",
    "advance_payment_request",
    "fake_escrow",
    "shipping_scam",
    "prohibited_item",
  ];

  it("external links use 'external_payment_link'", () => {
    const result = scanMessage("Visit https://scam.com now");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("phone numbers use 'phone_number_request'", () => {
    const result = scanMessage("Bel me op 06 12345678");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("email uses 'off_site_contact'", () => {
    const result = scanMessage("Mail me op test@gmail.com");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("WhatsApp uses 'off_site_contact'", () => {
    const result = scanMessage("Stuur me een bericht op WhatsApp");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("Tikkie uses 'external_payment_link'", () => {
    const result = scanMessage("Ik stuur je een Tikkie");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("urgency uses 'urgency_pressure'", () => {
    const result = scanMessage("Dit is urgent, nu betalen!");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("free/won uses 'suspicious_pricing'", () => {
    const result = scanMessage("Congratulations! You won a free prize!");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("deposit uses 'advance_payment_request'", () => {
    const result = scanMessage("Je moet een aanbetaling doen");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("password uses 'credential_harvesting'", () => {
    const result = scanMessage("Stuur me je wachtwoord");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("escrow service uses 'fake_escrow'", () => {
    const result = scanMessage("Gebruik mijn escrow service");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("weapon uses 'prohibited_item'", () => {
    const result = scanMessage("Ik heb een wapen te koop");
    assert(VALID_FRONTEND_REASONS.includes(result.reasons[0]));
  });

  it("all returned reasons are valid frontend enum values", () => {
    const scamText =
      "URGENT! Visit https://scam.com, bel 06 12345678, stuur me op WhatsApp, " +
      "betaal via Tikkie, stuur je wachtwoord, aanbetaling verplicht, " +
      "gebruik mijn escrow service, ik heb een wapen";
    const result = scanMessage(scamText);
    for (const reason of result.reasons) {
      assert(
        VALID_FRONTEND_REASONS.includes(reason),
        `Reason '${reason}' is not a valid frontend ScamReason value`,
      );
    }
  });
});
