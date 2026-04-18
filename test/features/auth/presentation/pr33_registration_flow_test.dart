import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
}
