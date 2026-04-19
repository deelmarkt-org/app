import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/auth/domain/entities/registration_state.dart';
import 'package:deelmarkt/features/auth/domain/usecases/register_with_email_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/resend_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/send_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_email_otp_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/verify_phone_otp_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/screens/register_screen.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
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
