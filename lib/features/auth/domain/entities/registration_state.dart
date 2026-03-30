import 'package:equatable/equatable.dart';

/// Steps in the multi-screen registration flow.
enum RegistrationStep {
  emailForm,
  emailVerification,
  phoneForm,
  phoneVerification,
  complete,
}

/// Immutable state for the registration flow.
///
/// Tracks which step the user is on, entered data, loading/error states,
/// and GDPR consent flags. Pure Dart — no Flutter imports.
class RegistrationState extends Equatable {
  const RegistrationState._({
    required this.step,
    required this.isLoading,
    required this.termsAccepted,
    required this.privacyAccepted,
    this.email,
    this.phone,
    this.errorKey,
  });

  factory RegistrationState.initial() => const RegistrationState._(
    step: RegistrationStep.emailForm,
    isLoading: false,
    termsAccepted: false,
    privacyAccepted: false,
  );

  final RegistrationStep step;
  final String? email;
  final String? phone;
  final bool isLoading;
  final String? errorKey;
  final bool termsAccepted;
  final bool privacyAccepted;

  RegistrationState copyWith({
    RegistrationStep? step,
    String? email,
    String? phone,
    bool? isLoading,
    String? Function()? errorKey,
    bool? termsAccepted,
    bool? privacyAccepted,
  }) {
    return RegistrationState._(
      step: step ?? this.step,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isLoading: isLoading ?? this.isLoading,
      errorKey: errorKey != null ? errorKey() : this.errorKey,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      privacyAccepted: privacyAccepted ?? this.privacyAccepted,
    );
  }

  @override
  List<Object?> get props => [
    step,
    email,
    phone,
    isLoading,
    errorKey,
    termsAccepted,
    privacyAccepted,
  ];
}
