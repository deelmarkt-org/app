import 'package:deelmarkt/features/admin/domain/entities/admin_stats_entity.dart';
import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';

/// Retrieves aggregated admin dashboard statistics.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class GetAdminStatsUseCase {
  const GetAdminStatsUseCase(this._repository);

  final AdminRepository _repository;

  /// Returns the current admin stats snapshot.
  Future<AdminStatsEntity> call() => _repository.getStats();
}
