import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';

/// Recent activity feed list for the admin dashboard.
///
/// Each row shows an icon (mapped from [ActivityItemType]), a localised title
/// and subtitle (built from `admin.activity.<type>.title/subtitle` l10n keys
/// with `item.params` as named arguments), and a human-readable timestamp.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminActivityFeed extends StatelessWidget {
  const AdminActivityFeed({required this.items, super.key});

  /// Activity items to render, ordered newest-first.
  final List<ActivityItemEntity> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: DeelmarktColors.white,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: DeelmarktColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(context),
          const SizedBox(height: Spacing.s3),
          ...items.map(_buildActivityRow),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'admin.activity.title'.tr(),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: DeelmarktColors.neutral900,
          ),
        ),
        Semantics(
          label: 'admin.activity.view_all'.tr(),
          button: true,
          child: GestureDetector(
            onTap: () {},
            child: Text(
              'admin.activity.view_all'.tr(),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: DeelmarktColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivityRow(ActivityItemEntity item) {
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

/// Maps [ActivityItemType] to a Phosphor icon and colour.
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
      child: Icon(icon, size: 16, color: color),
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

/// Title, subtitle, and timestamp for a single activity item.
///
/// Display strings are built from the activity [type] and [params] map via
/// `.tr(namedArgs:)` so all user-visible text is properly localised.
class _ActivityContent extends StatelessWidget {
  const _ActivityContent({required this.item});

  final ActivityItemEntity item;

  /// Returns the l10n key for the primary (title) line of an activity item.
  String _titleKey(ActivityItemType type) {
    return switch (type) {
      ActivityItemType.listingRemoved => 'admin.activity.listingRemoved.title',
      ActivityItemType.userVerified => 'admin.activity.userVerified.title',
      ActivityItemType.disputeEscalated =>
        'admin.activity.disputeEscalated.title',
      ActivityItemType.systemUpdate => 'admin.activity.systemUpdate.title',
    };
  }

  /// Returns the l10n key for the secondary (subtitle) line of an activity item.
  String _subtitleKey(ActivityItemType type) {
    return switch (type) {
      ActivityItemType.listingRemoved =>
        'admin.activity.listingRemoved.subtitle',
      ActivityItemType.userVerified => 'admin.activity.userVerified.subtitle',
      ActivityItemType.disputeEscalated =>
        'admin.activity.disputeEscalated.subtitle',
      ActivityItemType.systemUpdate => 'admin.activity.systemUpdate.subtitle',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _titleKey(item.type).tr(namedArgs: item.params),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: DeelmarktColors.neutral900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          _subtitleKey(item.type).tr(namedArgs: item.params),
          style: const TextStyle(
            fontSize: 12,
            color: DeelmarktColors.neutral500,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          _formatTimestamp(item.timestamp),
          style: const TextStyle(
            fontSize: 11,
            color: DeelmarktColors.neutral300,
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final diff = now.difference(timestamp);
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
