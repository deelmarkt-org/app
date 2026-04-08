import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_detection.dart';

/// DTO for converting Supabase REST/Realtime JSON to [MessageEntity].
///
/// All parsing is defensive — malformed JSON throws [FormatException]
/// with a descriptive message instead of an opaque TypeError.
class MessageDto {
  const MessageDto._();

  /// Parse a single Supabase JSON row from the `messages` table.
  static MessageEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final conversationId = json['conversation_id'];
    final senderId = json['sender_id'];
    final text = json['text'];
    final createdAtRaw = json['created_at'];

    if (id is! String ||
        conversationId is! String ||
        senderId is! String ||
        text is! String ||
        createdAtRaw is! String) {
      throw const FormatException(
        'MessageDto.fromJson: missing or invalid required fields',
      );
    }

    final scamConfidence = ScamConfidence.fromDb(
      json['scam_confidence'] as String?,
    );

    final scamReasonsRaw = json['scam_reasons'] as List<dynamic>?;
    final scamReasons =
        scamReasonsRaw?.whereType<String>().map(ScamReason.fromDb).toList();

    final scamFlaggedAtRaw = json['scam_flagged_at'] as String?;
    final scamFlaggedAt =
        scamFlaggedAtRaw != null ? DateTime.tryParse(scamFlaggedAtRaw) : null;

    return MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      type: MessageType.fromDb((json['type'] as String?) ?? 'text'),
      isRead: (json['is_read'] as bool?) ?? false,
      offerAmountCents: json['offer_amount_cents'] as int?,
      createdAt: DateTime.parse(createdAtRaw),
      scamConfidence: scamConfidence,
      scamReasons: scamConfidence != ScamConfidence.none ? scamReasons : null,
      scamFlaggedAt:
          scamConfidence != ScamConfidence.none ? scamFlaggedAt : null,
    );
  }

  /// Convert [MessageEntity] to Supabase INSERT JSON (excludes server-generated fields).
  static Map<String, dynamic> toJson(MessageEntity entity) {
    return {
      'conversation_id': entity.conversationId,
      'sender_id': entity.senderId,
      'text': entity.text,
      'type': entity.type.toDb(),
      if (entity.offerAmountCents != null)
        'offer_amount_cents': entity.offerAmountCents,
    };
  }

  /// Build an INSERT payload from discrete fields. Avoids constructing a full
  /// [MessageEntity] just to serialise — used by [SupabaseMessageRepository.sendMessage].
  static Map<String, dynamic> toInsertJson({
    required String conversationId,
    required String senderId,
    required String text,
    required MessageType type,
    int? offerAmountCents,
  }) {
    return {
      'conversation_id': conversationId,
      'sender_id': senderId,
      'text': text,
      'type': type.toDb(),
      if (offerAmountCents != null) 'offer_amount_cents': offerAmountCents,
    };
  }

  /// Parse a list of JSON rows. Skips malformed entries and logs warnings.
  static List<MessageEntity> fromJsonList(List<dynamic> jsonList) {
    final result = <MessageEntity>[];
    for (final item in jsonList.whereType<Map<String, dynamic>>()) {
      try {
        result.add(fromJson(item));
      } on FormatException catch (e) {
        AppLogger.warning(
          'Skipped malformed message row: $e',
          tag: 'MessageDto',
        );
      }
    }
    return result;
  }
}
