import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';
import 'package:deelmarkt/features/auth/presentation/view_models/login_state.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';

export 'login_state.dart' show LoginState, kMinPasswordLength;

part 'login_view_model.g.dart';

/// Email format validation regex.
final RegExp _emailRegex = RegExp(
  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
);

@riverpod
class LoginViewModel extends _$LoginViewModel {
  @override
  LoginState build() => const LoginState();

  void setEmail(String value) {
    state = state.copyWith(
      email: value,
      emailError: () => null,
      lastResult: () => null,
    );
  }

  void setPassword(String value) {
    state = state.copyWith(
      password: value,
      passwordError: () => null,
      lastResult: () => null,
    );
  }

  void togglePasswordVisibility() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> submitLogin() async {
    if (state.isLoading) return;

    // Validate locally — presentation concern
    final emailTrimmed = state.email.trim();
    if (emailTrimmed.isEmpty) {
      state = state.copyWith(emailError: () => 'validation.email_required');
      return;
    }
    if (!_emailRegex.hasMatch(emailTrimmed)) {
      state = state.copyWith(emailError: () => 'validation.email_invalid');
      return;
    }
    if (state.password.isEmpty) {
      state = state.copyWith(
        passwordError: () => 'validation.password_required',
      );
      return;
    }
    if (state.password.length < kMinPasswordLength) {
      state = state.copyWith(
        passwordError: () => 'validation.password_too_short',
      );
      return;
    }

    state = state.copyWith(
      isLoading: true,
      lastResult: () => null,
      emailError: () => null,
      passwordError: () => null,
    );

    final useCase = ref.read(loginWithEmailUseCaseProvider);
    final result = await useCase(email: emailTrimmed, password: state.password);

    state = state.copyWith(
      isLoading: false,
      password: '',
      lastResult: () => result,
      passwordError:
          () =>
              result is AuthFailureInvalidCredentials
                  ? 'auth.invalidCredentials'
                  : null,
    );
  }

  Future<void> loginWithBiometric({required String localizedReason}) async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, lastResult: () => null);

    final useCase = ref.read(loginWithBiometricUseCaseProvider);
    final result = await useCase(localizedReason: localizedReason);

    state = state.copyWith(isLoading: false, lastResult: () => result);
  }

  Future<void> init() async {
    final repo = ref.read(authRepositoryProvider);
    final available = await repo.isBiometricAvailable;
    final method = await repo.availableBiometricMethod;
    state = state.copyWith(
      biometricAvailable: available,
      biometricMethod: () => method,
    );
  }
}
