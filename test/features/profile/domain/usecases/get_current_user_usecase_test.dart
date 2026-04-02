import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_user_repository.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/domain/usecases/get_current_user_usecase.dart';

void main() {
  group('GetCurrentUserUseCase', () {
    late MockUserRepository repository;
    late GetCurrentUserUseCase useCase;

    setUp(() {
      repository = MockUserRepository();
      useCase = GetCurrentUserUseCase(repository);
    });

    test('returns user from repository', () async {
      final result = await useCase.call();

      expect(result, isNotNull);
      expect(result, isA<UserEntity>());
      expect(result!.displayName, 'Jan de Vries');
      expect(result.id, 'user-001');
    });

    test('returned user has expected fields', () async {
      final result = await useCase.call();

      expect(result, isNotNull);
      expect(result!.kycLevel, KycLevel.level1);
      expect(result.location, 'Amsterdam');
      expect(result.badges, isNotEmpty);
      expect(result.averageRating, 4.7);
      expect(result.reviewCount, 23);
      expect(result.responseTimeMinutes, 15);
    });
  });
}
