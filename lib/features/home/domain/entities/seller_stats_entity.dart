import 'package:equatable/equatable.dart';

/// Seller dashboard statistics — aggregated from listings, messages,
/// and transactions repositories.
///
/// All monetary values in cents to avoid floating-point errors.
/// Extends [Equatable] for Riverpod state diffing (ADR-21).
class SellerStatsEntity extends Equatable {
  const SellerStatsEntity({
    required this.totalSalesCents,
    required this.activeListingsCount,
    required this.unreadMessagesCount,
  });

  /// Total revenue from completed sales, in cents (e.g. 124700 = €1.247,00).
  final int totalSalesCents;

  /// Number of currently active (unsold) listings.
  final int activeListingsCount;

  /// Number of unread messages across all conversations.
  final int unreadMessagesCount;

  @override
  List<Object?> get props => [
    totalSalesCents,
    activeListingsCount,
    unreadMessagesCount,
  ];
}
