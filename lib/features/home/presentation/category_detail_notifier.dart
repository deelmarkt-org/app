import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/category_entity.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_category_by_id_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_listings_by_category_usecase.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_subcategories_usecase.dart';

/// State for a single category detail screen.
class CategoryDetailState extends Equatable {
  const CategoryDetailState({
    required this.parent,
    this.subcategories = const [],
    this.featuredListings = const [],
  });

  final CategoryEntity parent;
  final List<CategoryEntity> subcategories;
  final List<ListingEntity> featuredListings;

  CategoryDetailState copyWith({
    CategoryEntity? parent,
    List<CategoryEntity>? subcategories,
    List<ListingEntity>? featuredListings,
  }) {
    return CategoryDetailState(
      parent: parent ?? this.parent,
      subcategories: subcategories ?? this.subcategories,
      featuredListings: featuredListings ?? this.featuredListings,
    );
  }

  @override
  List<Object?> get props => [parent, subcategories, featuredListings];
}

/// Use case providers scoped to category detail.
final _getCategoryByIdUseCaseProvider = Provider<GetCategoryByIdUseCase>(
  (ref) => GetCategoryByIdUseCase(ref.watch(categoryRepositoryProvider)),
);

final _getSubcategoriesUseCaseProvider = Provider<GetSubcategoriesUseCase>(
  (ref) => GetSubcategoriesUseCase(ref.watch(categoryRepositoryProvider)),
);

final _getListingsByCategoryUseCaseProvider =
    Provider<GetListingsByCategoryUseCase>(
      (ref) => GetListingsByCategoryUseCase(
        ref.watch(listingRepositoryProvider),
        ref.watch(categoryRepositoryProvider),
      ),
    );

/// Provider family keyed by category ID.
final categoryDetailNotifierProvider = AsyncNotifierProvider.autoDispose
    .family<CategoryDetailNotifier, CategoryDetailState, String>(
      CategoryDetailNotifier.new,
    );

class CategoryDetailNotifier
    extends AutoDisposeFamilyAsyncNotifier<CategoryDetailState, String> {
  static const _logTag = 'category-detail';

  /// Guard against overlapping favourite toggles on the same listing.
  final _inFlight = <String>{};

  @override
  Future<CategoryDetailState> build(String arg) async {
    final getById = ref.watch(_getCategoryByIdUseCaseProvider);
    final getSubcategories = ref.watch(_getSubcategoriesUseCaseProvider);
    final getListings = ref.watch(_getListingsByCategoryUseCaseProvider);

    // Parallel fetch using Dart 3 record destructuring — immutable results.
    final (parent, subcategories, listings) =
        await (getById(arg), getSubcategories(arg), getListings(arg)).wait;

    if (parent == null) {
      throw Exception('Category not found');
    }

    return CategoryDetailState(
      parent: parent,
      subcategories: subcategories,
      featuredListings: listings,
    );
  }

  /// Optimistic favourite toggle with revert on failure.
  Future<void> toggleFavourite(String listingId) async {
    if (_inFlight.contains(listingId)) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _inFlight.add(listingId);

    // Optimistic UI: toggle immediately
    final optimistic = current.copyWith(
      featuredListings: [
        for (final l in current.featuredListings)
          if (l.id == listingId)
            l.copyWith(isFavourited: !l.isFavourited)
          else
            l,
      ],
    );
    state = AsyncValue.data(optimistic);

    try {
      final toggleFav = ref.read(toggleFavouriteUseCaseProvider);
      final updated = await toggleFav(listingId);
      final latest = state.valueOrNull;
      if (latest == null) return;

      state = AsyncValue.data(
        latest.copyWith(
          featuredListings: [
            for (final l in latest.featuredListings)
              if (l.id == updated.id) updated else l,
          ],
        ),
      );
    } on Exception catch (e) {
      AppLogger.error('Failed to toggle favourite', error: e, tag: _logTag);
      state = AsyncValue.data(current);
    } finally {
      _inFlight.remove(listingId);
    }
  }
}
