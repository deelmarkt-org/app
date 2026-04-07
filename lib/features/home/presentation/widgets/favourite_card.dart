import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/domain/entities/listing_entity.dart';
import 'package:deelmarkt/features/home/presentation/favourites_notifier.dart';
import 'package:deelmarkt/widgets/cards/deel_card.dart';

/// A single favourited listing card with unfavourite + SnackBar undo.
class FavouriteCard extends ConsumerWidget {
  const FavouriteCard({required this.listing, super.key});

  final ListingEntity listing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DeelCard.grid(
      imageUrl: listing.imageUrls.isNotEmpty ? listing.imageUrls.first : '',
      priceFormatted: Formatters.euroFromCents(listing.priceInCents),
      title: listing.title,
      isFavourited: true,
      location: listing.location,
      distanceFormatted:
          listing.distanceKm != null
              ? Formatters.distanceKm(listing.distanceKm!)
              : null,
      onTap:
          () => context.push(
            AppRoutes.listingDetail.replaceAll(':id', listing.id),
          ),
      onFavouriteTap: () => _handleRemove(context, ref),
    );
  }

  Future<void> _handleRemove(BuildContext context, WidgetRef ref) async {
    final removed = await ref
        .read(favouritesNotifierProvider.notifier)
        .removeFavourite(listing.id);

    if (removed != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('favourites.removed'.tr()),
          action: SnackBarAction(
            label: 'favourites.undo'.tr(),
            onPressed:
                () => ref
                    .read(favouritesNotifierProvider.notifier)
                    .undoRemove(removed),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
