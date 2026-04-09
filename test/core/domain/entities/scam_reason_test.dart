import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';

void main() {
  group('ScamReason.fromDb', () {
    test('maps all known reason strings', () {
      expect(
        ScamReason.fromDb('external_payment_link'),
        ScamReason.externalPaymentLink,
      );
      expect(ScamReason.fromDb('off_site_contact'), ScamReason.offSiteContact);
      expect(
        ScamReason.fromDb('phone_number_request'),
        ScamReason.phoneNumberRequest,
      );
      expect(
        ScamReason.fromDb('suspicious_pricing'),
        ScamReason.suspiciousPricing,
      );
      expect(ScamReason.fromDb('urgency_pressure'), ScamReason.urgencyPressure);
      expect(
        ScamReason.fromDb('credential_harvesting'),
        ScamReason.credentialHarvesting,
      );
      expect(
        ScamReason.fromDb('advance_payment_request'),
        ScamReason.advancePaymentRequest,
      );
      expect(ScamReason.fromDb('fake_escrow'), ScamReason.fakeEscrow);
      expect(ScamReason.fromDb('shipping_scam'), ScamReason.shippingScam);
      expect(ScamReason.fromDb('prohibited_item'), ScamReason.prohibitedItem);
    });

    test('falls back to other for unknown strings', () {
      expect(ScamReason.fromDb('unknown_value'), ScamReason.other);
      expect(ScamReason.fromDb(''), ScamReason.other);
    });
  });

  group('ScamReason.localizationKey', () {
    test('every reason has a non-empty l10n key', () {
      for (final reason in ScamReason.values) {
        expect(reason.localizationKey, isNotEmpty);
        expect(reason.localizationKey, startsWith('scam_alert.reason.'));
      }
    });

    test('all keys are unique', () {
      final keys = ScamReason.values.map((r) => r.localizationKey).toList();
      expect(keys.toSet().length, keys.length);
    });
  });

  group('ScamConfidence.fromDb', () {
    test('maps known values', () {
      expect(ScamConfidence.fromDb('none'), ScamConfidence.none);
      expect(ScamConfidence.fromDb('low'), ScamConfidence.low);
      expect(ScamConfidence.fromDb('high'), ScamConfidence.high);
    });

    test('falls back to none for null or unknown', () {
      expect(ScamConfidence.fromDb(null), ScamConfidence.none);
      expect(ScamConfidence.fromDb('unknown'), ScamConfidence.none);
    });
  });
}
