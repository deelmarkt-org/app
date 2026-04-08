import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfferStatus.fromDb', () {
    test(
      'maps pending',
      () => expect(OfferStatus.fromDb('pending'), OfferStatus.pending),
    );
    test(
      'maps accepted',
      () => expect(OfferStatus.fromDb('accepted'), OfferStatus.accepted),
    );
    test(
      'maps declined',
      () => expect(OfferStatus.fromDb('declined'), OfferStatus.declined),
    );
    test(
      'returns null for unknown value',
      () => expect(OfferStatus.fromDb('unknown'), isNull),
    );
    test(
      'returns null for null input',
      () => expect(OfferStatus.fromDb(null), isNull),
    );
  });

  group('OfferStatus.toDb', () {
    test(
      'pending → "pending"',
      () => expect(OfferStatus.pending.toDb(), 'pending'),
    );
    test(
      'accepted → "accepted"',
      () => expect(OfferStatus.accepted.toDb(), 'accepted'),
    );
    test(
      'declined → "declined"',
      () => expect(OfferStatus.declined.toDb(), 'declined'),
    );
  });

  test('round-trip: fromDb(toDb(x)) == x', () {
    for (final status in OfferStatus.values) {
      expect(OfferStatus.fromDb(status.toDb()), status);
    }
  });
}
