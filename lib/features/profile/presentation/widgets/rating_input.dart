import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Interactive 5-star rating picker for the P-38 review screen.
///
/// Each star is a 48×48 tappable target (WCAG 2.2 AA ≥44×44).
/// Provides haptic feedback on selection change.
/// Respects [MediaQuery.disableAnimations] for the fill animation.
///
/// Reference: docs/screens/07-profile/04-rating-review.md
class RatingInput extends StatelessWidget {
  const RatingInput({
    required this.value,
    required this.onChanged,
    this.starSize = 48,
    this.readOnly = false,
    super.key,
  });

  /// Current rating value (0.0–5.0, whole stars for MVP).
  final double value;

  /// Called when the user taps a star.
  final ValueChanged<double> onChanged;

  /// Size of each star icon in logical pixels.
  final double starSize;

  /// When true, stars are non-interactive (display only).
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.of(context).disableAnimations;

    return RepaintBoundary(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (index) {
          final starNumber = index + 1;
          final isFilled = starNumber <= value.round();

          return Semantics(
            button: !readOnly,
            enabled: !readOnly,
            label: 'review.a11y.rating'.tr(
              namedArgs: {'star': '$starNumber', 'total': '5'},
            ),
            value: isFilled ? 'selected' : 'unselected',
            child: InkResponse(
              onTap:
                  readOnly
                      ? null
                      : () {
                        if (starNumber.toDouble() != value) {
                          HapticFeedback.selectionClick();
                          onChanged(starNumber.toDouble());
                        }
                      },
              radius: starSize / 2,
              child: SizedBox(
                width: starSize,
                height: starSize,
                child: Center(
                  child: AnimatedSwitcher(
                    duration:
                        reducedMotion
                            ? Duration.zero
                            : const Duration(milliseconds: 200),
                    child: Icon(
                      isFilled
                          ? PhosphorIcons.star(PhosphorIconsStyle.fill)
                          : PhosphorIcons.star(),
                      key: ValueKey('star-$starNumber-$isFilled'),
                      size: starSize * 0.7,
                      color:
                          isFilled
                              ? DeelmarktColors.warning
                              : DeelmarktColors.neutral300,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
