import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_listing_card.dart';
import 'package:deelmarkt/widgets/trust/escrow_trust_banner.dart';

import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_image_gallery.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_info_section.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_seller_card.dart';

/// Listing detail screen — B-51.
///
/// Route: `/listings/:id` (deep link + in-app navigation).
/// Shows gallery, trust banner, price, description, seller card, action bar.
/// Handles sold and own-listing variants.
class ListingDetailScreen extends ConsumerWidget {
  const ListingDetailScreen({required this.listingId, super.key});

  final String listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailState = ref.watch(listingDetailNotifierProvider(listingId));

    return detailState.when(
      loading: () => const _LoadingView(),
      error:
          (error, _) => _ErrorView(
            onRetry:
                () => ref.invalidate(listingDetailNotifierProvider(listingId)),
          ),
      data:
          (data) => _DataView(
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

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Semantics(
          label: 'a11y.loading'.tr(),
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image skeleton
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: Container(
                          color: theme.colorScheme.surfaceContainerLow,
                        ),
                      ),
                      const SizedBox(height: Spacing.s4),
                      // Content skeletons
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [SkeletonListingCard()],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(), body: ErrorState(onRetry: onRetry));
  }
}

class _DataView extends StatelessWidget {
  const _DataView({
    required this.data,
    required this.listingId,
    required this.onFavouriteTap,
  });

  final ListingDetailState data;
  final String listingId;
  final VoidCallback onFavouriteTap;

  @override
  Widget build(BuildContext context) {
    final listing = data.listing;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                // Image gallery (replaces AppBar)
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: DetailImageGallery(
                      imageUrls: listing.imageUrls,
                      isFavourited: listing.isFavourited,
                      onFavouriteTap: onFavouriteTap,
                      onBack: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go(AppRoutes.home);
                        }
                      },
                      onShare: () => _shareListing(context),
                    ),
                  ),
                ),

                // Trust banner
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Spacing.s4,
                      vertical: Spacing.s4,
                    ),
                    child: EscrowTrustBanner(),
                  ),
                ),

                // Info section (price, condition, title, description, category, location)
                SliverToBoxAdapter(
                  child: DetailInfoSection(
                    listing: listing,
                    categoryName: data.category?.name,
                  ),
                ),

                // Seller card
                if (data.seller != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.s4,
                        vertical: Spacing.s4,
                      ),
                      child: DetailSellerCard(
                        seller: data.seller!,
                        onViewProfile:
                            () => context.goNamed(
                              'user-profile',
                              pathParameters: {'id': data.seller!.id},
                            ),
                      ),
                    ),
                  ),

                // Bottom padding for scroll clearance above action bar
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: Spacing.s8),
                ),
              ],
            ),
          ),

          // Sticky action bar
          DetailActionBar(
            priceInCents: listing.priceInCents,
            isOwnListing: data.isOwnListing,
            // onMessage, onBuy, onEdit, onDelete: wired in Phase 2 (E03/E04)
          ),
        ],
      ),
    );
  }

  void _shareListing(BuildContext context) {
    final url = 'https://deelmarkt.com/listings/$listingId';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('action.share'.tr())));
  }
}
