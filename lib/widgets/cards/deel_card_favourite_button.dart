import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/animation.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

/// Animated favourite toggle button for listing cards.
class DeelCardFavouriteButton extends StatefulWidget {
  const DeelCardFavouriteButton({
    required this.isFavourited,
    required this.onTap,
    super.key,
  });

  final bool isFavourited;
  final VoidCallback onTap;

  @override
  State<DeelCardFavouriteButton> createState() =>
      _DeelCardFavouriteButtonState();
}

class _DeelCardFavouriteButtonState extends State<DeelCardFavouriteButton>
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
