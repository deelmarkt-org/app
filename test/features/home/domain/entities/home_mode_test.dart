import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/home/domain/entities/home_mode.dart';

void main() {
  group('HomeMode', () {
    test('toStorage returns correct string values', () {
      expect(HomeMode.buyer.toStorage(), 'buyer');
      expect(HomeMode.seller.toStorage(), 'seller');
    });

    test('fromStorage parses known values', () {
      expect(HomeMode.fromStorage('buyer'), HomeMode.buyer);
      expect(HomeMode.fromStorage('seller'), HomeMode.seller);
    });

    test('fromStorage defaults to buyer for unknown values', () {
      expect(HomeMode.fromStorage('unknown'), HomeMode.buyer);
      expect(HomeMode.fromStorage(''), HomeMode.buyer);
    });

    test('round-trip toStorage/fromStorage', () {
      for (final mode in HomeMode.values) {
        expect(HomeMode.fromStorage(mode.toStorage()), mode);
      }
    });
  });
}
