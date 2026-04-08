import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/messages/domain/entities/conversation_entity.dart';

/// DTO for converting Supabase RPC JSON to [ConversationEntity].
///
/// Parses rows returned by the `get_conversations_for_user()` RPC,
/// which joins conversations, listings, and user_profiles into a single
/// enriched row. All parsing is defensive.
class ConversationDto {
  const ConversationDto._();

  /// Parse a single RPC row from `get_conversations_for_user`.
  static ConversationEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final listingId = json['listing_id'];
    final listingTitle = json['listing_title'];
    final otherUserId = json['other_user_id'];
    final otherUserName = json['other_user_name'];
    final lastMessageText = json['last_message_text'] as String?;
    final lastMessageType = json['last_message_type'] as String?;
    final lastMessageAtRaw = json['last_message_at'];

    if (id is! String ||
        listingId is! String ||
        listingTitle is! String ||
        otherUserId is! String ||
        otherUserName is! String ||
        lastMessageAtRaw is! String) {
      throw const FormatException(
        'ConversationDto.fromJson: missing or invalid required fields',
      );
    }

    return ConversationEntity(
      id: id,
      listingId: listingId,
      listingTitle: listingTitle,
      listingImageUrl: json['listing_image_url'] as String?,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      otherUserAvatarUrl: json['other_user_avatar_url'] as String?,
      lastMessageText: lastMessageText ?? '',
      lastMessageAt: DateTime.parse(lastMessageAtRaw),
      lastMessageType: lastMessageType,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Parse a list of RPC rows. Skips malformed entries and logs warnings.
  static List<ConversationEntity> fromJsonList(List<dynamic> jsonList) {
    final result = <ConversationEntity>[];
    for (final item in jsonList.whereType<Map<String, dynamic>>()) {
      try {
        result.add(fromJson(item));
      } on FormatException catch (e) {
        AppLogger.warning(
          'Skipped malformed conversation row: $e',
          tag: 'ConversationDto',
        );
      }
    }
    return result;
  }
}
