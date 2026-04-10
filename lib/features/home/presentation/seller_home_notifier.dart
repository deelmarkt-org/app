import 'package:riverpod_annotation/riverpod_annotation.dart';

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
