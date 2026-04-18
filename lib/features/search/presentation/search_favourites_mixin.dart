import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/utils/listing_list_extensions.dart';
import 'package:deelmarkt/features/search/presentation/search_state.dart';

/// Optimistic favourite toggle mixin for [SearchNotifier].
///
/// Mirrors the `_inFlight` guard pattern from [CategoryDetailNotifier] and
/// [FavouritesNotifier]. Reverts only the target listing in the **latest**
/// state to preserve concurrent loadMore/search results.
/// Reference: docs/epics/E01-listing-management.md
mixin SearchFavouritesMixin on AutoDisposeAsyncNotifier<SearchState> {
  static const _logTag = 'search-favourites';

  /// Guard against overlapping favourite toggles on the same listing.
  final _inFlight = <String>{};

  /// Optimistic favourite toggle with race-condition guard and granular revert.
  Future<void> toggleFavourite(String listingId) async {
    if (_inFlight.contains(listingId)) return;
    final current = state.valueOrNull;
    if (current == null) return;
    _inFlight.add(listingId);
    state = AsyncValue.data(
      current.copyWith(listings: current.listings.toggleFavourited(listingId)),
    );
    try {
      final updated = await ref.read(toggleFavouriteUseCaseProvider)(listingId);
      final latest = state.valueOrNull;
      if (latest == null) return;
      state = AsyncValue.data(
        latest.copyWith(listings: latest.listings.replaceById(updated)),
      );
    } on Exception catch (e) {
      AppLogger.error('Failed to toggle favourite', error: e, tag: _logTag);
      final latest = state.valueOrNull;
      if (latest != null) {
        state = AsyncValue.data(
          latest.copyWith(
            listings: latest.listings.toggleFavourited(listingId),
          ),
        );
      }
    } finally {
      _inFlight.remove(listingId);
    }
  }
}
