import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/auth/domain/entities/auth_result.dart';

/// Minimum password length — must match server-side validation and
/// the registration screen constant.
const int kMinPasswordLength = 8;

/// Grouped field-validation errors for the login form.
///
/// Extracted from [LoginState] to keep the constructor under 7 parameters
/// (SonarCloud MAJOR rule).
class LoginFieldErrors extends Equatable {
  const LoginFieldErrors({this.emailError, this.passwordError});

  final String? emailError;
  final String? passwordError;

  LoginFieldErrors copyWith({
    String? Function()? emailError,
    String? Function()? passwordError,
  }) {
    return LoginFieldErrors(
      emailError: emailError != null ? emailError() : this.emailError,
      passwordError:
          passwordError != null ? passwordError() : this.passwordError,
    );
  }

  @override
  List<Object?> get props => [emailError, passwordError];
}

/// Immutable login form state — drives the UI via `ref.watch`.
class LoginState extends Equatable {
  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.obscurePassword = true,
    this.lastResult,
    this.biometricAvailable = false,
    this.biometricMethod,
    this.fieldErrors = const LoginFieldErrors(),
  });

  final String email;
  final String password;
  final bool isLoading;
  final bool obscurePassword;
  final AuthResult? lastResult;
  final bool biometricAvailable;
  final BiometricMethod? biometricMethod;
  final LoginFieldErrors fieldErrors;

  /// Convenience accessors for field errors.
  String? get emailError => fieldErrors.emailError;
  String? get passwordError => fieldErrors.passwordError;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    bool? obscurePassword,
    AuthResult? Function()? lastResult,
    bool? biometricAvailable,
    BiometricMethod? Function()? biometricMethod,
    LoginFieldErrors? fieldErrors,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      lastResult: lastResult != null ? lastResult() : this.lastResult,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricMethod:
          biometricMethod != null ? biometricMethod() : this.biometricMethod,
      fieldErrors: fieldErrors ?? this.fieldErrors,
    );
  }

  @override
  List<Object?> get props => [
    email,
    password,
    isLoading,
    obscurePassword,
    lastResult,
    biometricAvailable,
    biometricMethod,
    fieldErrors,
  ];
}
