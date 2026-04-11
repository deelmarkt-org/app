import 'package:flutter_test/flutter_test.dart';
import 'package:deelmarkt/features/admin/domain/entities/severity_level.dart';

void main() {
  group('SeverityLevel', () {
    test('has exactly 4 values', () {
      expect(SeverityLevel.values.length, equals(4));
    });

    test('contains low', () {
      expect(SeverityLevel.values, contains(SeverityLevel.low));
    });

    test('contains medium', () {
      expect(SeverityLevel.values, contains(SeverityLevel.medium));
    });

    test('contains high', () {
      expect(SeverityLevel.values, contains(SeverityLevel.high));
    });

    test('contains critical', () {
      expect(SeverityLevel.values, contains(SeverityLevel.critical));
    });
  });
}
