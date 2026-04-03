import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_image_gallery.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_info_section.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_loading_view.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_seller_card.dart';

/// Listing detail screen — B-51.
///
/// Route: `/listings/:id` (deep link + in-app navigation).
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
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: Spacing.s4,
                      vertical: Spacing.s4,
                    ),
                    child: TrustBanner.escrow(),
                  ),
                ),
                SliverToBoxAdapter(
                  child: DetailInfoSection(
                    listing: listing,
                    categoryName: data.category?.name,
                    isOwnListing: data.isOwnListing,
                  ),
                ),
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
                const SliverPadding(
                  padding: EdgeInsets.only(bottom: Spacing.s8),
                ),
              ],
            ),
          ),
          DetailActionBar(
            priceInCents: listing.priceInCents,
            isOwnListing: data.isOwnListing,
            onMessage: () => _showComingSoon(context),
            onBuy: () => _showComingSoon(context),
            onEdit: () => _showComingSoon(context),
            onDelete: () => _showComingSoon(context),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('action.comingSoon'.tr())));
  }

  void _shareListing(BuildContext context) {
    final url = '${AppConstants.deepLinkBase}/listings/$listingId';
    Clipboard.setData(ClipboardData(text: url));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('action.share'.tr())));
  }
}
