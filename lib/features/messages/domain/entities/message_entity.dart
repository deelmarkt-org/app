import 'package:equatable/equatable.dart';

import 'package:deelmarkt/core/domain/entities/scam_reason.dart';

/// Single message in a conversation.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/epics/E04-messaging.md, docs/epics/E06-trust-moderation.md
class MessageEntity extends Equatable {
  // Non-const: runtime asserts on scamReasons/scamFlaggedAt disqualify const.
  // ignore: prefer_const_constructors_in_immutables
  MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = MessageType.text,
    this.isRead = false,
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
       );

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  /// E06 scam detector confidence on this message.
  /// Defaults to [ScamConfidence.none].
  final ScamConfidence scamConfidence;

  /// Reasons the detector flagged the message. Null when not flagged.
  final List<ScamReason>? scamReasons;

  /// Timestamp when the detector flagged the message. Null when not flagged.
  final DateTime? scamFlaggedAt;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    text,
    type,
    isRead,
    createdAt,
    scamConfidence,
    scamReasons,
    scamFlaggedAt,
  ];

  /// Returns a copy with the given fields replaced.
  ///
  /// **Limitation:** `scamReasons` and `scamFlaggedAt` use the `??`
  /// operator so they cannot be explicitly set back to `null` via this
  /// method. To clear scam metadata (e.g. unflagging a false positive),
  /// construct a new [MessageEntity] directly with
  /// `scamConfidence: ScamConfidence.none` (the asserts will enforce the
  /// null invariant).
  MessageEntity copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? text,
    MessageType? type,
    bool? isRead,
    DateTime? createdAt,
    ScamConfidence? scamConfidence,
    List<ScamReason>? scamReasons,
    DateTime? scamFlaggedAt,
  }) {
    return MessageEntity(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      scamConfidence: scamConfidence ?? this.scamConfidence,
      scamReasons: scamReasons ?? this.scamReasons,
      scamFlaggedAt: scamFlaggedAt ?? this.scamFlaggedAt,
    );
  }
}

/// Message types — per design system patterns.md §Chat.
enum MessageType { text, offer, systemAlert, scamWarning }
