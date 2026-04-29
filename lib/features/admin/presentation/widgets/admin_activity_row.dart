import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';

/// One row of [AdminActivityFeed]: type-mapped icon + localised title/subtitle
/// + relative timestamp.
///
/// Extracted from `admin_activity_feed.dart` (P-55) — kept feature-local under
/// `admin/presentation/widgets/`.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminActivityRow extends StatelessWidget {
  const AdminActivityRow({required this.item, super.key});

  final ActivityItemEntity item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ActivityIcon(type: item.type),
          const SizedBox(width: Spacing.s3),
          Expanded(child: _ActivityContent(item: item)),
        ],
      ),
    );
  }
}

class _ActivityIcon extends StatelessWidget {
  const _ActivityIcon({required this.type});

  final ActivityItemType type;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconData();
    return Container(
      padding: const EdgeInsets.all(Spacing.s2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: DeelmarktIconSize.xs, color: color),
    );
  }

  (IconData, Color) _iconData() {
    return switch (type) {
      ActivityItemType.listingRemoved => (
        PhosphorIconsRegular.trash,
        DeelmarktColors.error,
      ),
      ActivityItemType.userVerified => (
        PhosphorIconsRegular.checkCircle,
        DeelmarktColors.success,
      ),
      ActivityItemType.disputeEscalated => (
        PhosphorIconsRegular.warning,
        DeelmarktColors.warning,
      ),
      ActivityItemType.systemUpdate => (
        PhosphorIconsRegular.gear,
        DeelmarktColors.info,
      ),
    };
  }
}

class _ActivityContent extends StatelessWidget {
  const _ActivityContent({required this.item});

  final ActivityItemEntity item;

  String _titleKey(ActivityItemType type) => switch (type) {
    ActivityItemType.listingRemoved => 'admin.activity.listingRemoved.title',
    ActivityItemType.userVerified => 'admin.activity.userVerified.title',
    ActivityItemType.disputeEscalated =>
      'admin.activity.disputeEscalated.title',
    ActivityItemType.systemUpdate => 'admin.activity.systemUpdate.title',
  };

  String _subtitleKey(ActivityItemType type) => switch (type) {
    ActivityItemType.listingRemoved => 'admin.activity.listingRemoved.subtitle',
    ActivityItemType.userVerified => 'admin.activity.userVerified.subtitle',
    ActivityItemType.disputeEscalated =>
      'admin.activity.disputeEscalated.subtitle',
    ActivityItemType.systemUpdate => 'admin.activity.systemUpdate.subtitle',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titleKey(item.type).tr(namedArgs: item.params),
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: DeelmarktColors.neutral900),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          _subtitleKey(item.type).tr(namedArgs: item.params),
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: DeelmarktColors.neutral500),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          _formatTimestamp(item.timestamp),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: DeelmarktColors.neutral300,
            letterSpacing: 0,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'admin.activity.just_now'.tr();
    if (diff.inMinutes < 60) {
      return 'admin.activity.minutes_ago'.tr(args: ['${diff.inMinutes}']);
    }
    if (diff.inHours < 24) {
      return 'admin.activity.hours_ago'.tr(args: ['${diff.inHours}']);
    }
    return 'admin.activity.days_ago'.tr(args: ['${diff.inDays}']);
  }
}
