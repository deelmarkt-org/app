import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';

/// Retrieves recent admin activity items for the dashboard feed.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class GetAdminActivityUseCase {
  const GetAdminActivityUseCase(this._repository);

  final AdminRepository _repository;

  /// Returns the [limit] most recent activity items, newest-first.
  Future<List<ActivityItemEntity>> call({int limit = 10}) =>
      _repository.getRecentActivity(limit: limit);
}
