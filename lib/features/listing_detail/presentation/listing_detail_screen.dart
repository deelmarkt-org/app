import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_image_gallery.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_info_section.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_loading_view.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_seller_card.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/sold_overlay.dart';

/// Listing detail screen — route: `/listings/:id` (deep link + in-app).
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

  bool get _isSold => data.listing.status == ListingStatus.sold;

  @override
  Widget build(BuildContext context) {
    final listing = data.listing;
    final isExpanded = Breakpoints.isExpanded(context);

    if (isExpanded) return _expandedLayout(context, listing);
    return _compactLayout(context, listing);
  }

  Widget _compactLayout(BuildContext context, ListingEntity listing) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: SafeArea(
                    bottom: false,
                    child: _buildGallery(context, listing),
                  ),
                ),
                ..._detailSlivers(context),
              ],
            ),
          ),
          if (!_isSold) _actionBar(context),
        ],
      ),
    );
  }

  Widget _expandedLayout(BuildContext context, ListingEntity listing) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(flex: 3, child: _buildGallery(context, listing)),
            Flexible(
              flex: 2,
              child: Column(
                children: [
                  Expanded(
                    child: CustomScrollView(slivers: _detailSlivers(context)),
                  ),
                  if (!_isSold) _actionBar(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _detailSlivers(BuildContext context) {
    final listing = data.listing;
    return [
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(Spacing.s4),
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
            padding: const EdgeInsets.all(Spacing.s4),
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
      const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.s8)),
    ];
  }

  Widget _buildGallery(BuildContext context, ListingEntity listing) {
    final gallery = DetailImageGallery(
      imageUrls: listing.imageUrls,
      isFavourited: listing.isFavourited,
      onFavouriteTap: _isSold ? null : onFavouriteTap,
      onBack:
          () => context.canPop() ? context.pop() : context.go(AppRoutes.home),
      onShare: _isSold ? null : () => _shareListing(context),
    );
    return _isSold ? SoldOverlay(child: gallery) : gallery;
  }

  Widget _actionBar(BuildContext context) {
    return DetailActionBar(
      priceInCents: data.listing.priceInCents,
      isOwnListing: data.isOwnListing,
      onMessage: () => _showComingSoon(context),
      onBuy: () => _showComingSoon(context),
      onEdit: () => _showComingSoon(context),
      onDelete: () => _showComingSoon(context),
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
