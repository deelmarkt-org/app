import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// Result of KYC requirement check.
enum KycPromptType {
  /// No prompt needed — user meets requirements.
  none,

  /// Inline banner prompting Level 0 → Level 1 upgrade (phone verification).
  banner,

  /// Modal bottom sheet for Level 1 → Level 2 upgrade (iDIN for >=€500).
  bottomSheet,
}

/// Pure-logic use case: maps KYC level + transaction amount to prompt type.
///
/// No repository needed — entirely deterministic.
class CheckKycRequiredUseCase {
  const CheckKycRequiredUseCase();

  /// Transaction amount threshold (in cents) requiring Level 2 verification.
  static const int _level2ThresholdCents = 50000; // €500

  KycPromptType call({
    required KycLevel kycLevel,
    int? transactionAmountCents,
  }) {
    // Level 2+ needs no prompt
    if (kycLevel.index >= KycLevel.level2.index) {
      return KycPromptType.none;
    }

    // Level 1 with high-value transaction → bottom sheet for iDIN
    if (kycLevel == KycLevel.level1 &&
        transactionAmountCents != null &&
        transactionAmountCents >= _level2ThresholdCents) {
      return KycPromptType.bottomSheet;
    }

    // Level 0 → banner prompting phone verification
    if (kycLevel == KycLevel.level0) {
      return KycPromptType.banner;
    }

    return KycPromptType.none;
  }
}
