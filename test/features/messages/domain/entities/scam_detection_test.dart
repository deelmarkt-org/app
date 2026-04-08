import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ScamReason.localizationKey', () {
    test('returns snake_case keys for all values', () {
      expect(
        ScamReason.externalPaymentLink.localizationKey,
        'scam_alert.reason.external_payment_link',
      );
      expect(
        ScamReason.offSiteContact.localizationKey,
        'scam_alert.reason.off_site_contact',
      );
      expect(
        ScamReason.phoneNumberRequest.localizationKey,
        'scam_alert.reason.phone_number_request',
      );
      expect(
        ScamReason.suspiciousPricing.localizationKey,
        'scam_alert.reason.suspicious_pricing',
      );
      expect(
        ScamReason.urgencyPressure.localizationKey,
        'scam_alert.reason.urgency_pressure',
      );
      expect(ScamReason.other.localizationKey, 'scam_alert.reason.other');
    });
  });

  group('ScamReason.fromDb', () {
    test('maps known DB values correctly', () {
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
    });

    test('falls back to other for unknown values', () {
      expect(ScamReason.fromDb('unknown_reason'), ScamReason.other);
      expect(ScamReason.fromDb(''), ScamReason.other);
    });
  });

  group('ScamConfidence.fromDb', () {
    test('maps known DB values correctly', () {
      expect(ScamConfidence.fromDb('low'), ScamConfidence.low);
      expect(ScamConfidence.fromDb('high'), ScamConfidence.high);
    });

    test('falls back to none for unknown or null values', () {
      expect(ScamConfidence.fromDb(null), ScamConfidence.none);
      expect(ScamConfidence.fromDb('unknown'), ScamConfidence.none);
    });
  });
}
