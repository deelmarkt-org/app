import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// Horizontal stats row: sold count, rating, response time.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({required this.user, super.key});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _StatItem(value: '0', label: 'profile.sold'.tr()),
        _StatItem(
          value: user.averageRating?.toStringAsFixed(1) ?? '-',
          label: 'profile.reviews'.tr(),
        ),
        _StatItem(
          value: _formatResponseTime(user.responseTimeMinutes),
          label: 'profile.responseTime'.tr(),
        ),
      ],
    );
  }

  String _formatResponseTime(int? minutes) {
    if (minutes == null) return '-';
    if (minutes < 60) return '${minutes}m';
    return '${(minutes / 60).round()}h';
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$value $label',
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: Spacing.s1),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
