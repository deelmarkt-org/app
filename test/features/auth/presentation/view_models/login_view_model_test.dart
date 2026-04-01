import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/domain/repositories/auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/login_with_biometric_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/login_with_email_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/view_models/login_view_model.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLoginWithEmailUseCase extends Mock implements LoginWithEmailUseCase {}

class MockLoginWithBiometricUseCase extends Mock
    implements LoginWithBiometricUseCase {}

void main() {
  late MockAuthRepository mockRepo;
  late MockLoginWithEmailUseCase mockEmailUseCase;
  late MockLoginWithBiometricUseCase mockBioUseCase;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockAuthRepository();
    mockEmailUseCase = MockLoginWithEmailUseCase();
    mockBioUseCase = MockLoginWithBiometricUseCase();

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        loginWithEmailUseCaseProvider.overrideWithValue(mockEmailUseCase),
        loginWithBiometricUseCaseProvider.overrideWithValue(mockBioUseCase),
      ],
    );

    // Stub default for biometric check in init
    when(() => mockRepo.isBiometricAvailable).thenAnswer((_) async => false);
    when(() => mockRepo.availableBiometricMethod).thenAnswer((_) async => null);
  });

  tearDown(() => container.dispose());

  LoginViewModel readNotifier() =>
      container.read(loginViewModelProvider.notifier);
  LoginState readState() => container.read(loginViewModelProvider);

  group('LoginViewModel — initial state', () {
    test('has correct defaults', () {
      final state = readState();
      expect(state.email, '');
      expect(state.password, '');
      expect(state.isLoading, false);
      expect(state.obscurePassword, true);
      expect(state.lastResult, isNull);
      expect(state.biometricAvailable, false);
      expect(state.biometricMethod, isNull);
      expect(state.emailError, isNull);
      expect(state.passwordError, isNull);
    });
  });

  group('LoginViewModel — setEmail', () {
    test('updates email', () {
      readNotifier().setEmail('test@test.com');
      expect(readState().email, 'test@test.com');
    });

    test('clears emailError', () {
      readNotifier().setEmail('');
      // Force an error
      readNotifier().submitLogin();
      expect(readState().emailError, isNotNull);

      readNotifier().setEmail('x');
      expect(readState().emailError, isNull);
    });

    test('clears lastResult', () async {
      when(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const AuthFailureInvalidCredentials());

      readNotifier().setEmail('a@b.com');
      readNotifier().setPassword('12345678');
      await readNotifier().submitLogin();
      expect(readState().lastResult, isNotNull);

      readNotifier().setEmail('new@email.com');
      expect(readState().lastResult, isNull);
    });
  });

  group('LoginViewModel — setPassword', () {
    test('updates password and clears passwordError', () {
      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('short');
      readNotifier().submitLogin();
      expect(readState().passwordError, isNotNull);

      readNotifier().setPassword('newpassword');
      expect(readState().passwordError, isNull);
    });
  });

  group('LoginViewModel — togglePasswordVisibility', () {
    test('flips obscurePassword', () {
      expect(readState().obscurePassword, true);
      readNotifier().togglePasswordVisibility();
      expect(readState().obscurePassword, false);
      readNotifier().togglePasswordVisibility();
      expect(readState().obscurePassword, true);
    });
  });

  group('LoginViewModel — submitLogin validation', () {
    test('empty email sets emailError', () async {
      readNotifier().setEmail('');
      await readNotifier().submitLogin();

      expect(readState().emailError, 'validation.email_required');
      verifyNever(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    test('invalid email without @ sets emailError', () async {
      readNotifier().setEmail('noatsign');
      readNotifier().setPassword('12345678');
      await readNotifier().submitLogin();

      expect(readState().emailError, 'validation.email_invalid');
    });

    test('email like a@b. (no TLD) sets emailError', () async {
      readNotifier().setEmail('a@b.');
      readNotifier().setPassword('12345678');
      await readNotifier().submitLogin();

      expect(readState().emailError, 'validation.email_invalid');
    });

    test('email like user@domain.c (1-char TLD) sets emailError', () async {
      readNotifier().setEmail('user@domain.c');
      readNotifier().setPassword('12345678');
      await readNotifier().submitLogin();

      expect(readState().emailError, 'validation.email_invalid');
    });

    test('valid email passes validation', () async {
      when(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const AuthSuccess(userId: '1'));

      readNotifier().setEmail('user@example.com');
      readNotifier().setPassword('12345678');
      await readNotifier().submitLogin();

      expect(readState().emailError, isNull);
    });

    test('empty password sets passwordError', () async {
      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('');
      await readNotifier().submitLogin();

      expect(readState().passwordError, 'validation.password_required');
    });

    test('short password sets passwordError', () async {
      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('1234567');
      await readNotifier().submitLogin();

      expect(readState().passwordError, 'validation.password_too_short');
    });
  });

  group('LoginViewModel — submitLogin success', () {
    test('sets loading then result', () async {
      when(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const AuthSuccess(userId: '123'));

      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('12345678');

      await readNotifier().submitLogin();

      expect(readState().isLoading, false);
      expect(readState().lastResult, isA<AuthSuccess>());
    });

    test('C-1: password cleared from state after successful login', () async {
      when(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const AuthSuccess(userId: '123'));

      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('SecureP@ss1');
      await readNotifier().submitLogin();

      expect(readState().password, isEmpty);
    });

    test('C-1: password cleared from state after failed login', () async {
      when(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const AuthFailureInvalidCredentials());

      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('WrongPassword');
      await readNotifier().submitLogin();

      expect(readState().password, isEmpty);
    });
  });

  group('LoginViewModel — submitLogin failures', () {
    test('invalid credentials sets passwordError', () async {
      when(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const AuthFailureInvalidCredentials());

      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('12345678');
      await readNotifier().submitLogin();

      expect(readState().passwordError, 'auth.invalidCredentials');
      expect(readState().lastResult, isA<AuthFailureInvalidCredentials>());
    });

    test('double-tap prevention — no-op when loading', () async {
      when(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return const AuthSuccess(userId: '1');
      });

      readNotifier().setEmail('test@test.com');
      readNotifier().setPassword('12345678');

      // Fire twice without awaiting first
      final f1 = readNotifier().submitLogin();
      final f2 = readNotifier().submitLogin(); // should be no-op

      await Future.wait([f1, f2]);

      verify(
        () => mockEmailUseCase(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).called(1);
    });
  });

  group('LoginViewModel — loginWithBiometric', () {
    test('sets loading then result', () async {
      when(
        () => mockBioUseCase(localizedReason: any(named: 'localizedReason')),
      ).thenAnswer((_) async => const AuthSuccess(userId: '123'));

      await readNotifier().loginWithBiometric(localizedReason: 'test');

      expect(readState().isLoading, false);
      expect(readState().lastResult, isA<AuthSuccess>());
    });

    test('double-tap prevention — no-op when loading', () async {
      when(
        () => mockBioUseCase(localizedReason: any(named: 'localizedReason')),
      ).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        return const AuthSuccess(userId: '1');
      });

      final f1 = readNotifier().loginWithBiometric(localizedReason: 'test');
      final f2 = readNotifier().loginWithBiometric(localizedReason: 'test');

      await Future.wait([f1, f2]);

      verify(
        () => mockBioUseCase(localizedReason: any(named: 'localizedReason')),
      ).called(1);
    });
  });

  group('LoginViewModel — init', () {
    test('queries biometric availability', () async {
      when(() => mockRepo.isBiometricAvailable).thenAnswer((_) async => true);
      when(
        () => mockRepo.availableBiometricMethod,
      ).thenAnswer((_) async => BiometricMethod.face);

      await readNotifier().init();

      expect(readState().biometricAvailable, true);
      expect(readState().biometricMethod, BiometricMethod.face);
    });
  });
}
