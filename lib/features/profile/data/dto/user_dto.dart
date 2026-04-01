import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// DTO for converting Supabase REST JSON to [UserEntity].
///
/// Defensive parsing — validates required fields, uses tryParse for dates.
class UserDto {
  const UserDto._();

  /// Parse a Supabase JSON row from `user_profiles` table.
  static UserEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final displayName = json['display_name'];
    final createdAtRaw = json['created_at'];

    if (id is! String || displayName is! String) {
      throw FormatException(
        'UserDto.fromJson: missing required fields (id=$id, display_name=$displayName)',
      );
    }

    return UserEntity(
      id: id,
      displayName: displayName,
      avatarUrl: json['avatar_url'] as String?,
      location: json['location'] as String?,
      kycLevel: _parseKycLevel(json['kyc_level'] as String?),
      badges: BadgeType.fromDbList((json['badges'] as List<dynamic>?) ?? []),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as int?) ?? 0,
      responseTimeMinutes: json['response_time_minutes'] as int?,
      createdAt:
          createdAtRaw is String
              ? (DateTime.tryParse(createdAtRaw) ?? DateTime.now())
              : DateTime.now(),
    );
  }

  /// Convert [UserEntity] to Supabase INSERT/UPDATE JSON.
  static Map<String, dynamic> toJson(UserEntity entity) {
    return {
      'id': entity.id,
      'display_name': entity.displayName,
      'avatar_url': entity.avatarUrl,
      'location': entity.location,
      'badges': BadgeType.toDbList(entity.badges),
    };
  }

  /// Parse a list of JSON rows. Skips malformed entries.
  static List<UserEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.whereType<Map<String, dynamic>>().map(fromJson).toList();
  }

  static KycLevel _parseKycLevel(String? value) {
    if (value == null) return KycLevel.level0;
    return switch (value) {
      'level0' => KycLevel.level0,
      'level1' => KycLevel.level1,
      'level2' => KycLevel.level2,
      'level3' => KycLevel.level3,
      'level4' => KycLevel.level4,
      _ => KycLevel.level0,
    };
  }
}
