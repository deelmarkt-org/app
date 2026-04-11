import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';

/// DTO for converting Supabase REST JSON to [ActivityItemEntity].
///
/// Defensive parsing — validates required fields, uses tryParse for dates.
///
/// Expected JSON shape from admin activity RPC:
/// ```json
/// {
///   "id": "act-001",
///   "type": "listingRemoved",
///   "params": {"listingId": "4321", "moderator": "Moderator A"},
///   "timestamp": "2026-04-10T12:00:00.000Z"
/// }
/// ```
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class ActivityItemDto {
  const ActivityItemDto._();

  /// Parse a Supabase JSON row from admin activity RPC.
  static ActivityItemEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];

    if (id is! String) {
      throw const FormatException(
        'ActivityItemDto.fromJson: missing or invalid required field: id',
      );
    }

    final typeRaw = json['type'] as String?;
    final type = ActivityItemType.values.firstWhere(
      (e) => e.name == typeRaw,
      orElse: () => ActivityItemType.systemUpdate,
    );

    final rawParams = json['params'];
    final Map<String, String> params;
    if (rawParams is Map) {
      params = {
        for (final entry in rawParams.entries)
          if (entry.key is String && entry.value is String)
            entry.key as String: entry.value as String,
      };
    } else {
      params = const {};
    }

    final timestampRaw = json['timestamp'];
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
      params: params,
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
