import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/review_aggregate.dart';

/// Display widget for aggregate rating data.
///
/// Three variants:
/// - [RatingDisplay.large] — hero display with big number + stars + count
/// - [RatingDisplay.inline] — compact inline with small stars + count
/// - [RatingDisplay.tooFew] — info chip when count < 3 (E06 anti-gaming)
///
/// Reference: docs/screens/07-profile/02-seller-profile.md
class RatingDisplay extends StatelessWidget {
  /// Large hero display for profile header.
  const RatingDisplay.large({required this.aggregate, super.key})
    : _variant = _RatingVariant.large;

  /// Compact inline display for cards and list items.
  const RatingDisplay.inline({required this.aggregate, super.key})
    : _variant = _RatingVariant.inline;

  /// Info chip shown when review count < 3.
  const RatingDisplay.tooFew({required this.aggregate, super.key})
    : _variant = _RatingVariant.tooFew;

  /// Factory that picks variant based on aggregate visibility and requested size.
  factory RatingDisplay.fromAggregate(
    ReviewAggregate aggregate, {
    bool large = true,
    Key? key,
  }) {
    if (!aggregate.isVisible) {
      return RatingDisplay.tooFew(aggregate: aggregate, key: key);
    }
    return large
        ? RatingDisplay.large(aggregate: aggregate, key: key)
        : RatingDisplay.inline(aggregate: aggregate, key: key);
  }

  final ReviewAggregate aggregate;
  final _RatingVariant _variant;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'rating.a11y.summary'.tr(
        namedArgs: {
          'average': aggregate.averageRating.toStringAsFixed(1),
          'count': '${aggregate.totalCount}',
        },
      ),
      child: switch (_variant) {
        _RatingVariant.large => _buildLarge(context),
        _RatingVariant.inline => _buildInline(context),
        _RatingVariant.tooFew => _buildTooFew(context),
      },
    );
  }

  Widget _buildLarge(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final formatted = NumberFormat(
      '#.#',
      locale,
    ).format(aggregate.averageRating);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatted,
          style: Theme.of(
            context,
          ).textTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(width: Spacing.s2),
        _buildStars(size: 24),
        const SizedBox(width: Spacing.s2),
        Text(
          'seller_profile.review_count'.tr(
            namedArgs: {'count': '${aggregate.totalCount}'},
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildInline(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildStars(size: 14),
        const SizedBox(width: Spacing.s1),
        Text(
          '(${aggregate.totalCount})',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildTooFew(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s3,
        vertical: Spacing.s2,
      ),
      decoration: BoxDecoration(
        color: DeelmarktColors.infoSurface,
        borderRadius: BorderRadius.circular(Spacing.s2),
      ),
      child: Text(
        'seller_profile.too_few_reviews'.tr(),
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.info),
      ),
    );
  }

  Widget _buildStars({required double size}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final isFilled = index < aggregate.averageRating.round();
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

enum _RatingVariant { large, inline, tooFew }
