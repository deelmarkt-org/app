import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/response_time_formatter.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';

/// Horizontal stats row: sold count, rating, response time.
class ProfileStatsRow extends StatelessWidget {
  const ProfileStatsRow({required this.user, super.key});

  final UserEntity user;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatItem(value: '0', label: 'profile.sold'.tr())),
        Expanded(
          child: _StatItem(
            value: user.averageRating?.toStringAsFixed(1) ?? '-',
            label: 'profile.reviews'.tr(),
          ),
        ),
        Expanded(
          child: _StatItem(
            value: formatResponseTimeShort(user.responseTimeMinutes),
            label: formatResponseTimeLabel(user.responseTimeMinutes),
          ),
        ),
      ],
    );
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
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Spacing.s1),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
