import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/admin/data/mock/mock_admin_repository.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_stats_usecase.dart';

void main() {
  group('GetAdminStatsUseCase', () {
    late GetAdminStatsUseCase useCase;

    setUp(() {
      useCase = GetAdminStatsUseCase(MockAdminRepository());
    });

    test('call() returns AdminStatsEntity from repository', () async {
      final stats = await useCase.call();

      expect(stats.openDisputes, equals(12));
      expect(stats.dsaNoticesWithin24h, equals(3));
      expect(stats.activeListings, equals(156));
      expect(stats.escrowAmountCents, equals(1245000));
    });
  });
}
