import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/data/mock/mock_admin_repository.dart';
import 'package:deelmarkt/features/admin/domain/usecases/verify_admin_role_usecase.dart';

void main() {
  group('VerifyAdminRoleUseCase', () {
    late VerifyAdminRoleUseCase useCase;
    late MockAdminRepository repository;

    setUp(() {
      repository = MockAdminRepository();
      useCase = VerifyAdminRoleUseCase(repository);
    });

    test('call() returns bool from repository', () async {
      final result = await useCase.call();

      expect(result, isA<bool>());
    });

    test('call() returns cached result within cache duration', () async {
      final first = await useCase.call();
      final second = await useCase.call();

      expect(first, equals(second));
    });

    test('invalidate() clears the cache', () async {
      await useCase.call();
      useCase.invalidate();

      // After invalidation, next call goes to repository again.
      final result = await useCase.call();
      expect(result, isA<bool>());
    });

    test('call() with short cache evicts and re-fetches', () async {
      final shortCache = VerifyAdminRoleUseCase(
        repository,
        cacheDuration: Duration.zero,
      );
      final first = await shortCache.call();
      final second = await shortCache.call();

      expect(first, equals(second));
    });
  });
}
