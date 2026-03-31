import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

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

/// Default location (Amsterdam Centraal) — replaced by device location
/// when LocationService is implemented (E05).
const _defaultLatitude = 52.3676;
const _defaultLongitude = 4.9041;
const _pageSize = 10;

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<HomeState> build() async {
    final listings = ref.watch(listingRepositoryProvider);
    final categories = ref.watch(categoryRepositoryProvider);

    final results = await Future.wait([
      categories.getTopLevel(),
      listings.getNearby(
        latitude: _defaultLatitude,
        longitude: _defaultLongitude,
        limit: _pageSize,
      ),
      listings.getRecent(limit: _pageSize),
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
    state = await AsyncValue.guard(() => build());
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
      final listings = ref.read(listingRepositoryProvider);
      final updated = await listings.toggleFavourite(listingId);
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
      debugPrint('Failed to toggle favourite: $e');
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
