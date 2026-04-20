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

  /// Whether the seller has no listings — triggers [SellerHomeEmptyView].
  ///
  /// Checks **only** `listings.isEmpty`. Stats and actions may be non-empty
  /// while this returns `true` (e.g. a returning seller with historical sales
  /// but no currently active listings). This is intentional: the empty-state
  /// screen is a listing-creation prompt, not a "no data" fallback.
  ///
  /// If a future sprint needs to distinguish "never listed" from "all sold",
  /// replace this getter with a `SellerHomeViewState` enum — see the E01
  /// epic seller-mode states table.
  bool get isEmpty => listings.isEmpty;

  @override
  List<Object?> get props => [userName, stats, actions, listings];
}
