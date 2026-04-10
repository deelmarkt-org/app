import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';

/// DTO for converting Supabase REST JSON to [ActivityItemEntity].
///
/// Defensive parsing — validates required fields, uses tryParse for dates.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class ActivityItemDto {
  const ActivityItemDto._();

  /// Parse a Supabase JSON row from admin activity RPC.
  static ActivityItemEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final title = json['title'];
    final subtitle = json['subtitle'];
    final timestampRaw = json['timestamp'];

    if (id is! String || title is! String || subtitle is! String) {
      throw const FormatException(
        'ActivityItemDto.fromJson: missing or invalid required fields',
      );
    }

    final typeRaw = json['type'] as String?;
    final type = ActivityItemType.values.firstWhere(
      (e) => e.name == typeRaw,
      orElse: () => ActivityItemType.systemUpdate,
    );

    if (timestampRaw is! String) {
      throw const FormatException(
        'ActivityItemDto.fromJson: missing timestamp field',
      );
    }
    final timestamp = DateTime.tryParse(timestampRaw);
    if (timestamp == null) {
      throw const FormatException(
        'ActivityItemDto.fromJson: invalid timestamp value',
      );
    }

    return ActivityItemEntity(
      id: id,
      type: type,
      title: title,
      subtitle: subtitle,
      timestamp: timestamp,
    );
  }

  /// Parse a list of JSON rows. Skips malformed entries silently.
  static List<ActivityItemEntity> fromJsonList(List<dynamic> jsonList) {
    final results = <ActivityItemEntity>[];
    for (final item in jsonList) {
      if (item is! Map<String, dynamic>) continue;
      try {
        results.add(fromJson(item));
      } on FormatException {
        // Skip malformed entries — logged at debug level upstream
      }
    }
    return results;
  }
}
