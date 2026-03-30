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
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/register_viewmodel.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockRegisterWithEmailUseCase extends Mock
    implements RegisterWithEmailUseCase {}

class MockResendEmailOtpUseCase extends Mock implements ResendEmailOtpUseCase {}

class MockVerifyEmailOtpUseCase extends Mock implements VerifyEmailOtpUseCase {}

class MockSendPhoneOtpUseCase extends Mock implements SendPhoneOtpUseCase {}

class MockVerifyPhoneOtpUseCase extends Mock implements VerifyPhoneOtpUseCase {}

void main() {
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

  // -----------------------------------------------------------------------
  // Helper to read the current state from the container.
  // -----------------------------------------------------------------------
  RegistrationState readState() => container.read(registerViewModelProvider);

  RegisterViewModel readNotifier() =>
      container.read(registerViewModelProvider.notifier);

  // -----------------------------------------------------------------------
  // Stub helpers
  // -----------------------------------------------------------------------
  void stubRegisterSuccess() {
    when(
      () => mockRegisterWithEmail.call(
        email: any(named: 'email'),
        password: any(named: 'password'),
        termsAcceptedAt: any(named: 'termsAcceptedAt'),
        privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
      ),
    ).thenAnswer((_) async {});
  }

  void stubRegisterThrows(Exception exception) {
    when(
      () => mockRegisterWithEmail.call(
        email: any(named: 'email'),
        password: any(named: 'password'),
        termsAcceptedAt: any(named: 'termsAcceptedAt'),
        privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
      ),
    ).thenThrow(exception);
  }

  void stubResendEmailOtpSuccess() {
    when(
      () => mockResendEmailOtp.call(email: any(named: 'email')),
    ).thenAnswer((_) async {});
  }

  void stubResendEmailOtpThrows(Exception exception) {
    when(
      () => mockResendEmailOtp.call(email: any(named: 'email')),
    ).thenThrow(exception);
  }

  void stubVerifyEmailSuccess() {
    when(
      () => mockVerifyEmailOtp.call(
        email: any(named: 'email'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
  }

  void stubVerifyEmailThrows(Exception exception) {
    when(
      () => mockVerifyEmailOtp.call(
        email: any(named: 'email'),
        token: any(named: 'token'),
      ),
    ).thenThrow(exception);
  }

  void stubSendPhoneOtpSuccess() {
    when(
      () => mockSendPhoneOtp.call(phone: any(named: 'phone')),
    ).thenAnswer((_) async {});
  }

  void stubSendPhoneOtpThrows(Exception exception) {
    when(
      () => mockSendPhoneOtp.call(phone: any(named: 'phone')),
    ).thenThrow(exception);
  }

  void stubVerifyPhoneSuccess() {
    when(
      () => mockVerifyPhoneOtp.call(
        phone: any(named: 'phone'),
        token: any(named: 'token'),
      ),
    ).thenAnswer((_) async {});
  }

  void stubVerifyPhoneThrows(Exception exception) {
    when(
      () => mockVerifyPhoneOtp.call(
        phone: any(named: 'phone'),
        token: any(named: 'token'),
      ),
    ).thenThrow(exception);
  }

  /// Drives the viewmodel to the emailVerification step.
  Future<void> driveToEmailVerification() async {
    stubRegisterSuccess();
    await readNotifier().submitEmail(
      email: 'test@example.com',
      password: 'Pass1234',
      termsAccepted: true,
      privacyAccepted: true,
    );
  }

  /// Drives the viewmodel to the phoneForm step.
  Future<void> driveToPhoneForm() async {
    await driveToEmailVerification();
    stubVerifyEmailSuccess();
    await readNotifier().verifyEmail('123456');
  }

  /// Drives the viewmodel to the phoneVerification step.
  Future<void> driveToPhoneVerification() async {
    await driveToPhoneForm();
    stubSendPhoneOtpSuccess();
    await readNotifier().submitPhone('+31612345678');
  }

  // -----------------------------------------------------------------------
  // Tests
  // -----------------------------------------------------------------------

  group('RegisterViewModel', () {
    group('initial state', () {
      test('starts on emailForm with no loading and no error', () {
        final state = readState();

        expect(state.step, RegistrationStep.emailForm);
        expect(state.isLoading, isFalse);
        expect(state.errorKey, isNull);
        expect(state.email, isNull);
        expect(state.phone, isNull);
        expect(state.termsAccepted, isFalse);
        expect(state.privacyAccepted, isFalse);
      });
    });

    // -----------------------------------------------------------------
    // submitEmail
    // -----------------------------------------------------------------
    group('submitEmail', () {
      test(
        'success transitions to emailVerification and stores email',
        () async {
          stubRegisterSuccess();

          await readNotifier().submitEmail(
            email: 'test@example.com',
            password: 'Pass1234',
            termsAccepted: true,
            privacyAccepted: true,
          );

          final state = readState();
          expect(state.step, RegistrationStep.emailVerification);
          expect(state.email, 'test@example.com');
          expect(state.isLoading, isFalse);
          expect(state.errorKey, isNull);
          expect(state.termsAccepted, isTrue);
          expect(state.privacyAccepted, isTrue);
        },
      );

      test('success calls use case with correct parameters', () async {
        stubRegisterSuccess();

        await readNotifier().submitEmail(
          email: 'test@example.com',
          password: 'Pass1234',
          termsAccepted: true,
          privacyAccepted: true,
        );

        verify(
          () => mockRegisterWithEmail.call(
            email: 'test@example.com',
            password: 'Pass1234',
            termsAcceptedAt: any(named: 'termsAcceptedAt'),
            privacyAcceptedAt: any(named: 'privacyAcceptedAt'),
          ),
        ).called(1);
      });

      test('AppException sets errorKey and stays on emailForm', () async {
        stubRegisterThrows(const AuthException('error.email_taken'));

        await readNotifier().submitEmail(
          email: 'taken@example.com',
          password: 'Pass1234',
          termsAccepted: true,
          privacyAccepted: true,
        );

        final state = readState();
        expect(state.step, RegistrationStep.emailForm);
        expect(state.errorKey, 'error.email_taken');
        expect(state.isLoading, isFalse);
      });

      test('generic Exception sets errorKey to error.generic', () async {
        stubRegisterThrows(Exception('unexpected'));

        await readNotifier().submitEmail(
          email: 'test@example.com',
          password: 'Pass1234',
          termsAccepted: true,
          privacyAccepted: true,
        );

        final state = readState();
        expect(state.step, RegistrationStep.emailForm);
        expect(state.errorKey, 'error.generic');
        expect(state.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------
    // resendEmailOtp
    // -----------------------------------------------------------------
    group('resendEmailOtp', () {
      test('success toggles loading and stays on emailVerification', () async {
        await driveToEmailVerification();
        stubResendEmailOtpSuccess();

        await readNotifier().resendEmailOtp();

        final state = readState();
        expect(state.step, RegistrationStep.emailVerification);
        expect(state.isLoading, isFalse);
        expect(state.errorKey, isNull);
      });

      test('success calls use case with stored email', () async {
        await driveToEmailVerification();
        stubResendEmailOtpSuccess();

        await readNotifier().resendEmailOtp();

        verify(
          () => mockResendEmailOtp.call(email: 'test@example.com'),
        ).called(1);
      });

      test('AppException sets errorKey', () async {
        await driveToEmailVerification();
        stubResendEmailOtpThrows(const AuthException('error.rate_limit'));

        await readNotifier().resendEmailOtp();

        final state = readState();
        expect(state.step, RegistrationStep.emailVerification);
        expect(state.errorKey, 'error.rate_limit');
        expect(state.isLoading, isFalse);
      });

      test('generic Exception sets errorKey to error.generic', () async {
        await driveToEmailVerification();
        stubResendEmailOtpThrows(Exception('network'));

        await readNotifier().resendEmailOtp();

        final state = readState();
        expect(state.errorKey, 'error.generic');
        expect(state.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------
    // verifyEmail
    // -----------------------------------------------------------------
    group('verifyEmail', () {
      test('success transitions to phoneForm', () async {
        await driveToEmailVerification();
        stubVerifyEmailSuccess();

        await readNotifier().verifyEmail('123456');

        final state = readState();
        expect(state.step, RegistrationStep.phoneForm);
        expect(state.isLoading, isFalse);
        expect(state.errorKey, isNull);
      });

      test(
        'success calls use case with stored email and provided otp',
        () async {
          await driveToEmailVerification();
          stubVerifyEmailSuccess();

          await readNotifier().verifyEmail('123456');

          verify(
            () => mockVerifyEmailOtp.call(
              email: 'test@example.com',
              token: '123456',
            ),
          ).called(1);
        },
      );

      test(
        'AppException sets errorKey and stays on emailVerification',
        () async {
          await driveToEmailVerification();
          stubVerifyEmailThrows(const AuthException('error.invalid_otp'));

          await readNotifier().verifyEmail('000000');

          final state = readState();
          expect(state.step, RegistrationStep.emailVerification);
          expect(state.errorKey, 'error.invalid_otp');
          expect(state.isLoading, isFalse);
        },
      );

      test('generic Exception sets errorKey to error.generic', () async {
        await driveToEmailVerification();
        stubVerifyEmailThrows(Exception('timeout'));

        await readNotifier().verifyEmail('123456');

        final state = readState();
        expect(state.errorKey, 'error.generic');
        expect(state.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------
    // submitPhone
    // -----------------------------------------------------------------
    group('submitPhone', () {
      test(
        'success transitions to phoneVerification and stores phone',
        () async {
          await driveToPhoneForm();
          stubSendPhoneOtpSuccess();

          await readNotifier().submitPhone('+31612345678');

          final state = readState();
          expect(state.step, RegistrationStep.phoneVerification);
          expect(state.phone, '+31612345678');
          expect(state.isLoading, isFalse);
          expect(state.errorKey, isNull);
        },
      );

      test('success calls use case with provided phone number', () async {
        await driveToPhoneForm();
        stubSendPhoneOtpSuccess();

        await readNotifier().submitPhone('+31612345678');

        verify(() => mockSendPhoneOtp.call(phone: '+31612345678')).called(1);
      });

      test('AppException sets errorKey and stays on phoneForm', () async {
        await driveToPhoneForm();
        stubSendPhoneOtpThrows(
          const ValidationException('error.invalid_phone'),
        );

        await readNotifier().submitPhone('invalid');

        final state = readState();
        expect(state.step, RegistrationStep.phoneForm);
        expect(state.errorKey, 'error.invalid_phone');
        expect(state.isLoading, isFalse);
      });

      test('generic Exception sets errorKey to error.generic', () async {
        await driveToPhoneForm();
        stubSendPhoneOtpThrows(Exception('sms service down'));

        await readNotifier().submitPhone('+31612345678');

        final state = readState();
        expect(state.errorKey, 'error.generic');
        expect(state.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------
    // verifyPhone
    // -----------------------------------------------------------------
    group('verifyPhone', () {
      test('success transitions to complete', () async {
        await driveToPhoneVerification();
        stubVerifyPhoneSuccess();

        await readNotifier().verifyPhone('654321');

        final state = readState();
        expect(state.step, RegistrationStep.complete);
        expect(state.isLoading, isFalse);
        expect(state.errorKey, isNull);
      });

      test(
        'success calls use case with stored phone and provided otp',
        () async {
          await driveToPhoneVerification();
          stubVerifyPhoneSuccess();

          await readNotifier().verifyPhone('654321');

          verify(
            () =>
                mockVerifyPhoneOtp.call(phone: '+31612345678', token: '654321'),
          ).called(1);
        },
      );

      test(
        'AppException sets errorKey and stays on phoneVerification',
        () async {
          await driveToPhoneVerification();
          stubVerifyPhoneThrows(const AuthException('error.invalid_otp'));

          await readNotifier().verifyPhone('000000');

          final state = readState();
          expect(state.step, RegistrationStep.phoneVerification);
          expect(state.errorKey, 'error.invalid_otp');
          expect(state.isLoading, isFalse);
        },
      );

      test('generic Exception sets errorKey to error.generic', () async {
        await driveToPhoneVerification();
        stubVerifyPhoneThrows(Exception('timeout'));

        await readNotifier().verifyPhone('654321');

        final state = readState();
        expect(state.errorKey, 'error.generic');
        expect(state.isLoading, isFalse);
      });
    });

    // -----------------------------------------------------------------
    // goBack
    // -----------------------------------------------------------------
    group('goBack', () {
      test('from emailVerification returns to emailForm', () async {
        await driveToEmailVerification();

        readNotifier().goBack();

        expect(readState().step, RegistrationStep.emailForm);
        expect(readState().errorKey, isNull);
      });

      test('from phoneForm returns to emailVerification', () async {
        await driveToPhoneForm();

        readNotifier().goBack();

        expect(readState().step, RegistrationStep.emailVerification);
        expect(readState().errorKey, isNull);
      });

      test('from phoneVerification returns to phoneForm', () async {
        await driveToPhoneVerification();

        readNotifier().goBack();

        expect(readState().step, RegistrationStep.phoneForm);
        expect(readState().errorKey, isNull);
      });

      test('from emailForm stays on emailForm (no-op)', () {
        readNotifier().goBack();

        expect(readState().step, RegistrationStep.emailForm);
      });

      test('from complete stays on complete (no-op)', () async {
        await driveToPhoneVerification();
        stubVerifyPhoneSuccess();
        await readNotifier().verifyPhone('654321');

        readNotifier().goBack();

        expect(readState().step, RegistrationStep.complete);
      });

      test('clears errorKey when navigating back', () async {
        await driveToEmailVerification();
        stubVerifyEmailThrows(const AuthException('error.invalid_otp'));
        await readNotifier().verifyEmail('000000');
        expect(readState().errorKey, 'error.invalid_otp');

        readNotifier().goBack();

        expect(readState().errorKey, isNull);
      });
    });

    // -----------------------------------------------------------------
    // Error clearing between actions
    // -----------------------------------------------------------------
    group('error clearing', () {
      test(
        'submitEmail clears previous error before calling use case',
        () async {
          // First call fails
          stubRegisterThrows(const AuthException('error.email_taken'));
          await readNotifier().submitEmail(
            email: 'taken@example.com',
            password: 'Pass1234',
            termsAccepted: true,
            privacyAccepted: true,
          );
          expect(readState().errorKey, 'error.email_taken');

          // Second call succeeds - error should be cleared
          stubRegisterSuccess();
          await readNotifier().submitEmail(
            email: 'new@example.com',
            password: 'Pass1234',
            termsAccepted: true,
            privacyAccepted: true,
          );
          expect(readState().errorKey, isNull);
        },
      );
    });

    // -----------------------------------------------------------------
    // NetworkException (subtype of AppException)
    // -----------------------------------------------------------------
    group('network errors', () {
      test('NetworkException sets its messageKey as errorKey', () async {
        stubRegisterThrows(const NetworkException());

        await readNotifier().submitEmail(
          email: 'test@example.com',
          password: 'Pass1234',
          termsAccepted: true,
          privacyAccepted: true,
        );

        expect(readState().errorKey, 'error.network');
        expect(readState().isLoading, isFalse);
      });
    });
  });
}
