import 'package:equatable/equatable.dart';

/// Single message in a conversation.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/epics/E04-messaging.md
class MessageEntity extends Equatable {
  const MessageEntity({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.type = MessageType.text,
    this.isRead = false,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final MessageType type;
  final bool isRead;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    text,
    type,
    isRead,
    createdAt,
  ];
}

/// Message types — per design system patterns.md §Chat.
enum MessageType { text, offer, systemAlert, scamWarning }
