import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';
import 'package:deelmarkt/widgets/cards/deel_card_skeleton.dart';
import 'package:deelmarkt/widgets/feedback/empty_state.dart';
import 'package:deelmarkt/widgets/feedback/error_state.dart';

/// Grid view of user's listings with status badges.
class ListingsTabView extends StatelessWidget {
  const ListingsTabView({
    required this.listings,
    required this.onRetry,
    super.key,
  });

  final AsyncValue<List<ListingEntity>> listings;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return listings.when(
      loading:
          () => GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: Spacing.listingCardGap,
              mainAxisSpacing: Spacing.listingCardGap,
              childAspectRatio: 0.7,
            ),
            itemCount: 4,
            itemBuilder: (_, _) => const DeelCardSkeleton(),
          ),
      error:
          (_, _) => ErrorState(message: 'error.generic'.tr(), onRetry: onRetry),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            variant: EmptyStateVariant.myListings,
            onAction: () {
              // Tracked: #51
            },
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: Spacing.listingCardGap,
            mainAxisSpacing: Spacing.listingCardGap,
            childAspectRatio: 0.7,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final listing = items[index];
            return DeelCard.grid(
              imageUrl:
                  listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
              priceFormatted:
                  '\u20AC ${(listing.priceInCents / 100).toStringAsFixed(2)}',
              title: listing.title,
              onTap: () {
                // Tracked: #52
              },
              location: listing.location,
            );
          },
        );
      },
    );
  }
}
