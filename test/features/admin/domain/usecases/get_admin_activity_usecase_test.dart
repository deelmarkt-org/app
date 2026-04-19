import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/data/mock/mock_admin_repository.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_activity_usecase.dart';

void main() {
  group('GetAdminActivityUseCase', () {
    late GetAdminActivityUseCase useCase;

    setUp(() {
      useCase = GetAdminActivityUseCase(MockAdminRepository());
    });

    test('call() returns list of ActivityItemEntity', () async {
      final items = await useCase.call();

      expect(items, isA<List<ActivityItemEntity>>());
    });

    test('call() respects the limit parameter', () async {
      final items = await useCase.call(limit: 3);

      expect(items.length, lessThanOrEqualTo(3));
    });

    test('call() defaults to limit 10', () async {
      final items = await useCase.call();

      expect(items.length, lessThanOrEqualTo(10));
    });
  });
}
