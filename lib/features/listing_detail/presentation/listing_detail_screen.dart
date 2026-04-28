import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_loading_view.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/listing_detail_data_view.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Listing detail screen — route: `/listings/:id` (deep link + in-app).
///
/// Owns the AsyncValue → child mapping; the loaded-data presentation
/// layer (responsive layouts, gallery, action bar, share + clipboard
/// side effects) lives in [ListingDetailDataView] (P-54 PR-D2 split
/// for §2.1 200-line cap).
///
/// Reference: docs/screens/03-listings/01-listing-detail.md
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(listingDetailNotifierProvider(listingId));

    return state.when(
      loading: () => const DetailLoadingView(),
      error:
          (_, _) => Scaffold(
            appBar: AppBar(),
            body: ErrorState(
              onRetry:
                  () =>
                      ref.invalidate(listingDetailNotifierProvider(listingId)),
            ),
          ),
      data:
          (data) => ListingDetailDataView(
            data: data,
            listingId: listingId,
            onFavouriteTap:
                () =>
                    ref
                        .read(listingDetailNotifierProvider(listingId).notifier)
                        .toggleFavourite(),
          ),
    );
  }
}
