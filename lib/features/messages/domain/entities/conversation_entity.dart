import 'package:equatable/equatable.dart';

/// Chat conversation between buyer and seller about a listing.
///
/// Immutable value object — domain layer, no Flutter/Supabase imports.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
///
/// Reference: docs/epics/E04-messaging.md
class ConversationEntity extends Equatable {
  const ConversationEntity({
    required this.id,
    required this.listingId,
    required this.listingTitle,
    required this.listingImageUrl,
    required this.otherUserId,
    required this.otherUserName,
    required this.lastMessageText,
    required this.lastMessageAt,
    this.otherUserAvatarUrl,
    this.lastMessageType,
    this.unreadCount = 0,
    this.sellerResponseTimeMinutes,
  });

  final String id;
  final String listingId;
  final String listingTitle;
  final String? listingImageUrl;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatarUrl;
  final String lastMessageText;
  final DateTime lastMessageAt;

  /// Raw message type from DB (e.g. "offer", "text"). Used by UI to format
  /// the preview string with the correct l10n template.
  final String? lastMessageType;
  final int unreadCount;

  /// Seller's median first-reply time in minutes, computed daily by R-33 cron.
  /// Null when the seller has too few conversations to compute a reliable stat.
  final int? sellerResponseTimeMinutes;

  @override
  List<Object?> get props => [
    id,
    listingId,
    listingTitle,
    listingImageUrl,
    otherUserId,
    otherUserName,
    otherUserAvatarUrl,
    lastMessageText,
    lastMessageAt,
    lastMessageType,
    unreadCount,
    sellerResponseTimeMinutes,
  ];

  ConversationEntity copyWith({
    String? id,
    String? listingId,
    String? listingTitle,
    String? listingImageUrl,
    String? otherUserId,
    String? otherUserName,
    String? otherUserAvatarUrl,
    String? lastMessageText,
    DateTime? lastMessageAt,
    String? lastMessageType,
    int? unreadCount,
    int? sellerResponseTimeMinutes,
  }) {
    return ConversationEntity(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      listingTitle: listingTitle ?? this.listingTitle,
      listingImageUrl: listingImageUrl ?? this.listingImageUrl,
      otherUserId: otherUserId ?? this.otherUserId,
      otherUserName: otherUserName ?? this.otherUserName,
      otherUserAvatarUrl: otherUserAvatarUrl ?? this.otherUserAvatarUrl,
      lastMessageText: lastMessageText ?? this.lastMessageText,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      unreadCount: unreadCount ?? this.unreadCount,
      sellerResponseTimeMinutes:
          sellerResponseTimeMinutes ?? this.sellerResponseTimeMinutes,
    );
  }
}
