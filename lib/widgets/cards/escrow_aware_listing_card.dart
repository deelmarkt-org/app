import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/domain/entities/listing_entity.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/widgets/cards/listing_deel_card.dart';

/// A [listingDeelCard] that reads `listing.isEscrowAvailable` and the
/// Unleash flag [FeatureFlags.listingsEscrowBadge] to decide whether the
/// escrow badge should render.
///
/// Introduced by GH-59 / ADR-023 so the badge is server-authoritative and
/// gated by a progressive rollout flag, without changing the shared
/// [listingDeelCard] signature (which already powers search, favourites
/// and other non-badge surfaces).
///
/// Use this widget anywhere an entity-driven escrow badge is desired;
/// keep [listingDeelCard] for surfaces that either always show the badge,
/// never show it, or derive it from some other source.
///
/// Reference: docs/epics/E03-payments-escrow.md
///            docs/adr/ADR-023-escrow-eligibility-authority.md
class EscrowAwareListingCard extends ConsumerWidget {
  const EscrowAwareListingCard({
    required this.listing,
    required this.onTap,
    required this.onFavouriteTap,
    super.key,
  });

  final ListingEntity listing;
  final VoidCallback onTap;
  final VoidCallback onFavouriteTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Badge visibility requires BOTH:
    //   • The server-authoritative [ListingEntity.isEscrowAvailable] flag
    //     (fail-closed default in the DTO → ADR-023).
    //   • The Unleash flag [FeatureFlags.listingsEscrowBadge] (kill-switch
    //     during the staged rollout).
    final flagOn = ref.watch(
      isFeatureEnabledProvider(FeatureFlags.listingsEscrowBadge),
    );
    return listingDeelCard(
      listing,
      onTap: onTap,
      onFavouriteTap: onFavouriteTap,
      showEscrowBadge: flagOn && listing.isEscrowAvailable,
    );
  }
}
