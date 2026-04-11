import 'package:equatable/equatable.dart';

import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';

/// State for the seller home dashboard.
class SellerHomeState extends Equatable {
  const SellerHomeState({
    this.userName,
    required this.stats,
    required this.actions,
    required this.listings,
  });

  /// Display name for the seller. Null when not available — presentation layer
  /// must substitute a localised fallback (e.g. `'mode.seller'.tr()`).
  final String? userName;
  final SellerStatsEntity stats;
  final List<ActionItemEntity> actions;
  final List<ListingEntity> listings;

  /// Whether the seller has no listings at all (empty state).
  bool get isEmpty => listings.isEmpty;

  @override
  List<Object?> get props => [userName, stats, actions, listings];
}
