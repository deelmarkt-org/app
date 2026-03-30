import 'package:equatable/equatable.dart';

/// DeelMarkt user profile.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/epics/E02-user-auth-kyc.md
class UserEntity extends Equatable {
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
  List<Object?> get props => [
    id,
    displayName,
    avatarUrl,
    location,
    kycLevel,
    badges,
    averageRating,
    reviewCount,
    responseTimeMinutes,
    createdAt,
  ];

  UserEntity copyWith({
    String? id,
    String? displayName,
    String? avatarUrl,
    String? location,
    KycLevel? kycLevel,
    List<BadgeType>? badges,
    double? averageRating,
    int? reviewCount,
    int? responseTimeMinutes,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      displayName: displayName ?? this.displayName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      location: location ?? this.location,
      kycLevel: kycLevel ?? this.kycLevel,
      badges: badges ?? this.badges,
      averageRating: averageRating ?? this.averageRating,
      reviewCount: reviewCount ?? this.reviewCount,
      responseTimeMinutes: responseTimeMinutes ?? this.responseTimeMinutes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// Progressive KYC levels — per E02 epic.
enum KycLevel {
  /// Email verified only.
  level0,

  /// Phone verified.
  level1,

  /// iDIN bank verification (BRP/DigiD).
  level2,

  /// ID document verified.
  level3,

  /// Business seller (KVK).
  level4,
}

/// Verification badge types — per design system components.md.
///
/// DB stores as TEXT[] (e.g. ['emailVerified', 'phoneVerified']).
/// Use [BadgeType.fromDbList] and [BadgeType.toDbList] for serialization.
enum BadgeType {
  emailVerified,
  phoneVerified,
  idVerified,
  trustedSeller,
  fastResponder,
  topRated,
  newUser;

  /// Parse a list of DB strings to BadgeType list.
  /// Unknown values are silently skipped (forward-compatible).
  static List<BadgeType> fromDbList(List<dynamic> values) {
    return values
        .whereType<String>()
        .map((v) {
          try {
            return BadgeType.values.firstWhere((b) => b.name == v);
          } catch (_) {
            return null;
          }
        })
        .whereType<BadgeType>()
        .toList();
  }

  /// Convert to DB TEXT[] format.
  static List<String> toDbList(List<BadgeType> badges) {
    return badges.map((b) => b.name).toList();
  }
}
