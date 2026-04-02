import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/domain/usecases/check_kyc_required_usecase.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

void main() {
  const useCase = CheckKycRequiredUseCase();

  group('CheckKycRequiredUseCase', () {
    test('level0 returns banner', () {
      expect(useCase(kycLevel: KycLevel.level0), KycPromptType.banner);
    });

    test('level1 without transaction returns none', () {
      expect(useCase(kycLevel: KycLevel.level1), KycPromptType.none);
    });

    test('level1 with amount < 500€ returns none', () {
      expect(
        useCase(kycLevel: KycLevel.level1, transactionAmountCents: 49999),
        KycPromptType.none,
      );
    });

    test('level1 with amount >= 500€ returns bottomSheet', () {
      expect(
        useCase(kycLevel: KycLevel.level1, transactionAmountCents: 50000),
        KycPromptType.bottomSheet,
      );
    });

    test('level1 with amount > 500€ returns bottomSheet', () {
      expect(
        useCase(kycLevel: KycLevel.level1, transactionAmountCents: 100000),
        KycPromptType.bottomSheet,
      );
    });

    test('level2 returns none', () {
      expect(useCase(kycLevel: KycLevel.level2), KycPromptType.none);
    });

    test('level3 returns none', () {
      expect(useCase(kycLevel: KycLevel.level3), KycPromptType.none);
    });

    test('level4 returns none', () {
      expect(useCase(kycLevel: KycLevel.level4), KycPromptType.none);
    });

    test('level2+ with high amount still returns none', () {
      expect(
        useCase(kycLevel: KycLevel.level2, transactionAmountCents: 100000),
        KycPromptType.none,
      );
    });
  });
}
