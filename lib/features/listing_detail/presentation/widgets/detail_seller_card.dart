import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// Seller card showing avatar, name, badges, rating, and response time.
class DetailSellerCard extends StatelessWidget {
  const DetailSellerCard({
    required this.seller,
    required this.onViewProfile,
    super.key,
  });

  final UserEntity seller;
  final VoidCallback onViewProfile;

  static const double _avatarSize = 48;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: _buildSemanticLabel(),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onViewProfile,
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          child: Container(
            padding: const EdgeInsets.all(Spacing.s4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                _Avatar(url: seller.avatarUrl, name: seller.displayName),
                const SizedBox(width: Spacing.s3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _NameRow(
                        name: seller.displayName,
                        isVerified:
                            seller.kycLevel.index >= KycLevel.level2.index,
                      ),
                      const SizedBox(height: Spacing.s1),
                      _InfoRow(seller: seller),
                    ],
                  ),
                ),
                Icon(
                  PhosphorIcons.caretRight(),
                  size: DeelmarktIconSize.sm,
                  color: DeelmarktColors.neutral500,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _buildSemanticLabel() {
    final parts = <String>['listing.seller'.tr(), seller.displayName];
    if (seller.averageRating != null) {
      parts.add('${seller.averageRating} ${_starsLabel()}');
    }
    if (seller.kycLevel.index >= KycLevel.level2.index) {
      parts.add('listing_detail.verified'.tr());
    }
    return parts.join(', ');
  }

  String _starsLabel() =>
      seller.reviewCount > 0
          ? 'listing_detail.reviews'.tr(
            namedArgs: {'count': '${seller.reviewCount}'},
          )
          : 'listing_detail.noReviews'.tr();
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.url, required this.name});

  final String? url;
  final String name;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: DetailSellerCard._avatarSize / 2,
      backgroundColor: DeelmarktColors.neutral200,
      backgroundImage: url != null ? NetworkImage(url!) : null,
      child:
          url == null
              ? Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: Theme.of(context).textTheme.headlineSmall,
              )
              : null,
    );
  }
}

class _NameRow extends StatelessWidget {
  const _NameRow({required this.name, required this.isVerified});

  final String name;
  final bool isVerified;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Flexible(
          child: Text(
            name,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isVerified) ...[
          const SizedBox(width: Spacing.s1),
          Icon(
            PhosphorIcons.sealCheck(PhosphorIconsStyle.fill),
            size: DeelmarktIconSize.xs,
            color: DeelmarktColors.trustVerified,
          ),
        ],
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.seller});

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
