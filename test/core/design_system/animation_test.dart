import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// Tests for [DeelmarktAnimation] — Tier-1 Audit L-05.
///
/// Verifies all animation tokens are sensible and the [resolve] helper
/// correctly suppresses motion when reduced motion is enabled.
void main() {
  group('DeelmarktAnimation durations', () {
    test('quick is 150ms', () {
      expect(
        DeelmarktAnimation.quick,
        equals(const Duration(milliseconds: 150)),
      );
    });

    test('standard is 200ms', () {
      expect(
        DeelmarktAnimation.standard,
        equals(const Duration(milliseconds: 200)),
      );
    });

    test('emphasis is 500ms', () {
      expect(
        DeelmarktAnimation.emphasis,
        equals(const Duration(milliseconds: 500)),
      );
    });

    test('shimmer is 1500ms', () {
      expect(
        DeelmarktAnimation.shimmer,
        equals(const Duration(milliseconds: 1500)),
      );
    });

    test('durations are in ascending order', () {
      expect(DeelmarktAnimation.quick < DeelmarktAnimation.standard, isTrue);
      expect(DeelmarktAnimation.standard < DeelmarktAnimation.emphasis, isTrue);
      expect(DeelmarktAnimation.emphasis < DeelmarktAnimation.shimmer, isTrue);
    });
  });

  group('DeelmarktAnimation curves', () {
    test('curveStandard is easeOutCubic', () {
      expect(DeelmarktAnimation.curveStandard, equals(Curves.easeOutCubic));
    });

    test('curveEntrance is easeOut', () {
      expect(DeelmarktAnimation.curveEntrance, equals(Curves.easeOut));
    });

    test('curveExit is easeIn', () {
      expect(DeelmarktAnimation.curveExit, equals(Curves.easeIn));
    });

    test('curveBounce is elasticOut', () {
      expect(DeelmarktAnimation.curveBounce, equals(Curves.elasticOut));
    });
  });

  group('DeelmarktAnimation.resolve', () {
    test('returns Duration.zero when reduced motion is enabled', () {
      expect(
        DeelmarktAnimation.resolve(
          DeelmarktAnimation.standard,
          reduceMotion: true,
        ),
        equals(Duration.zero),
      );
    });

    test('returns original duration when reduced motion is disabled', () {
      expect(
        DeelmarktAnimation.resolve(
          DeelmarktAnimation.standard,
          reduceMotion: false,
        ),
        equals(DeelmarktAnimation.standard),
      );
    });

    test('works with all duration tokens when reduced motion is true', () {
      for (final duration in [
        DeelmarktAnimation.quick,
        DeelmarktAnimation.standard,
        DeelmarktAnimation.emphasis,
        DeelmarktAnimation.shimmer,
      ]) {
        expect(
          DeelmarktAnimation.resolve(duration, reduceMotion: true),
          equals(Duration.zero),
          reason: 'Expected Duration.zero for $duration with reduceMotion',
        );
      }
    });

    test('works with all duration tokens when reduced motion is false', () {
      final durations = [
        DeelmarktAnimation.quick,
        DeelmarktAnimation.standard,
        DeelmarktAnimation.emphasis,
        DeelmarktAnimation.shimmer,
      ];
      for (final duration in durations) {
        expect(
          DeelmarktAnimation.resolve(duration, reduceMotion: false),
          equals(duration),
          reason: 'Expected $duration to pass through with reduceMotion=false',
        );
      }
    });

    test('handles custom durations', () {
      const custom = Duration(milliseconds: 750);
      expect(
        DeelmarktAnimation.resolve(custom, reduceMotion: false),
        equals(custom),
      );
      expect(
        DeelmarktAnimation.resolve(custom, reduceMotion: true),
        equals(Duration.zero),
      );
    });
  });
}
