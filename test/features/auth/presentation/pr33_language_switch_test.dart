import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/resend_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/register_viewmodel.dart';

// ---------------------------------------------------------------------------
// Mocks for ViewModel-level tests
// ---------------------------------------------------------------------------

class MockRegisterWithEmailUseCase extends Mock
    implements RegisterWithEmailUseCase {}

class MockResendEmailOtpUseCase extends Mock implements ResendEmailOtpUseCase {}

class MockVerifyEmailOtpUseCase extends Mock implements VerifyEmailOtpUseCase {}

class MockSendPhoneOtpUseCase extends Mock implements SendPhoneOtpUseCase {}

class MockVerifyPhoneOtpUseCase extends Mock implements VerifyPhoneOtpUseCase {}

// ---------------------------------------------------------------------------
// Fake Notifier for screen-level tests
// ---------------------------------------------------------------------------

class FakeRegisterViewModel extends AutoDisposeNotifier<RegistrationState>
    with Mock
    implements RegisterViewModel {
  FakeRegisterViewModel(this._state);

  final RegistrationState _state;

  @override
  RegistrationState build() => _state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Item 2: NL ↔ EN language switch', () {
    /// All auth-related l10n keys used in the registration flow.
    final authKeys = [
      'auth.register',
      'auth.welcome',
      'auth.verify_email_title',
      'auth.verify_email_subtitle',
      'auth.phone_entry_title',
      'auth.phone_entry_subtitle',
      'auth.verify_phone_title',
      'auth.verify_phone_subtitle',
      'auth.otp_resend',
      'auth.otp_resend_timer',
      'auth.create_account',
      'auth.send_code',
      'auth.already_have_account',
      'auth.terms_agree_prefix',
      'auth.terms_link',
      'auth.privacy_agree_prefix',
      'auth.privacy_link',
      'auth.otp_field_label',
    ];

    final validationKeys = [
      'validation.email_required',
      'validation.email_invalid',
      'validation.password_required',
      'validation.password_too_short',
      'validation.password_needs_uppercase',
      'validation.password_needs_lowercase',
      'validation.password_needs_digit',
      'validation.phone_required',
      'validation.phone_invalid',
      'validation.terms_required',
    ];

    final errorKeys = [
      'error.generic',
      'error.network',
      'error.email_taken',
      'error.otp_expired',
      'error.otp_invalid',
      'error.rate_limited',
    ];

    final strengthKeys = [
      'password_strength.weak',
      'password_strength.fair',
      'password_strength.strong',
      'password_strength.very_strong',
    ];

    final formKeys = [
      'form.email',
      'form.pass_field',
      'form.phone',
      'form.show_password',
      'form.hide_password',
    ];

    /// Reads a nested JSON map and flattens into dot-separated keys.
    Set<String> flattenKeys(Map<String, dynamic> json, [String prefix = '']) {
      final keys = <String>{};
      for (final entry in json.entries) {
        final key = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
        if (entry.value is Map<String, dynamic>) {
          keys.addAll(flattenKeys(entry.value as Map<String, dynamic>, key));
        } else {
          keys.add(key);
        }
      }
      return keys;
    }

    test('all auth-related l10n keys exist in en-US.json', () async {
      final enJson = await rootBundle.loadString('assets/l10n/en-US.json');
      final enMap = json.decode(enJson) as Map<String, dynamic>;
      final enKeys = flattenKeys(enMap);

      final allRequired = [
        ...authKeys,
        ...validationKeys,
        ...errorKeys,
        ...strengthKeys,
        ...formKeys,
      ];

      for (final key in allRequired) {
        expect(enKeys, contains(key), reason: 'Missing EN key: $key');
      }
    });

    test('all auth-related l10n keys exist in nl-NL.json', () async {
      final nlJson = await rootBundle.loadString('assets/l10n/nl-NL.json');
      final nlMap = json.decode(nlJson) as Map<String, dynamic>;
      final nlKeys = flattenKeys(nlMap);

      final allRequired = [
        ...authKeys,
        ...validationKeys,
        ...errorKeys,
        ...strengthKeys,
        ...formKeys,
      ];

      for (final key in allRequired) {
        expect(nlKeys, contains(key), reason: 'Missing NL key: $key');
      }
    });

    test('EN and NL have the same top-level key set (no drift)', () async {
      final enJson = await rootBundle.loadString('assets/l10n/en-US.json');
      final nlJson = await rootBundle.loadString('assets/l10n/nl-NL.json');
      final enMap = json.decode(enJson) as Map<String, dynamic>;
      final nlMap = json.decode(nlJson) as Map<String, dynamic>;
      final enKeys = flattenKeys(enMap);
      final nlKeys = flattenKeys(nlMap);

      final missingInNl = enKeys.difference(nlKeys);
      final missingInEn = nlKeys.difference(enKeys);

      expect(
        missingInNl,
        isEmpty,
        reason: 'Keys in EN but missing in NL: $missingInNl',
      );
      expect(
        missingInEn,
        isEmpty,
        reason: 'Keys in NL but missing in EN: $missingInEn',
      );
    });

    test('NL translations are not empty and differ from EN', () async {
      final enJson = await rootBundle.loadString('assets/l10n/en-US.json');
      final nlJson = await rootBundle.loadString('assets/l10n/nl-NL.json');
      final enMap = json.decode(enJson) as Map<String, dynamic>;
      final nlMap = json.decode(nlJson) as Map<String, dynamic>;

      // Spot-check NL auth translations differ from EN (aren't just copied)
      String? getValue(Map<String, dynamic> map, String dotPath) {
        final parts = dotPath.split('.');
        dynamic current = map;
        for (final part in parts) {
          if (current is! Map<String, dynamic>) return null;
          current = current[part];
        }
        return current is String ? current : null;
      }

      // These keys MUST differ between NL and EN
      final mustDiffer = [
        'auth.register',
        'auth.welcome',
        'auth.create_account',
        'auth.verify_email_title',
        'auth.phone_entry_title',
        'validation.email_required',
        'error.generic',
        'error.network',
        'password_strength.weak',
      ];

      for (final key in mustDiffer) {
        final enVal = getValue(enMap, key);
        final nlVal = getValue(nlMap, key);
        expect(enVal, isNotNull, reason: 'EN value for $key is null');
        expect(nlVal, isNotNull, reason: 'NL value for $key is null');
        expect(
          enVal,
          isNot(equals(nlVal)),
          reason: 'EN and NL have same value for $key: "$enVal"',
        );
      }
    });

    test('app supports both NL and EN locales', () {
      expect(
        AppLocales.supportedLocales,
        containsAll([const Locale('nl', 'NL'), const Locale('en', 'US')]),
      );
    });
  });
}
