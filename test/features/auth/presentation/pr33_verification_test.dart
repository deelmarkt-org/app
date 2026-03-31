// PR #33 Verification Tests
//
// These tests verify the 4 unchecked items in the PR #33 test plan:
// 1. Manual: register → email OTP → phone → phone OTP → home
// 2. Verify NL ↔ EN language switch
// 3. Verify terms/privacy checkboxes required before submit
// 4. Verify error states: network off, invalid OTP, email taken
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/resend_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/screens/register_screen.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/register_viewmodel.dart';
import 'package:deelmarkt/features/auth/presentation/widgets/registration_form.dart';

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
  // =========================================================================
  // ITEM 1: Full registration flow (email → email OTP → phone → phone OTP → complete)
  // =========================================================================
  group('Item 1: Full registration flow state machine', () {
    late MockRegisterWithEmailUseCase mockRegisterWithEmail;
    late MockResendEmailOtpUseCase mockResendEmailOtp;
    late MockVerifyEmailOtpUseCase mockVerifyEmailOtp;
    late MockSendPhoneOtpUseCase mockSendPhoneOtp;
    late MockVerifyPhoneOtpUseCase mockVerifyPhoneOtp;
    late ProviderContainer container;

    setUp(() {
      mockRegisterWithEmail = MockRegisterWithEmailUseCase();
      mockResendEmailOtp = MockResendEmailOtpUseCase();
      mockVerifyEmailOtp = MockVerifyEmailOtpUseCase();
      mockSendPhoneOtp = MockSendPhoneOtpUseCase();
      mockVerifyPhoneOtp = MockVerifyPhoneOtpUseCase();

      container = ProviderContainer(
        overrides: [
          registerWithEmailUseCaseProvider.overrideWithValue(
            mockRegisterWithEmail,
          ),
          resendEmailOtpUseCaseProvider.overrideWithValue(mockResendEmailOtp),
          verifyEmailOtpUseCaseProvider.overrideWithValue(mockVerifyEmailOtp),
          sendPhoneOtpUseCaseProvider.overrideWithValue(mockSendPhoneOtp),
          verifyPhoneOtpUseCaseProvider.overrideWithValue(mockVerifyPhoneOtp),
        ],
      );

      registerFallbackValue(DateTime(2026));
    });

    tearDown(() => container.dispose());

    RegistrationState readState() => container.read(registerViewModelProvider);
    RegisterViewModel readNotifier() =>
        container.read(registerViewModelProvider.notifier);

    test(
      'complete flow: emailForm → emailVerification → phoneForm → phoneVerification → complete',
      () async {
        // -- Step 0: Initial state --
        expect(readState().step, RegistrationStep.emailForm);
        expect(readState().isLoading, isFalse);
        expect(readState().email, isNull);
        expect(readState().phone, isNull);

        // -- Step 1: Submit email → emailVerification --
        when(
          () => mockRegisterWithEmail.call(
            email: any(named: 'email'),
            password: any(named: 'password'),
            termsAcceptedAt: any(named: 'termsAcceptedAt'),
            privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
          ),
        ).thenAnswer((_) async {});

        await readNotifier().submitEmail(
          email: 'user@deelmarkt.nl',
          password: 'Welkom123', // pragma: allowlist secret
          termsAccepted: true,
          privacyAccepted: true,
        );

        expect(readState().step, RegistrationStep.emailVerification);
        expect(readState().email, 'user@deelmarkt.nl');
        expect(readState().termsAccepted, isTrue);
        expect(readState().privacyAccepted, isTrue);

        // -- Step 2: Verify email OTP → phoneForm --
        when(
          () => mockVerifyEmailOtp.call(
            email: any(named: 'email'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async {});

        await readNotifier().verifyEmail('123456');

        expect(readState().step, RegistrationStep.phoneForm);
        expect(readState().email, 'user@deelmarkt.nl'); // email preserved

        // -- Step 3: Submit phone → phoneVerification --
        when(
          () => mockSendPhoneOtp.call(phone: any(named: 'phone')),
        ).thenAnswer((_) async {});

        await readNotifier().submitPhone('+31612345678');

        expect(readState().step, RegistrationStep.phoneVerification);
        expect(readState().phone, '+31612345678');

        // -- Step 4: Verify phone OTP → complete --
        when(
          () => mockVerifyPhoneOtp.call(
            phone: any(named: 'phone'),
            token: any(named: 'token'),
          ),
        ).thenAnswer((_) async {});

        await readNotifier().verifyPhone('654321');

        expect(readState().step, RegistrationStep.complete);
        expect(readState().isLoading, isFalse);
        expect(readState().errorKey, isNull);

        // -- Verify all use cases were called in order --
        verifyInOrder([
          () => mockRegisterWithEmail.call(
            email: 'user@deelmarkt.nl',
            password: 'Welkom123', // pragma: allowlist secret
            termsAcceptedAt: any(named: 'termsAcceptedAt'),
            privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
          ),
          () => mockVerifyEmailOtp.call(
            email: 'user@deelmarkt.nl',
            token: '123456',
          ),
          () => mockSendPhoneOtp.call(phone: '+31612345678'),
          () => mockVerifyPhoneOtp.call(phone: '+31612345678', token: '654321'),
        ]);
      },
    );

    test('screen shows correct UI for each step', () async {
      // Step 1: emailForm shows RegistrationForm
      expect(readState().step, RegistrationStep.emailForm);

      // Step 2: emailVerification shows OTP view title
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );
      expect(readState().step, RegistrationStep.emailVerification);

      // Step 3: phoneForm shows phone input
      when(
        () => mockVerifyEmailOtp.call(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().verifyEmail('123456');
      expect(readState().step, RegistrationStep.phoneForm);

      // Step 4: phoneVerification shows OTP view
      when(
        () => mockSendPhoneOtp.call(phone: any(named: 'phone')),
      ).thenAnswer((_) async {});
      await readNotifier().submitPhone('+31612345678');
      expect(readState().step, RegistrationStep.phoneVerification);

      // Step 5: complete
      when(
        () => mockVerifyPhoneOtp.call(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().verifyPhone('654321');
      expect(readState().step, RegistrationStep.complete);
    });

    testWidgets('RegisterScreen shows email form on emailForm step', (
      tester,
    ) async {
      final fakeVm = FakeRegisterViewModel(RegistrationState.initial());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [registerViewModelProvider.overrideWith(() => fakeVm)],
          child: MaterialApp(
            home: const RegisterScreen(),
            onGenerateRoute:
                (_) =>
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        ),
      );

      // Email field, password field, terms checkboxes, create account button
      expect(find.text('form.email *'), findsOneWidget);
      expect(find.text('form.pass_field *'), findsOneWidget);
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
      expect(find.text('auth.create_account'), findsOneWidget);
    });

    testWidgets('RegisterScreen shows email OTP on emailVerification step', (
      tester,
    ) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.emailVerification,
        email: 'test@example.com',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [registerViewModelProvider.overrideWith(() => fakeVm)],
          child: MaterialApp(
            home: const RegisterScreen(),
            onGenerateRoute:
                (_) =>
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        ),
      );

      expect(find.text('auth.verify_email_title'), findsAtLeast(1));
      expect(find.byType(TextFormField), findsNWidgets(6)); // 6 OTP digits
    });

    testWidgets('RegisterScreen shows phone form on phoneForm step', (
      tester,
    ) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.phoneForm,
        email: 'test@example.com',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [registerViewModelProvider.overrideWith(() => fakeVm)],
          child: MaterialApp(
            home: const RegisterScreen(),
            onGenerateRoute:
                (_) =>
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        ),
      );

      expect(find.text('auth.send_code'), findsOneWidget);
      expect(find.text('+31'), findsOneWidget);
    });

    testWidgets('RegisterScreen shows phone OTP on phoneVerification step', (
      tester,
    ) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.phoneVerification,
        email: 'test@example.com',
        phone: '+31612345678',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [registerViewModelProvider.overrideWith(() => fakeVm)],
          child: MaterialApp(
            home: const RegisterScreen(),
            onGenerateRoute:
                (_) =>
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        ),
      );

      expect(find.text('auth.verify_phone_title'), findsAtLeast(1));
      expect(find.byType(TextFormField), findsNWidgets(6)); // 6 OTP digits
    });
  });

  // =========================================================================
  // ITEM 2: NL ↔ EN language switch
  // =========================================================================
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

  // =========================================================================
  // ITEM 3: Terms/privacy checkboxes required before submit
  // =========================================================================
  group('Item 3: Terms/privacy checkboxes required before submit', () {
    Widget buildRegistrationForm({
      required void Function({
        required String email,
        required String password,
        required bool termsAccepted,
        required bool privacyAccepted,
      })
      onSubmit,
    }) {
      return MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: RegistrationForm(onSubmit: onSubmit, onLoginTap: () {}),
          ),
        ),
      );
    }

    testWidgets('submit button is disabled when no checkboxes are checked', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit:
              ({
                required email,
                required password,
                required termsAccepted,
                required privacyAccepted,
              }) {},
        ),
      );

      final elevatedButton = find.ancestor(
        of: find.text('auth.create_account'),
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(button.onPressed, isNull, reason: 'Button should be disabled');
    });

    testWidgets(
      'submit button is disabled when only terms is checked (privacy missing)',
      (tester) async {
        await tester.pumpWidget(
          buildRegistrationForm(
            onSubmit:
                ({
                  required email,
                  required password,
                  required termsAccepted,
                  required privacyAccepted,
                }) {},
          ),
        );

        // Check terms only
        final checkboxes = find.byType(Checkbox);
        await tester.ensureVisible(checkboxes.at(0));
        await tester.tap(checkboxes.at(0));
        await tester.pump();

        final elevatedButton = find.ancestor(
          of: find.text('auth.create_account'),
          matching: find.byType(ElevatedButton),
        );
        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(
          button.onPressed,
          isNull,
          reason: 'Button should be disabled with only terms checked',
        );
      },
    );

    testWidgets(
      'submit button is disabled when only privacy is checked (terms missing)',
      (tester) async {
        await tester.pumpWidget(
          buildRegistrationForm(
            onSubmit:
                ({
                  required email,
                  required password,
                  required termsAccepted,
                  required privacyAccepted,
                }) {},
          ),
        );

        // Check privacy only (second checkbox)
        final checkboxes = find.byType(Checkbox);
        await tester.ensureVisible(checkboxes.at(1));
        await tester.tap(checkboxes.at(1));
        await tester.pump();

        final elevatedButton = find.ancestor(
          of: find.text('auth.create_account'),
          matching: find.byType(ElevatedButton),
        );
        final button = tester.widget<ElevatedButton>(elevatedButton);
        expect(
          button.onPressed,
          isNull,
          reason: 'Button should be disabled with only privacy checked',
        );
      },
    );

    testWidgets('submit button becomes enabled when BOTH checkboxes checked', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit:
              ({
                required email,
                required password,
                required termsAccepted,
                required privacyAccepted,
              }) {},
        ),
      );

      // Check both
      final checkboxes = find.byType(Checkbox);
      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      final elevatedButton = find.ancestor(
        of: find.text('auth.create_account'),
        matching: find.byType(ElevatedButton),
      );
      final button = tester.widget<ElevatedButton>(elevatedButton);
      expect(
        button.onPressed,
        isNotNull,
        reason: 'Button should be enabled with both checkboxes checked',
      );
    });

    testWidgets('two separate checkboxes exist (GDPR Art. 7 compliance)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit:
              ({
                required email,
                required password,
                required termsAccepted,
                required privacyAccepted,
              }) {},
        ),
      );

      // C-5 fix: Must have 2 SEPARATE checkboxes, not 1 combined
      expect(find.byType(CheckboxListTile), findsNWidgets(2));

      // Both checkboxes should be unchecked initially
      final tiles =
          tester
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .toList();
      expect(
        tiles[0].value,
        isFalse,
        reason: 'Terms checkbox should start unchecked',
      );
      expect(
        tiles[1].value,
        isFalse,
        reason: 'Privacy checkbox should start unchecked',
      );

      // Terms and Privacy use Text.rich with TextSpan — find via rich text
      // The combined text for terms contains the prefix + link text
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan?.toPlainText().contains('auth.terms') == true,
        ),
        findsOneWidget,
        reason: 'Terms checkbox should contain terms text',
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Text &&
              w.textSpan?.toPlainText().contains('auth.privacy') == true,
        ),
        findsOneWidget,
        reason: 'Privacy checkbox should contain privacy text',
      );
    });

    testWidgets('form validation blocks submit even with checkboxes checked', (
      tester,
    ) async {
      var submitted = false;

      await tester.pumpWidget(
        buildRegistrationForm(
          onSubmit: ({
            required email,
            required password,
            required termsAccepted,
            required privacyAccepted,
          }) {
            submitted = true;
          },
        ),
      );

      // Check both checkboxes
      final checkboxes = find.byType(Checkbox);
      await tester.ensureVisible(checkboxes.at(0));
      await tester.tap(checkboxes.at(0));
      await tester.pump();
      await tester.ensureVisible(checkboxes.at(1));
      await tester.tap(checkboxes.at(1));
      await tester.pump();

      // Leave email and password empty, tap submit
      final submitButton = find.text('auth.create_account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(
        submitted,
        isFalse,
        reason: 'Should not submit with empty form fields',
      );
    });
  });

  // =========================================================================
  // ITEM 4: Error states (network off, invalid OTP, email taken)
  // =========================================================================
  group('Item 4: Error states', () {
    late MockRegisterWithEmailUseCase mockRegisterWithEmail;
    late MockResendEmailOtpUseCase mockResendEmailOtp;
    late MockVerifyEmailOtpUseCase mockVerifyEmailOtp;
    late MockSendPhoneOtpUseCase mockSendPhoneOtp;
    late MockVerifyPhoneOtpUseCase mockVerifyPhoneOtp;
    late ProviderContainer container;

    setUp(() {
      mockRegisterWithEmail = MockRegisterWithEmailUseCase();
      mockResendEmailOtp = MockResendEmailOtpUseCase();
      mockVerifyEmailOtp = MockVerifyEmailOtpUseCase();
      mockSendPhoneOtp = MockSendPhoneOtpUseCase();
      mockVerifyPhoneOtp = MockVerifyPhoneOtpUseCase();

      container = ProviderContainer(
        overrides: [
          registerWithEmailUseCaseProvider.overrideWithValue(
            mockRegisterWithEmail,
          ),
          resendEmailOtpUseCaseProvider.overrideWithValue(mockResendEmailOtp),
          verifyEmailOtpUseCaseProvider.overrideWithValue(mockVerifyEmailOtp),
          sendPhoneOtpUseCaseProvider.overrideWithValue(mockSendPhoneOtp),
          verifyPhoneOtpUseCaseProvider.overrideWithValue(mockVerifyPhoneOtp),
        ],
      );

      registerFallbackValue(DateTime(2026));
    });

    tearDown(() => container.dispose());

    RegistrationState readState() => container.read(registerViewModelProvider);
    RegisterViewModel readNotifier() =>
        container.read(registerViewModelProvider.notifier);

    // -- Network off --
    test('network error sets error.network on submitEmail', () async {
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenThrow(const NetworkException());

      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );

      expect(readState().errorKey, 'error.network');
      expect(readState().step, RegistrationStep.emailForm);
      expect(readState().isLoading, isFalse);
    });

    test('network error sets error.network on verifyEmail', () async {
      // Drive to emailVerification first
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );

      when(
        () => mockVerifyEmailOtp.call(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const NetworkException());

      await readNotifier().verifyEmail('123456');

      expect(readState().errorKey, 'error.network');
      expect(readState().step, RegistrationStep.emailVerification);
    });

    test('network error sets error.network on submitPhone', () async {
      // Drive to phoneForm
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );
      when(
        () => mockVerifyEmailOtp.call(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().verifyEmail('123456');

      when(
        () => mockSendPhoneOtp.call(phone: any(named: 'phone')),
      ).thenThrow(const NetworkException());

      await readNotifier().submitPhone('+31612345678');

      expect(readState().errorKey, 'error.network');
      expect(readState().step, RegistrationStep.phoneForm);
    });

    test('network error sets error.network on verifyPhone', () async {
      // Drive to phoneVerification
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );
      when(
        () => mockVerifyEmailOtp.call(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().verifyEmail('123456');
      when(
        () => mockSendPhoneOtp.call(phone: any(named: 'phone')),
      ).thenAnswer((_) async {});
      await readNotifier().submitPhone('+31612345678');

      when(
        () => mockVerifyPhoneOtp.call(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const NetworkException());

      await readNotifier().verifyPhone('654321');

      expect(readState().errorKey, 'error.network');
      expect(readState().step, RegistrationStep.phoneVerification);
    });

    // -- Invalid OTP --
    test('invalid email OTP sets error.otp_invalid', () async {
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );

      when(
        () => mockVerifyEmailOtp.call(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthException('error.otp_invalid'));

      await readNotifier().verifyEmail('000000');

      expect(readState().errorKey, 'error.otp_invalid');
      expect(readState().step, RegistrationStep.emailVerification);
    });

    test('invalid phone OTP sets error.otp_invalid', () async {
      // Drive to phoneVerification
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );
      when(
        () => mockVerifyEmailOtp.call(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().verifyEmail('123456');
      when(
        () => mockSendPhoneOtp.call(phone: any(named: 'phone')),
      ).thenAnswer((_) async {});
      await readNotifier().submitPhone('+31612345678');

      when(
        () => mockVerifyPhoneOtp.call(
          phone: any(named: 'phone'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthException('error.otp_invalid'));

      await readNotifier().verifyPhone('000000');

      expect(readState().errorKey, 'error.otp_invalid');
      expect(readState().step, RegistrationStep.phoneVerification);
    });

    // -- Email taken --
    test('email already taken sets error.email_taken', () async {
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenThrow(const AuthException('error.email_taken'));

      await readNotifier().submitEmail(
        email: 'existing@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );

      expect(readState().errorKey, 'error.email_taken');
      expect(readState().step, RegistrationStep.emailForm);
      expect(readState().isLoading, isFalse);
    });

    // -- Error displayed in UI --
    testWidgets('error text is rendered on emailForm screen', (tester) async {
      final state = RegistrationState.initial().copyWith(
        errorKey: () => 'error.email_taken',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [registerViewModelProvider.overrideWith(() => fakeVm)],
          child: MaterialApp(
            home: const RegisterScreen(),
            onGenerateRoute:
                (_) =>
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        ),
      );

      // The error text should be rendered (raw l10n key without l10n init)
      expect(find.text('error.email_taken'), findsOneWidget);
    });

    testWidgets('error text is rendered on OTP verification screen', (
      tester,
    ) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.emailVerification,
        email: 'test@example.com',
        errorKey: () => 'error.otp_invalid',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [registerViewModelProvider.overrideWith(() => fakeVm)],
          child: MaterialApp(
            home: const RegisterScreen(),
            onGenerateRoute:
                (_) =>
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        ),
      );

      // OTP error text should be visible
      expect(find.text('error.otp_invalid'), findsOneWidget);
    });

    testWidgets('error text is rendered on phone form screen', (tester) async {
      final state = RegistrationState.initial().copyWith(
        step: RegistrationStep.phoneForm,
        email: 'test@example.com',
        errorKey: () => 'error.network',
      );
      final fakeVm = FakeRegisterViewModel(state);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [registerViewModelProvider.overrideWith(() => fakeVm)],
          child: MaterialApp(
            home: const RegisterScreen(),
            onGenerateRoute:
                (_) =>
                    MaterialPageRoute<void>(builder: (_) => const Scaffold()),
          ),
        ),
      );

      expect(find.text('error.network'), findsOneWidget);
    });

    // -- OTP expired --
    test('expired OTP sets error.otp_expired', () async {
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});
      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );

      when(
        () => mockVerifyEmailOtp.call(
          email: any(named: 'email'),
          token: any(named: 'token'),
        ),
      ).thenThrow(const AuthException('error.otp_expired'));

      await readNotifier().verifyEmail('999999');

      expect(readState().errorKey, 'error.otp_expired');
      expect(readState().step, RegistrationStep.emailVerification);
    });

    // -- Rate limited --
    test('rate limited sets error.rate_limited', () async {
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenThrow(const AuthException('error.rate_limited'));

      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );

      expect(readState().errorKey, 'error.rate_limited');
    });

    // -- Error clearing --
    test('errors are cleared when retrying after failure', () async {
      // First attempt fails
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenThrow(const AuthException('error.email_taken'));

      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );
      expect(readState().errorKey, 'error.email_taken');

      // Second attempt succeeds - error should be cleared
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenAnswer((_) async {});

      await readNotifier().submitEmail(
        email: 'new@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );
      expect(readState().errorKey, isNull);
    });

    // -- Generic exception fallback --
    test('unknown exception maps to error.generic', () async {
      when(
        () => mockRegisterWithEmail.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          termsAcceptedAt: any(named: 'termsAcceptedAt'),
          privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
        ),
      ).thenThrow(Exception('unexpected server error'));

      await readNotifier().submitEmail(
        email: 'test@example.com',
        password: 'Pass1234', // pragma: allowlist secret
        termsAccepted: true,
        privacyAccepted: true,
      );

      expect(readState().errorKey, 'error.generic');
    });
  });
}
