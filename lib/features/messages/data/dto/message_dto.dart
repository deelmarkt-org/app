import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_entity.dart';
import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/features/messages/domain/entities/offer_status.dart';

/// DTO for converting Supabase REST/Realtime JSON to [MessageEntity].
///
/// All parsing is defensive — malformed JSON throws [FormatException]
/// with a descriptive message instead of an opaque TypeError.
class MessageDto {
  const MessageDto._();

  static const _colConversationId = 'conversation_id';
  static const _colSenderId = 'sender_id';
  static const _colText = 'text';
  static const _colType = 'type';
  static const _colOfferAmountCents = 'offer_amount_cents';

  /// Parse a single Supabase JSON row from the `messages` table.
  static MessageEntity fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final conversationId = json[_colConversationId];
    final senderId = json[_colSenderId];
    final text = json[_colText];
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

    final type = MessageType.fromDb((json[_colType] as String?) ?? 'text');

    return MessageEntity(
      id: id,
      conversationId: conversationId,
      senderId: senderId,
      text: text,
      type: type,
      isRead: (json['is_read'] as bool?) ?? false,
      offerAmountCents: json[_colOfferAmountCents] as int?,
      offerStatus:
          type == MessageType.offer
              ? (OfferStatus.fromDb(json['offer_status'] as String?) ??
                  OfferStatus.pending)
              : null,
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
      _colConversationId: entity.conversationId,
      _colSenderId: entity.senderId,
      _colText: entity.text,
      _colType: entity.type.toDb(),
      if (entity.offerAmountCents != null)
        _colOfferAmountCents: entity.offerAmountCents,
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
      _colConversationId: conversationId,
      _colSenderId: senderId,
      _colText: text,
      _colType: type.toDb(),
      if (offerAmountCents != null) _colOfferAmountCents: offerAmountCents,
      if (type == MessageType.offer) 'offer_status': OfferStatus.pending.toDb(),
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
