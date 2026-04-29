import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/domain/entities/user_entity.dart';

/// Rating stars + review count + response time row for seller card.
class SellerInfoRow extends StatelessWidget {
  const SellerInfoRow({required this.seller, super.key});

  static const _countKey = 'count';

  final UserEntity seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final secondaryColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;
    final starColor =
        isDark ? DeelmarktColors.darkWarning : DeelmarktColors.warning;
    final parts = <Widget>[];

    if (seller.averageRating != null) {
      parts.add(
        _RatingPart(
          rating: seller.averageRating!,
          reviewCount: seller.reviewCount,
          starColor: starColor,
          secondaryColor: secondaryColor,
        ),
      );
    }

    if (seller.responseTimeMinutes != null) {
      if (parts.isNotEmpty) {
        parts.add(
          Text(
            ' · ',
            style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
        );
      }
      // Flexible so the response-time text shrinks/ellipsizes when the seller
      // card is in a narrow column (e.g. iPad expanded-layout right rail).
      parts.add(
        Flexible(
          child: _ResponseTimePart(
            label: _formatResponseTime(seller.responseTimeMinutes!),
            color: secondaryColor,
          ),
        ),
      );
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Semantics(
      label: _semanticLabel(),
      child: Row(mainAxisSize: MainAxisSize.min, children: parts),
    );
  }

  String _semanticLabel() {
    final parts = <String>[];
    if (seller.averageRating != null) {
      parts.add(seller.averageRating!.toStringAsFixed(1));
      if (seller.reviewCount > 0) {
        parts.add(
          'listing_detail.reviews'.tr(
            namedArgs: {_countKey: '${seller.reviewCount}'},
          ),
        );
      }
    }
    if (seller.responseTimeMinutes != null) {
      parts.add(_formatResponseTime(seller.responseTimeMinutes!));
    }
    return parts.join(', ');
  }

  String _formatResponseTime(int minutes) {
    final String timeStr;
    if (minutes >= 60) {
      final hours = (minutes / 60).round();
      timeStr = 'listing_detail.respondsWithinHours'.tr(
        namedArgs: {_countKey: '$hours'},
      );
    } else {
      timeStr = 'listing_detail.respondsWithinMinutes'.tr(
        namedArgs: {_countKey: '$minutes'},
      );
    }
    return 'listing_detail.respondsWithin'.tr(namedArgs: {'time': timeStr});
  }
}

class _RatingPart extends StatelessWidget {
  const _RatingPart({
    required this.rating,
    required this.reviewCount,
    required this.starColor,
    required this.secondaryColor,
  });

  final double rating;
  final int reviewCount;
  final Color starColor;
  final Color secondaryColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          PhosphorIcons.star(PhosphorIconsStyle.fill),
          size: DeelmarktIconSize.xs,
          color: starColor,
        ),
        const SizedBox(width: 2),
        Text(rating.toStringAsFixed(1), style: theme.textTheme.bodySmall),
        if (reviewCount > 0)
          Text(
            ' ($reviewCount)',
            style: theme.textTheme.bodySmall?.copyWith(color: secondaryColor),
          ),
      ],
    );
  }
}

class _ResponseTimePart extends StatelessWidget {
  const _ResponseTimePart({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(PhosphorIcons.clock(), size: DeelmarktIconSize.xs, color: color),
        const SizedBox(width: 2),
        Flexible(
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
