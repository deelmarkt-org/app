import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';

part 'home_notifier.g.dart';

class HomeState {
  const HomeState({
    this.categories = const [],
    this.nearby = const [],
    this.recent = const [],
  });

  final List<CategoryEntity> categories;
  final List<ListingEntity> nearby;
  final List<ListingEntity> recent;
}

@riverpod
class HomeNotifier extends _$HomeNotifier {
  @override
  Future<HomeState> build() async {
    final listings = ref.watch(listingRepositoryProvider);
    final categories = ref.watch(categoryRepositoryProvider);

    final results = await Future.wait([
      categories.getTopLevel(),
      listings.getNearby(
        latitude: 52.3676,
        longitude: 4.9041,
        radiusKm: 25,
        limit: 10,
      ),
      listings.getRecent(limit: 10),
    ]);

    return HomeState(
      categories: results[0] as List<CategoryEntity>,
      nearby: results[1] as List<ListingEntity>,
      recent: results[2] as List<ListingEntity>,
    );
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => build());
  }

  Future<void> toggleFavourite(String listingId) async {
    final listings = ref.read(listingRepositoryProvider);
    final updated = await listings.toggleFavourite(listingId);
    final current = state.valueOrNull;
    if (current == null) return;

    state = AsyncValue.data(
      HomeState(
        categories: current.categories,
        nearby: _replaceListing(current.nearby, updated),
        recent: _replaceListing(current.recent, updated),
      ),
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
