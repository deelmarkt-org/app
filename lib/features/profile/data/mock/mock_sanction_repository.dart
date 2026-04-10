import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/sanction_repository.dart';

/// Mock implementation of [SanctionRepository] for development and testing.
///
/// Returns no active sanction by default so the app is fully accessible in
/// dev/mock mode. Override [activeForUserId] in tests to simulate a suspension.
class MockSanctionRepository implements SanctionRepository {
  MockSanctionRepository({this.activeForUserId});

  /// If set, [getActiveSanction] returns a mock suspension for this user ID.
  final String? activeForUserId;

  @override
  Future<SanctionEntity?> getActiveSanction(String userId) async {
    if (activeForUserId != null && userId == activeForUserId) {
      return SanctionEntity(
        id: 'mock-sanction-001',
        userId: userId,
        type: SanctionType.suspension,
        reason: 'Mock suspension — dev/test only',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        expiresAt: DateTime.now().add(const Duration(days: 6)),
      );
    }
    return null;
  }

  @override
  Future<List<SanctionEntity>> getAll(String userId) async => [];

  @override
  Future<SanctionEntity> submitAppeal(
    String sanctionId,
    String appealBody,
  ) async {
    return SanctionEntity(
      id: sanctionId,
      userId: activeForUserId ?? 'mock-user',
      type: SanctionType.suspension,
      reason: 'Mock suspension — dev/test only',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      expiresAt: DateTime.now().add(const Duration(days: 6)),
      appealedAt: DateTime.now(),
      appealBody: appealBody,
    );
  }
}
