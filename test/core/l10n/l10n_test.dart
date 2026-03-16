import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/l10n/l10n.dart';

void main() {
  group('AppLocales', () {
    test('nl locale has correct language and country code', () {
      expect(AppLocales.nl.languageCode, 'nl');
      expect(AppLocales.nl.countryCode, 'NL');
    });

    test('en locale has correct language and country code', () {
      expect(AppLocales.en.languageCode, 'en');
      expect(AppLocales.en.countryCode, 'US');
    });

    test('supported locales contains both NL and EN', () {
      expect(AppLocales.supportedLocales, hasLength(2));
      expect(AppLocales.supportedLocales, contains(AppLocales.nl));
      expect(AppLocales.supportedLocales, contains(AppLocales.en));
    });

    test('NL is the primary locale (first in list)', () {
      expect(AppLocales.supportedLocales.first, AppLocales.nl);
    });

    test('fallback locale is NL', () {
      expect(AppLocales.fallbackLocale, AppLocales.nl);
    });

    test('path points to assets/l10n', () {
      expect(AppLocales.path, 'assets/l10n');
    });

    test('locales are const and immutable', () {
      expect(identical(AppLocales.nl, const Locale('nl', 'NL')), isTrue);
      expect(identical(AppLocales.en, const Locale('en', 'US')), isTrue);
    });
  });
}
