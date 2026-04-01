import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// Rating stars + review count + response time row for seller card.
class SellerInfoRow extends StatelessWidget {
  const SellerInfoRow({required this.seller, super.key});

  final UserEntity seller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final parts = <Widget>[];

    if (seller.averageRating != null) {
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.star(PhosphorIconsStyle.fill),
              size: DeelmarktIconSize.xs,
              color: DeelmarktColors.warning,
            ),
            const SizedBox(width: 2),
            Text(
              seller.averageRating!.toStringAsFixed(1),
              style: theme.textTheme.bodySmall,
            ),
            if (seller.reviewCount > 0)
              Text(
                ' (${seller.reviewCount})',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: DeelmarktColors.neutral500,
                ),
              ),
          ],
        ),
      );
    }

    if (seller.responseTimeMinutes != null) {
      if (parts.isNotEmpty) {
        parts.add(
          Text(
            ' · ',
            style: theme.textTheme.bodySmall?.copyWith(
              color: DeelmarktColors.neutral500,
            ),
          ),
        );
      }
      parts.add(
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.clock(),
              size: DeelmarktIconSize.xs,
              color: DeelmarktColors.neutral500,
            ),
            const SizedBox(width: 2),
            Text(
              _formatResponseTime(seller.responseTimeMinutes!),
              style: theme.textTheme.bodySmall?.copyWith(
                color: DeelmarktColors.neutral500,
              ),
            ),
          ],
        ),
      );
    }

    if (parts.isEmpty) return const SizedBox.shrink();

    return Row(mainAxisSize: MainAxisSize.min, children: parts);
  }

  String _formatResponseTime(int minutes) {
    final String timeStr;
    if (minutes >= 60) {
      final hours = (minutes / 60).round();
      timeStr = 'listing_detail.respondsWithinHours'.tr(
        namedArgs: {'count': '$hours'},
      );
    } else {
      timeStr = 'listing_detail.respondsWithinMinutes'.tr(
        namedArgs: {'count': '$minutes'},
      );
    }
    return 'listing_detail.respondsWithin'.tr(namedArgs: {'time': timeStr});
  }
}
