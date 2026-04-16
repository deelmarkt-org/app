import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_actions_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_listings_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_seller_stats_usecase.dart';
import 'package:deelmarkt/features/home/presentation/seller_home_state.dart';

export 'package:deelmarkt/features/home/presentation/seller_home_state.dart';

part 'seller_home_notifier.g.dart';

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
  Future<SellerHomeState> build() {
    // ref.watch calls belong ONLY in build() so that Riverpod can track
    // subscriptions correctly. Calling ref.watch inside _fetchFor (or after
    // an await) was creating duplicate subscriptions on every refresh() call.
    // Fix #116: resolve all providers here, pass resolved values to _fetchFor.
    final user = ref.watch(currentUserProvider);
    final getStats = ref.watch(getSellerStatsUseCaseProvider);
    final getActions = ref.watch(getSellerActionsUseCaseProvider);
    final getListings = ref.watch(getSellerListingsUseCaseProvider);
    return _fetchFor(
      user: user,
      getStats: getStats,
      getActions: getActions,
      getListings: getListings,
    );
  }

  /// Core fetch logic — accepts all dependencies as parameters so it can be
  /// called from both [build] (via ref.watch) and [refresh] (via ref.read)
  /// without creating new provider subscriptions.
  Future<SellerHomeState> _fetchFor({
    required User? user,
    required GetSellerStatsUseCase getStats,
    required GetSellerActionsUseCase getActions,
    required GetSellerListingsUseCase getListings,
  }) async {
    if (user == null) {
      throw StateError('Seller mode requires authentication');
    }

    final userId = user.id;

    // Parallel fetch per audit finding A2.
    final (stats, actions, listings) =
        await (getStats(userId), getActions(userId), getListings(userId)).wait;

    final metaName = user.userMetadata?['display_name'] as String?;
    final emailName = user.email?.split('@').first;
    // null means no display name is available — presentation layer
    // substitutes the localised fallback via 'mode.seller'.tr().
    final displayName = metaName ?? emailName;

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
    // ref.read here — refresh() must NOT create new subscriptions.
    // Subscriptions are owned by build(); refresh reads the current values.
    state = await AsyncValue.guard(
      () => _fetchFor(
        user: ref.read(currentUserProvider),
        getStats: ref.read(getSellerStatsUseCaseProvider),
        getActions: ref.read(getSellerActionsUseCaseProvider),
        getListings: ref.read(getSellerListingsUseCaseProvider),
      ),
    );
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
