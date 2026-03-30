import '../../domain/entities/user_entity.dart';

/// DTO for converting Supabase REST JSON to [UserEntity].
class UserDto {
  const UserDto._();

  /// Parse a Supabase JSON row from `user_profiles` table.
  static UserEntity fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String,
      displayName: json['display_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      location: json['location'] as String?,
      kycLevel: _parseKycLevel(json['kyc_level'] as String?),
      badges: BadgeType.fromDbList((json['badges'] as List<dynamic>?) ?? []),
      averageRating: (json['average_rating'] as num?)?.toDouble(),
      reviewCount: (json['review_count'] as int?) ?? 0,
      responseTimeMinutes: json['response_time_minutes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Convert [UserEntity] to Supabase INSERT/UPDATE JSON.
  /// Only includes writable fields.
  static Map<String, dynamic> toJson(UserEntity entity) {
    return {
      'id': entity.id,
      'display_name': entity.displayName,
      'avatar_url': entity.avatarUrl,
      'location': entity.location,
      'badges': BadgeType.toDbList(entity.badges),
    };
  }

  /// Parse a list of JSON rows.
  static List<UserEntity> fromJsonList(List<dynamic> jsonList) {
    return jsonList.map((e) => fromJson(e as Map<String, dynamic>)).toList();
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
