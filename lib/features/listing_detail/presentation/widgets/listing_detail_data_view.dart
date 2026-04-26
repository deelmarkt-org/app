import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/listing_detail/presentation/listing_detail_notifier.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_action_bar.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_image_gallery.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_info_section.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_seller_card.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/sold_overlay.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

/// Loaded-data presenter for [ListingDetailScreen].
///
/// Renders the gallery + slivers + action bar with a responsive
/// compact / expanded layout split. Pure StatelessWidget — all state
/// resolved by the parent screen and passed in via the constructor
/// (per CLAUDE.md §1.2 + P-54 D2 — `StatelessWidget` default for
/// extracted sub-widgets).
///
/// Reference: docs/screens/03-listings/01-listing-detail.md
class ListingDetailDataView extends StatelessWidget {
  const ListingDetailDataView({
    required this.data,
    required this.listingId,
    required this.onFavouriteTap,
    super.key,
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
    // Outer SafeArea with `top: false` keeps the gallery bleeding into
    // the status bar (the inner `SafeArea(bottom: false)` on the gallery
    // sliver handles the top-edge case) while preventing the action bar
    // from overlapping the home indicator on iOS / nav bar on Android
    // (Gemini PR #240 review).
    return Scaffold(
      body: SafeArea(
        top: false,
        child: Column(
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
      ),
    );
  }

  Widget _expandedLayout(BuildContext context, ListingEntity listing) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              flex: 3,
              child: Align(
                alignment: Alignment.topCenter,
                child: _buildGallery(context, listing),
              ),
            ),
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

  Future<void> _shareListing(BuildContext context) async {
    // Build the URL via Uri so a stray trailing slash on
    // `AppConstants.deepLinkBase` doesn't double up and listing IDs with
    // reserved characters are encoded correctly.
    final url =
        Uri.parse(
          AppConstants.deepLinkBase,
        ).replace(path: '/listings/$listingId').toString();
    await Clipboard.setData(ClipboardData(text: url));
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('action.share'.tr())));
  }
}
