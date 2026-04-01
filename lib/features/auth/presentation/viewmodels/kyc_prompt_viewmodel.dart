import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/features/auth/domain/usecases/check_kyc_required_usecase.dart';
import 'package:deelmarkt/features/auth/domain/usecases/initiate_idin_verification_usecase.dart';
import 'package:deelmarkt/features/auth/presentation/viewmodels/auth_providers.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// State for the KYC prompt flow.
class KycPromptState {
  const KycPromptState({
    this.promptType = KycPromptType.none,
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
  });

  final KycPromptType promptType;
  final bool isLoading;
  final bool isSuccess;
  final String? error;

  KycPromptState copyWith({
    KycPromptType? promptType,
    bool? isLoading,
    bool? isSuccess,
    String? error,
  }) {
    return KycPromptState(
      promptType: promptType ?? this.promptType,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error,
    );
  }
}

/// ViewModel for KYC prompt — manages prompt type determination and iDIN flow.
class KycPromptNotifier extends StateNotifier<KycPromptState> {
  KycPromptNotifier({
    required CheckKycRequiredUseCase checkKycRequired,
    required InitiateIdinVerificationUseCase initiateIdin,
  }) : _checkKycRequired = checkKycRequired,
       _initiateIdin = initiateIdin,
       super(const KycPromptState());

  final CheckKycRequiredUseCase _checkKycRequired;
  final InitiateIdinVerificationUseCase _initiateIdin;

  /// Check what KYC prompt (if any) to show.
  void checkRequired({
    required KycLevel kycLevel,
    int? transactionAmountCents,
  }) {
    final promptType = _checkKycRequired(
      kycLevel: kycLevel,
      transactionAmountCents: transactionAmountCents,
    );
    state = KycPromptState(promptType: promptType);
  }

  /// Initiate iDIN verification flow.
  Future<void> initiateIdin() async {
    state = state.copyWith(isLoading: true);
    try {
      await _initiateIdin();
      state = state.copyWith(isLoading: false, isSuccess: true);
    } on Exception catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Dismiss the prompt (user tapped "Later").
  void dismiss() {
    state = const KycPromptState();
  }
}

/// Provider for [CheckKycRequiredUseCase].
final checkKycRequiredProvider = Provider<CheckKycRequiredUseCase>(
  (ref) => const CheckKycRequiredUseCase(),
);

/// Provider for [InitiateIdinVerificationUseCase].
final initiateIdinProvider = Provider<InitiateIdinVerificationUseCase>(
  (ref) => InitiateIdinVerificationUseCase(ref.watch(authRepositoryProvider)),
);

/// Provider for [KycPromptNotifier].
final kycPromptProvider =
    StateNotifierProvider<KycPromptNotifier, KycPromptState>(
      (ref) => KycPromptNotifier(
        checkKycRequired: ref.watch(checkKycRequiredProvider),
        initiateIdin: ref.watch(initiateIdinProvider),
      ),
    );
