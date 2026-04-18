import 'package:equatable/equatable.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_nearby_listings_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_recent_listings_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_top_categories_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/toggle_favourite_usecase.dart';

part 'home_notifier.g.dart';

class HomeState extends Equatable {
  const HomeState({
    this.categories = const [],
    this.nearby = const [],
    this.recent = const [],
  });

  final List<CategoryEntity> categories;
  final List<ListingEntity> nearby;
  final List<ListingEntity> recent;

  @override
  List<Object?> get props => [categories, nearby, recent];
}

/// Riverpod provider for [GetTopCategoriesUseCase].
final getTopCategoriesUseCaseProvider = Provider<GetTopCategoriesUseCase>(
  (ref) => GetTopCategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

/// Riverpod provider for [GetNearbyListingsUseCase].
final getNearbyListingsUseCaseProvider = Provider<GetNearbyListingsUseCase>(
  (ref) => GetNearbyListingsUseCase(ref.watch(listingRepositoryProvider)),
);

/// Riverpod provider for [GetRecentListingsUseCase].
final getRecentListingsUseCaseProvider = Provider<GetRecentListingsUseCase>(
  (ref) => GetRecentListingsUseCase(ref.watch(listingRepositoryProvider)),
);

/// Riverpod provider for [ToggleFavouriteUseCase].
final toggleFavouriteUseCaseProvider = Provider<ToggleFavouriteUseCase>(
  (ref) => ToggleFavouriteUseCase(ref.watch(listingRepositoryProvider)),
);

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<HomeState> build() => _fetchData();

  Future<HomeState> _fetchData() async {
    final getTopCategories = ref.watch(getTopCategoriesUseCaseProvider);
    final getNearbyListings = ref.watch(getNearbyListingsUseCaseProvider);
    final getRecentListings = ref.watch(getRecentListingsUseCaseProvider);

    final results = await Future.wait([
      getTopCategories(),
      getNearbyListings(),
      getRecentListings(),
    ]);

    return HomeState(
      categories: results[0] as List<CategoryEntity>,
      nearby: results[1] as List<ListingEntity>,
      recent: results[2] as List<ListingEntity>,
    );
  }

  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchData);
    // If refresh fails, restore previous data so the user doesn't lose content.
    if (state.hasError && previous != null) {
      state = AsyncValue.data(previous);
    }
  }

  Future<void> toggleFavourite(String listingId) async {
    final current = state.valueOrNull;
    if (current == null) return;

    // Optimistic UI: toggle immediately
    final optimistic = _toggleInList(current, listingId);
    state = AsyncValue.data(optimistic);

    try {
      final toggleFav = ref.read(toggleFavouriteUseCaseProvider);
      final updated = await toggleFav(listingId);
      final latest = state.valueOrNull;
      if (latest == null) return;

      state = AsyncValue.data(
        HomeState(
          categories: latest.categories,
          nearby: _replaceListing(latest.nearby, updated),
          recent: _replaceListing(latest.recent, updated),
        ),
      );
    } on Exception catch (e) {
      // Revert optimistic update on failure
      AppLogger.error('Failed to toggle favourite', error: e, tag: 'home');
      state = AsyncValue.data(current);
    }
  }

  HomeState _toggleInList(HomeState current, String listingId) {
    return HomeState(
      categories: current.categories,
      nearby: [
        for (final l in current.nearby)
          if (l.id == listingId)
            l.copyWith(isFavourited: !l.isFavourited)
          else
            l,
      ],
      recent: [
        for (final l in current.recent)
          if (l.id == listingId)
            l.copyWith(isFavourited: !l.isFavourited)
          else
            l,
      ],
    );
  }

  List<ListingEntity> _replaceListing(
    List<ListingEntity> list,
    ListingEntity updated,
  ) {
    return [
      for (final l in list)
        if (l.id == updated.id) updated else l,
    ];
  }
}
