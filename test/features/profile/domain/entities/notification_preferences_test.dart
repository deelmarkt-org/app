import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationPreferences', () {
    group('default values', () {
      test('messages defaults to true', () {
        const prefs = NotificationPreferences();
        expect(prefs.messages, isTrue);
      });

      test('offers defaults to true', () {
        const prefs = NotificationPreferences();
        expect(prefs.offers, isTrue);
      });

      test('shippingUpdates defaults to true', () {
        const prefs = NotificationPreferences();
        expect(prefs.shippingUpdates, isTrue);
      });

      test('marketing defaults to false', () {
        const prefs = NotificationPreferences();
        expect(prefs.marketing, isFalse);
      });
    });

    group('Equatable', () {
      test('same props are equal', () {
        const a = NotificationPreferences(offers: false);
        const b = NotificationPreferences(offers: false);
        expect(a, equals(b));
      });

      test('different props are not equal', () {
        const a = NotificationPreferences();
        const b = NotificationPreferences(messages: false, marketing: true);
        expect(a, isNot(equals(b)));
      });

      test('single field difference makes them not equal', () {
        const a = NotificationPreferences();
        const b = NotificationPreferences(marketing: true);
        expect(a, isNot(equals(b)));
      });
    });

    group('copyWith', () {
      test('creates new instance with updated field', () {
        const original = NotificationPreferences();
        final updated = original.copyWith(marketing: true);

        expect(updated.marketing, isTrue);
        expect(updated.messages, isTrue);
        expect(updated.offers, isTrue);
        expect(updated.shippingUpdates, isTrue);
      });

      test('does not mutate original', () {
        final original =
            const NotificationPreferences()..copyWith(messages: false);

        expect(original.messages, isTrue);
      });

      test('copies all fields when all specified', () {
        const original = NotificationPreferences();
        final updated = original.copyWith(
          messages: false,
          offers: false,
          shippingUpdates: false,
          marketing: true,
        );

        expect(updated.messages, isFalse);
        expect(updated.offers, isFalse);
        expect(updated.shippingUpdates, isFalse);
        expect(updated.marketing, isTrue);
      });

      test('returns equal instance when no fields changed', () {
        const original = NotificationPreferences();
        final copied = original.copyWith();

        expect(copied, equals(original));
      });
    });
  });
}
