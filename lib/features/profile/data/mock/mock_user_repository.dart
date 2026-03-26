import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';

/// Mock user repository — returns static data for Phase 1-2 widget development.
class MockUserRepository implements UserRepository {
  @override
  Future<UserEntity?> getById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    try {
      return _mockUsers.firstWhere((u) => u.id == id);
    } on StateError {
      return null;
    }
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    await Future<void>.delayed(const Duration(milliseconds: 200));
    return _mockUsers.first;
  }

  @override
  Future<UserEntity> updateProfile({
    String? displayName,
    String? avatarUrl,
    String? location,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return _mockUsers.first;
  }
}

final _mockUsers = [
  UserEntity(
    id: 'user-001',
    displayName: 'Jan de Vries',
    kycLevel: KycLevel.level1,
    avatarUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
    location: 'Amsterdam',
    badges: [
      BadgeType.emailVerified,
      BadgeType.phoneVerified,
      BadgeType.fastResponder,
    ],
    averageRating: 4.7,
    reviewCount: 23,
    responseTimeMinutes: 15,
    createdAt: DateTime(2025, 6, 1),
  ),
  UserEntity(
    id: 'user-002',
    displayName: 'Maria Jansen',
    kycLevel: KycLevel.level2,
    location: 'Rotterdam',
    badges: [
      BadgeType.emailVerified,
      BadgeType.phoneVerified,
      BadgeType.idVerified,
      BadgeType.trustedSeller,
    ],
    averageRating: 4.9,
    reviewCount: 87,
    responseTimeMinutes: 8,
    createdAt: DateTime(2025, 3, 15),
  ),
];
