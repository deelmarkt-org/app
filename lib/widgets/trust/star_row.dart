import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/design_system/colors.dart';

/// A row of 5 star icons representing a rating value.
///
/// Shared widget extracted from [RatingDisplay] and [ReviewCard] to
/// eliminate duplicate `List.generate(5, ...)` star loops (M-2).
///
/// Uses [StarSizes] constants instead of magic numbers (M-4).
class StarRow extends StatelessWidget {
  const StarRow({required this.rating, this.size = StarSizes.small, super.key});

  /// The rating value (0–5). Stars up to `rating.round()` are filled.
  final double rating;

  /// Icon size for each star. Defaults to [StarSizes.small].
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < rating.round();
        return Icon(
          isFilled
              ? PhosphorIcons.star(PhosphorIconsStyle.fill)
              : PhosphorIcons.star(),
          size: size,
          color:
              isFilled ? DeelmarktColors.warning : DeelmarktColors.neutral300,
        );
      }),
    );
  }
}
