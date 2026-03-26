/// DeelMarkt user profile.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
///
/// Reference: docs/epics/E02-user-auth-kyc.md
class UserEntity {
  const UserEntity({
    required this.id,
    required this.displayName,
    required this.kycLevel,
    required this.createdAt,
    this.avatarUrl,
    this.location,
    this.badges = const [],
    this.averageRating,
    this.reviewCount = 0,
    this.responseTimeMinutes,
  });

  final String id;
  final String displayName;
  final String? avatarUrl;
  final String? location;
  final KycLevel kycLevel;
  final List<BadgeType> badges;
  final double? averageRating;
  final int reviewCount;

  /// Average response time in minutes (shown on seller profile).
  final int? responseTimeMinutes;

  final DateTime createdAt;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is UserEntity && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Progressive KYC levels — per E02 epic.
enum KycLevel {
  /// Email verified only.
  level0,

  /// Phone verified.
  level1,

  /// iDIN bank verification (BRP/DigiD).
  level2,
}

/// Verification badge types — per design system components.md.
enum BadgeType {
  emailVerified,
  phoneVerified,
  idVerified,
  trustedSeller,
  fastResponder,
  topRated,
  newUser,
}
