import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state_copy_with.dart';

void main() {
  group('ListingCreationStateCopyWith', () {
    const base = ListingCreationState(
      title: 'Base Title',
      priceInCents: 1000,
      errorKey: 'some.existing.key',
    );

    test('copyWith() with no args returns equal state', () {
      final copy = base.copyWith();
      expect(copy, equals(base));
    });

    test('copyWith(title:) updates title and keeps other fields', () {
      final copy = base.copyWith(title: 'New Title');
      expect(copy.title, 'New Title');
      expect(copy.priceInCents, base.priceInCents);
      expect(copy.errorKey, base.errorKey);
      expect(copy.step, base.step);
    });

    test('copyWith(errorKey: () => value) sets the errorKey', () {
      final copy = base.copyWith(errorKey: () => 'some.key');
      expect(copy.errorKey, 'some.key');
    });

    test('copyWith(errorKey: () => null) clears the errorKey', () {
      final copy = base.copyWith(errorKey: () => null);
      expect(copy.errorKey, isNull);
    });

    test('omitting errorKey keeps the existing value', () {
      final copy = base.copyWith(title: 'Changed');
      expect(copy.errorKey, base.errorKey);
    });
  });
}
