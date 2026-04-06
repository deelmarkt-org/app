import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/messages/domain/entities/message_type.dart';
import 'package:deelmarkt/features/messages/domain/entities/scam_detection.dart';

/// Single message in a conversation.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Scam fields ([scamConfidence], [scamReasons], [scamFlaggedAt]) are
/// populated asynchronously by the R-35 Edge Function after insert.
/// The invariant is enforced by both the DB CHECK constraint and the
/// constructor assert: when [scamConfidence] is not [ScamConfidence.none],
/// [scamReasons] and [scamFlaggedAt] must be non-null.
///
/// Reference: docs/epics/E04-messaging.md, docs/epics/E06-trust-moderation.md
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = MessageType.text,
    this.isRead = false,
    this.offerAmountCents,
    this.scamConfidence = ScamConfidence.none,
    this.scamReasons,
    this.scamFlaggedAt,
  }) : assert(
         scamConfidence == ScamConfidence.none ||
             (scamReasons != null && scamFlaggedAt != null),
         'When scamConfidence is low or high, scamReasons and '
         'scamFlaggedAt must be provided.',
       ),
       assert(
         scamConfidence != ScamConfidence.none ||
             (scamReasons == null && scamFlaggedAt == null),
         'When scamConfidence is none, scamReasons and scamFlaggedAt '
         'must be null.',
       ),
       assert(
         type != MessageType.offer || offerAmountCents != null,
         'offerAmountCents must be provided when type is offer.',
       );

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final MessageType type;
  final bool isRead;

  /// Offer amount in euro cents — non-null only when [type] is [MessageType.offer].
  final int? offerAmountCents;

  /// E06 scam detector confidence on this message.
  /// Defaults to [ScamConfidence.none].
  final ScamConfidence scamConfidence;

  /// Reasons the detector flagged the message. Null when not flagged.
  final List<ScamReason>? scamReasons;

  /// Timestamp when the detector flagged the message. Null when not flagged.
  final DateTime? scamFlaggedAt;

  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    text,
    type,
    isRead,
    offerAmountCents,
    createdAt,
    scamConfidence,
    scamReasons,
    scamFlaggedAt,
  ];

  /// Creates a copy with the given fields replaced.
  ///
  /// Nullable scam fields use a sentinel pattern: pass the field explicitly
  /// to update it (including setting it to `null` to clear a flag).
  /// Omitting a field preserves the current value.
  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    MessageType? type,
    bool? isRead,
    int? offerAmountCents,
    DateTime? createdAt,
    ScamConfidence? scamConfidence,
    Object? scamReasons = _sentinel,
    Object? scamFlaggedAt = _sentinel,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      offerAmountCents: offerAmountCents ?? this.offerAmountCents,
      createdAt: createdAt ?? this.createdAt,
      scamConfidence: scamConfidence ?? this.scamConfidence,
      scamReasons:
          scamReasons == _sentinel
              ? this.scamReasons
              : scamReasons as List<ScamReason>?,
      scamFlaggedAt:
          scamFlaggedAt == _sentinel
              ? this.scamFlaggedAt
              : scamFlaggedAt as DateTime?,
    );
  }

  static const Object _sentinel = Object();
}
