import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/domain/usecases/get_favourites_usecase.dart';

part 'favourites_notifier.g.dart';

/// Riverpod provider for [GetFavouritesUseCase].
final _getFavouritesUseCaseProvider = Provider<GetFavouritesUseCase>(
  (ref) => GetFavouritesUseCase(ref.watch(listingRepositoryProvider)),
);

/// Manages the user's favourited listings with optimistic updates.
///
/// Supports remove-with-undo and re-favourite flows.
/// Uses `_inFlight` guard to prevent race conditions on rapid remove+undo.
/// Reference: docs/epics/E01-listing-management.md
@riverpod
class FavouritesNotifier extends _$FavouritesNotifier {
  /// Guard against overlapping operations on the same listing ID.
  final _inFlight = <String>{};

  @override
  Future<List<ListingEntity>> build() => _fetchFavourites();

  Future<List<ListingEntity>> _fetchFavourites() async {
    final getFavourites = ref.watch(_getFavouritesUseCaseProvider);
    return getFavourites();
  }

  /// Pull-to-refresh with previous state preservation on error.
  Future<void> refresh() async {
    final previous = state.valueOrNull;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetchFavourites);
    if (state.hasError && previous != null) {
      state = AsyncValue.data(previous);
    }
  }

  /// Removes a listing from favourites with optimistic UI.
  ///
  /// Returns the removed [ListingEntity] for SnackBar undo, or null on error.
  Future<ListingEntity?> removeFavourite(String listingId) async {
    if (_inFlight.contains(listingId)) return null;
    final current = state.valueOrNull;
    if (current == null) return null;

    final listing = current.where((l) => l.id == listingId).firstOrNull;
    if (listing == null) return null;

    _inFlight.add(listingId);

    // Optimistic: remove immediately
    state = AsyncValue.data([
      for (final l in current)
        if (l.id != listingId) l,
    ]);

    try {
      final toggleFav = ref.read(toggleFavouriteUseCaseProvider);
      await toggleFav(listingId);
      return listing;
    } on Exception catch (e) {
      AppLogger.error(
        'Failed to remove favourite',
        error: e,
        tag: 'favourites',
      );
      state = AsyncValue.data(current);
      return null;
    } finally {
      _inFlight.remove(listingId);
    }
  }

  /// Re-favourites a previously removed listing (undo action).
  Future<void> undoRemove(ListingEntity listing) async {
    if (_inFlight.contains(listing.id)) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _inFlight.add(listing.id);

    // Optimistic: insert at top
    state = AsyncValue.data([listing, ...current]);

    try {
      final toggleFav = ref.read(toggleFavouriteUseCaseProvider);
      await toggleFav(listing.id);
    } on Exception catch (e) {
      AppLogger.error(
        'Failed to undo favourite removal',
        error: e,
        tag: 'favourites',
      );
      state = AsyncValue.data([
        for (final l in state.valueOrNull ?? current)
          if (l.id != listing.id) l,
      ]);
    } finally {
      _inFlight.remove(listing.id);
    }
  }
}
