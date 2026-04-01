import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/badges/deel_badge.dart';
import 'package:deelmarkt/widgets/badges/deel_badge_data.dart';
import 'package:deelmarkt/widgets/cards/deel_card_image.dart';
import 'package:deelmarkt/widgets/cards/deel_card_skeleton.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

/// Listing card with grid and list variants.
///
/// Features: image with Hero, favourite toggle with bounce animation,
/// optional escrow badge, price-first layout.
///
/// Reference: docs/design-system/components.md §Listing Card
class DeelCard extends StatelessWidget {
  /// Grid variant: 4:3 image on top, details below.
  const DeelCard.grid({
    required this.imageUrl,
    required this.priceFormatted,
    required this.title,
    required this.onTap,
    this.heroTag,
    this.location,
    this.distanceFormatted,
    this.isFavourited = false,
    this.onFavouriteTap,
    this.showEscrowBadge = false,
    super.key,
  }) : _variant = DeelCardVariant.grid;

  /// List variant: 1:1 thumbnail left, details right.
  const DeelCard.list({
    required this.imageUrl,
    required this.priceFormatted,
    required this.title,
    required this.onTap,
    this.heroTag,
    this.location,
    this.distanceFormatted,
    this.isFavourited = false,
    this.onFavouriteTap,
    this.showEscrowBadge = false,
    super.key,
  }) : _variant = DeelCardVariant.list;

  final String imageUrl;
  final String priceFormatted;
  final String title;
  final VoidCallback onTap;
  final String? heroTag;
  final String? location;
  final String? distanceFormatted;
  final bool isFavourited;
  final VoidCallback? onFavouriteTap;
  final bool showEscrowBadge;
  final DeelCardVariant _variant;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$priceFormatted, $title',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DeelCardTokens.borderRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            color: Theme.of(context).colorScheme.surface,
          ),
          child:
              _variant == DeelCardVariant.grid
                  ? _buildGrid(context)
                  : _buildList(context),
        ),
      ),
    );
  }

  Widget _buildGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            DeelCardImage(
              imageUrl: imageUrl,
              aspectRatio:
                  DeelCardTokens.gridImageAspectWidth /
                  DeelCardTokens.gridImageAspectHeight,
              heroTag: heroTag,
            ),
            if (showEscrowBadge)
              const Positioned(
                top: DeelCardTokens.badgeTopOffset,
                right: DeelCardTokens.badgeRightOffset,
                child: DeelBadge(
                  type: DeelBadgeType.escrowProtected,
                  size: DeelBadgeSize.small,
                  showTooltip: false,
                ),
              ),
            if (onFavouriteTap != null)
              Positioned(
                top: DeelCardTokens.badgeTopOffset,
                left: DeelCardTokens.badgeRightOffset,
                child: _FavouriteButton(
                  isFavourited: isFavourited,
                  onTap: onFavouriteTap!,
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(Spacing.s3),
          child: _buildDetails(context),
        ),
      ],
    );
  }

  Widget _buildList(BuildContext context) {
    return SizedBox(
      height: DeelCardTokens.listThumbnailSize,
      child: Row(
        children: [
          SizedBox(
            width: DeelCardTokens.listThumbnailSize,
            height: DeelCardTokens.listThumbnailSize,
            child: DeelCardImage(
              imageUrl: imageUrl,
              aspectRatio: 1,
              heroTag: heroTag,
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(DeelmarktRadius.xl),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(Spacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [_buildDetails(context)],
              ),
            ),
          ),
          if (onFavouriteTap != null)
            Padding(
              padding: const EdgeInsets.only(right: Spacing.s2),
              child: _FavouriteButton(
                isFavourited: isFavourited,
                onTap: onFavouriteTap!,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetails(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          priceFormatted,
          style: theme.titleSmall?.copyWith(
            fontSize: DeelCardTokens.priceFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          title,
          style: theme.bodyMedium,
          maxLines: DeelCardTokens.titleMaxLines,
          overflow: TextOverflow.ellipsis,
        ),
        if (location != null || distanceFormatted != null) ...[
          const SizedBox(height: Spacing.s1),
          Text(
            [location, distanceFormatted].whereType<String>().join(' · '),
            style: theme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

/// Animated favourite toggle button.
class _FavouriteButton extends StatefulWidget {
  const _FavouriteButton({required this.isFavourited, required this.onTap});

  final bool isFavourited;
  final VoidCallback onTap;

  @override
  State<_FavouriteButton> createState() => _FavouriteButtonState();
}

class _FavouriteButtonState extends State<_FavouriteButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DeelmarktAnimation.standard,
    );
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: DeelmarktAnimation.curveBounce,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    if (!reduceMotion) {
      _controller.forward(from: 0);
    }
    HapticFeedback.lightImpact();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      toggled: widget.isFavourited,
      label:
          widget.isFavourited
              ? 'listing_card.removeFavourite'.tr()
              : 'listing_card.addFavourite'.tr(),
      child: GestureDetector(
        onTap: _handleTap,
        child: Container(
          width: DeelCardTokens.favouriteTapTarget,
          height: DeelCardTokens.favouriteTapTarget,
          color: Colors.transparent,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Icon(
                widget.isFavourited
                    ? PhosphorIcons.heart(PhosphorIconsStyle.fill)
                    : PhosphorIcons.heart(),
                size: DeelCardTokens.favouriteIconSize,
                color:
                    widget.isFavourited
                        ? DeelmarktColors.error
                        : DeelmarktColors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
