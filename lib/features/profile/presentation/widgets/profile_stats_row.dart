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
          value: _formatResponseTimeValue(user.responseTimeMinutes),
          label: _formatResponseTimeLabel(user.responseTimeMinutes),
        ),
      ],
    );
  }

  /// Short value shown in large text (e.g. "< 1h", "< 4h").
  String _formatResponseTimeValue(int? minutes) {
    if (minutes == null) return '-';
    if (minutes < 60) return '< 1h';
    if (minutes < 240) return '< 4h';
    if (minutes < 1440) return '< 24h';
    return '> 24h';
  }

  /// Descriptive label shown in small text below the value.
  /// Uses l10n bucket strings consistent with SellerInfoRow and the E04 spec.
  String _formatResponseTimeLabel(int? minutes) {
    if (minutes == null) {
      return 'seller_profile.response_time.unknown'.tr();
    }
    if (minutes < 60) return 'seller_profile.response_time.under_1h'.tr();
    if (minutes < 240) return 'seller_profile.response_time.under_4h'.tr();
    if (minutes < 1440) return 'seller_profile.response_time.under_24h'.tr();
    return 'seller_profile.response_time.over_24h'.tr();
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
