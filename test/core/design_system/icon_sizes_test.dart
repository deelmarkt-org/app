import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/icon_sizes.dart';

void main() {
  group('DeelmarktIconSize', () {
    test('defines ascending size scale', () {
      expect(DeelmarktIconSize.xs, 16);
      expect(DeelmarktIconSize.sm, 20);
      expect(DeelmarktIconSize.md, 24);
      expect(DeelmarktIconSize.lg, 32);
      expect(DeelmarktIconSize.xl, 48);
      expect(DeelmarktIconSize.hero, 64);
    });

    test('all sizes are positive', () {
      final sizes = [
        DeelmarktIconSize.xs,
        DeelmarktIconSize.sm,
        DeelmarktIconSize.md,
        DeelmarktIconSize.lg,
        DeelmarktIconSize.xl,
        DeelmarktIconSize.hero,
      ];
      for (final size in sizes) {
        expect(size, greaterThan(0));
      }
    });
  });
}
