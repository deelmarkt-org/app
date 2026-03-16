import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late Map<String, dynamic> nlStrings;
  late Map<String, dynamic> enStrings;

  setUpAll(() {
    final nlFile = File('assets/l10n/nl-NL.json');
    final enFile = File('assets/l10n/en-US.json');

    expect(nlFile.existsSync(), isTrue, reason: 'nl-NL.json must exist');
    expect(enFile.existsSync(), isTrue, reason: 'en-US.json must exist');

    nlStrings = jsonDecode(nlFile.readAsStringSync()) as Map<String, dynamic>;
    enStrings = jsonDecode(enFile.readAsStringSync()) as Map<String, dynamic>;
  });

  group('String file structure', () {
    test('NL file parses as valid JSON', () {
      expect(nlStrings, isNotEmpty);
    });

    test('EN file parses as valid JSON', () {
      expect(enStrings, isNotEmpty);
    });

    test('both files have identical top-level keys', () {
      final nlKeys = nlStrings.keys.toSet();
      final enKeys = enStrings.keys.toSet();

      expect(nlKeys, equals(enKeys),
          reason: 'Top-level keys must match between NL and EN');
    });

    test('both files have identical nested keys', () {
      final nlNestedKeys = _flattenKeys(nlStrings);
      final enNestedKeys = _flattenKeys(enStrings);

      final missingInEn = nlNestedKeys.difference(enNestedKeys);
      final missingInNl = enNestedKeys.difference(nlNestedKeys);

      expect(missingInEn, isEmpty,
          reason: 'Keys in NL but missing in EN: $missingInEn');
      expect(missingInNl, isEmpty,
          reason: 'Keys in EN but missing in NL: $missingInNl');
    });

    test('no empty string values in NL file', () {
      final emptyKeys = _findEmptyValues(nlStrings);
      expect(emptyKeys, isEmpty,
          reason: 'Empty values found in NL: $emptyKeys');
    });

    test('no empty string values in EN file', () {
      final emptyKeys = _findEmptyValues(enStrings);
      expect(emptyKeys, isEmpty,
          reason: 'Empty values found in EN: $emptyKeys');
    });
  });

  group('String count', () {
    test('NL file has at least 20 keys (SPRINT-PLAN minimum)', () {
      final keyCount = _flattenKeys(nlStrings).length;
      expect(keyCount, greaterThanOrEqualTo(20));
    });

    test('both files have the same number of keys', () {
      final nlCount = _flattenKeys(nlStrings).length;
      final enCount = _flattenKeys(enStrings).length;
      expect(nlCount, equals(enCount));
    });
  });

  group('Required categories', () {
    test('has navigation strings', () {
      expect(nlStrings.containsKey('nav'), isTrue);
    });

    test('has action strings', () {
      expect(nlStrings.containsKey('action'), isTrue);
    });

    test('has form labels', () {
      expect(nlStrings.containsKey('form'), isTrue);
    });

    test('has error messages', () {
      expect(nlStrings.containsKey('error'), isTrue);
    });

    test('has empty state messages', () {
      expect(nlStrings.containsKey('empty'), isTrue);
    });

    test('has listing strings', () {
      expect(nlStrings.containsKey('listing'), isTrue);
    });

    test('has auth strings', () {
      expect(nlStrings.containsKey('auth'), isTrue);
    });

    test('has accessibility strings', () {
      expect(nlStrings.containsKey('a11y'), isTrue);
    });
  });
}

/// Recursively flatten nested map keys into dot-notation set.
Set<String> _flattenKeys(Map<String, dynamic> map, [String prefix = '']) {
  final result = <String>{};
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      result.addAll(
          _flattenKeys(entry.value as Map<String, dynamic>, key));
    } else {
      result.add(key);
    }
  }
  return result;
}

/// Find keys with empty string values.
List<String> _findEmptyValues(Map<String, dynamic> map, [String prefix = '']) {
  final result = <String>[];
  for (final entry in map.entries) {
    final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
    if (entry.value is Map<String, dynamic>) {
      result.addAll(
          _findEmptyValues(entry.value as Map<String, dynamic>, key));
    } else if (entry.value is String && (entry.value as String).isEmpty) {
      result.add(key);
    }
  }
  return result;
}
