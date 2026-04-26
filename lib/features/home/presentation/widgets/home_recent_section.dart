import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/widgets/section_header.dart';
import 'package:deelmarkt/widgets/cards/escrow_aware_listing_card.dart';

/// Height of the recent listings horizontal row.
const double _recentRowHeight = 280;

/// Width of each card in the recent listings row.
const double _recentCardWidth = 180;

/// "Recently added" header sliver for the buyer home view.
class HomeRecentHeader extends StatelessWidget {
  const HomeRecentHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(top: Spacing.s6, bottom: Spacing.s3),
        child: SectionHeader(
          title: 'home.recentlyAdded'.tr(),
          actionLabel: 'home.viewAll'.tr(),
          onAction: () => context.go(AppRoutes.search),
        ),
      ),
    );
  }
}

/// Horizontal carousel of "recently added" listings on the buyer home view.
class HomeRecentRow extends StatelessWidget {
  const HomeRecentRow({
    required this.listings,
    required this.onToggleFavourite,
    super.key,
  });

  final List<ListingEntity> listings;
  final ValueChanged<String> onToggleFavourite;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SizedBox(
        height: _recentRowHeight,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: Spacing.s4),
          itemCount: listings.length,
          separatorBuilder: (_, _) => const SizedBox(width: Spacing.s3),
          itemBuilder: (context, index) {
            final listing = listings[index];
            return SizedBox(
              width: _recentCardWidth,
              child: EscrowAwareListingCard(
                listing: listing,
                onTap:
                    () => context.goNamed(
                      'listing-detail',
                      pathParameters: {'id': listing.id},
                    ),
                onFavouriteTap: () => onToggleFavourite(listing.id),
              ),
            );
          },
        ),
      ),
    );
  }
}
