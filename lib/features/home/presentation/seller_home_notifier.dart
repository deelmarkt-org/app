import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/action_item_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/seller_stats_entity.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_actions_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_listings_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_stats_usecase.dart';

part 'seller_home_notifier.g.dart';

/// State for the seller home dashboard.
class SellerHomeState extends Equatable {
  const SellerHomeState({
    required this.userName,
    required this.stats,
    required this.actions,
    required this.listings,
  });

  final String userName;
  final SellerStatsEntity stats;
  final List<ActionItemEntity> actions;
  final List<ListingEntity> listings;

  /// Whether the seller has no listings at all (empty state).
  bool get isEmpty => listings.isEmpty;

  @override
  List<Object?> get props => [userName, stats, actions, listings];
}

/// Riverpod provider for [GetSellerStatsUseCase].
final getSellerStatsUseCaseProvider = Provider<GetSellerStatsUseCase>(
  (ref) => GetSellerStatsUseCase(
    listingRepository: ref.watch(listingRepositoryProvider),
    messageRepository: ref.watch(messageRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  ),
);

/// Riverpod provider for [GetSellerActionsUseCase].
final getSellerActionsUseCaseProvider = Provider<GetSellerActionsUseCase>(
  (ref) => GetSellerActionsUseCase(
    messageRepository: ref.watch(messageRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  ),
);

/// Riverpod provider for [GetSellerListingsUseCase].
final getSellerListingsUseCaseProvider = Provider<GetSellerListingsUseCase>(
  (ref) => GetSellerListingsUseCase(ref.watch(listingRepositoryProvider)),
);

@riverpod
class SellerHomeNotifier extends _$SellerHomeNotifier {
  @override
  Future<SellerHomeState> build() => _fetchData();

  Future<SellerHomeState> _fetchData() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) {
      throw StateError('Seller mode requires authentication');
    }

    final userId = user.id;
    final getStats = ref.watch(getSellerStatsUseCaseProvider);
    final getActions = ref.watch(getSellerActionsUseCaseProvider);
    final getListings = ref.watch(getSellerListingsUseCaseProvider);

    // Parallel fetch per audit finding A2.
    final (stats, actions, listings) =
        await (getStats(userId), getActions(userId), getListings(userId)).wait;

    final metadata = user.userMetadata;
    final rawName = metadata?['display_name'];
    final metaName = rawName as String?;
    final emailName = user.email?.split('@').first;
    final displayName = metaName ?? emailName ?? 'Verkoper';

    return SellerHomeState(
      userName: displayName,
      stats: stats,
      actions: actions,
      listings: listings,
    );
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchData);
    if (state.hasError && previous != null) {
      AppLogger.error(
        'Failed to refresh seller home',
        error: state.error,
        tag: 'seller_home',
      );
      state = AsyncValue.data(previous);
    }
  }
}
