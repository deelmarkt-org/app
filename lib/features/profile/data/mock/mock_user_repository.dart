import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/domain/repositories/user_repository.dart';

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
    final user = _mockUsers.first;
    return user.copyWith(
      displayName: displayName ?? user.displayName,
      avatarUrl: avatarUrl ?? user.avatarUrl,
      location: location ?? user.location,
    );
  }
}

final _mockUsers = [
  UserEntity(
    id: 'user-001',
    displayName: 'Jan de Vries',
    email: 'jan@deelmarkt.nl',
    phone: '+31612345678',
    kycLevel: KycLevel.level1,
    avatarUrl: 'https://res.cloudinary.com/demo/image/upload/sample.jpg',
    location: 'Amsterdam',
    badges: const [
      BadgeType.emailVerified,
      BadgeType.phoneVerified,
      BadgeType.fastResponder,
    ],
    averageRating: 4.7,
    reviewCount: 23,
    responseTimeMinutes: 15,
    createdAt: DateTime(2025, 6),
  ),
  UserEntity(
    id: 'user-002',
    displayName: 'Maria Jansen',
    email: 'maria@deelmarkt.nl',
    phone: '+31698765432',
    kycLevel: KycLevel.level2,
    location: 'Rotterdam',
    badges: const [
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
  // P-39: Too-few reviews (< 3, rating hidden)
  UserEntity(
    id: 'user-003',
    displayName: 'Pieter Bakker',
    kycLevel: KycLevel.level1,
    location: 'Utrecht',
    badges: const [BadgeType.emailVerified, BadgeType.newUser],
    averageRating: 5.0,
    reviewCount: 2,
    createdAt: DateTime(2026, 2),
  ),
  // P-39: No listings, many reviews
  UserEntity(
    id: 'user-004',
    displayName: 'Sophie van Dijk',
    kycLevel: KycLevel.level1,
    location: 'Den Haag',
    badges: const [BadgeType.emailVerified, BadgeType.phoneVerified],
    averageRating: 3.8,
    reviewCount: 12,
    responseTimeMinutes: 120,
    createdAt: DateTime(2025, 9),
  ),
  // P-39: Seller profile (current user as seller)
  UserEntity(
    id: 'user-seller',
    displayName: 'Verkoper Test',
    kycLevel: KycLevel.level2,
    location: 'Eindhoven',
    badges: const [
      BadgeType.emailVerified,
      BadgeType.phoneVerified,
      BadgeType.idVerified,
    ],
    averageRating: 4.5,
    reviewCount: 15,
    responseTimeMinutes: 30,
    createdAt: DateTime(2025, 5),
  ),
];
