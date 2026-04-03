import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/auth/data/repositories/mock_auth_repository.dart';
import 'package:deelmarkt/features/auth/domain/usecases/initiate_idin_verification_usecase.dart';

void main() {
  group('InitiateIdinVerificationUseCase', () {
    test('returns redirect URL from repository', () async {
      final repository = MockAuthRepository();
      final useCase = InitiateIdinVerificationUseCase(repository);

      final url = await useCase();
      expect(url, isNotEmpty);
      expect(url, contains('idin'));
    });
  });
}
