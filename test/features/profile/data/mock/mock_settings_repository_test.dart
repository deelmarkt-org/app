import 'package:deelmarkt/features/profile/data/mock/mock_settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MockSettingsRepository repository;

  setUp(() {
    repository = MockSettingsRepository();
  });

  group('MockSettingsRepository', () {
    group('getNotificationPreferences', () {
      test('returns default preferences', () async {
        final prefs = await repository.getNotificationPreferences();

        expect(prefs, equals(const NotificationPreferences()));
        expect(prefs.messages, isTrue);
        expect(prefs.offers, isTrue);
        expect(prefs.shippingUpdates, isTrue);
        expect(prefs.marketing, isFalse);
      });
    });

    group('updateNotificationPreferences', () {
      test('persists changes', () async {
        const updated = NotificationPreferences(
          messages: false,
          shippingUpdates: false,
          marketing: true,
        );

        await repository.updateNotificationPreferences(updated);
        final result = await repository.getNotificationPreferences();

        expect(result, equals(updated));
      });
    });

    group('getAddresses', () {
      test('returns 2 mock addresses', () async {
        final addresses = await repository.getAddresses();

        expect(addresses, hasLength(2));
      });

      test('first address is Amsterdam', () async {
        final addresses = await repository.getAddresses();

        expect(addresses.first.city, 'Amsterdam');
        expect(addresses.first.postcode, '1012 AB');
      });

      test('second address is Rotterdam', () async {
        final addresses = await repository.getAddresses();

        expect(addresses.last.city, 'Rotterdam');
        expect(addresses.last.postcode, '3011 HE');
      });
    });

    group('saveAddress', () {
      test('adds new address', () async {
        const newAddress = DutchAddress(
          postcode: '2511 BT',
          houseNumber: '10',
          street: 'Binnenhof',
          city: 'Den Haag',
        );

        await repository.saveAddress(newAddress);
        final addresses = await repository.getAddresses();

        expect(addresses, hasLength(3));
        expect(addresses.last.city, 'Den Haag');
      });

      test('updates existing address by postcode and house number', () async {
        const updatedAddress = DutchAddress(
          postcode: '1012 AB',
          houseNumber: '42',
          street: 'Nieuwe Damstraat',
          city: 'Amsterdam',
        );

        await repository.saveAddress(updatedAddress);
        final addresses = await repository.getAddresses();

        expect(addresses, hasLength(2));
        expect(addresses.first.street, 'Nieuwe Damstraat');
      });
    });

    group('deleteAddress', () {
      test('removes address', () async {
        const addressToDelete = DutchAddress(
          postcode: '1012 AB',
          houseNumber: '42',
          street: 'Damstraat',
          city: 'Amsterdam',
        );

        await repository.deleteAddress(addressToDelete);
        final addresses = await repository.getAddresses();

        expect(addresses, hasLength(1));
        expect(addresses.first.city, 'Rotterdam');
      });
    });

    group('exportUserData', () {
      test('returns URL', () async {
        final url = await repository.exportUserData();

        expect(url, isA<String>());
        expect(url, contains('https://'));
        expect(url, contains('deelmarkt.nl'));
      });
    });

    group('deleteAccount', () {
      test('completes without error', () async {
        await expectLater(repository.deleteAccount(), completes);
      });
    });
  });
}
