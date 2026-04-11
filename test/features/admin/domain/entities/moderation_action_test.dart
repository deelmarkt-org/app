import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/features/admin/domain/entities/moderation_action.dart';

void main() {
  group('ModerationAction', () {
    test('has exactly 5 values', () {
      expect(ModerationAction.values.length, equals(5));
    });

    test('contains approve', () {
      expect(ModerationAction.values, contains(ModerationAction.approve));
    });

    test('contains remove', () {
      expect(ModerationAction.values, contains(ModerationAction.remove));
    });

    test('contains warn', () {
      expect(ModerationAction.values, contains(ModerationAction.warn));
    });

    test('contains suspend', () {
      expect(ModerationAction.values, contains(ModerationAction.suspend));
    });

    test('contains ban', () {
      expect(ModerationAction.values, contains(ModerationAction.ban));
    });
  });
}
