import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/icon_sizes.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';

/// DSA Compliance Monitor card with progress bar.
///
/// Visualises the 24-hour SLA compliance rate as a horizontal progress bar
/// with completed/total status text.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class AdminSlaBar extends StatelessWidget {
  const AdminSlaBar({
    required this.progress,
    required this.completed,
    required this.total,
    super.key,
  });

  /// Completion ratio between 0.0 and 1.0.
  final double progress;

  /// Number of items handled within the SLA window.
  final int completed;

  /// Total number of items subject to the SLA.
  final int total;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'admin.sla.a11y'.tr(args: ['$completed', '$total']),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: DeelmarktColors.white,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          border: Border.all(color: DeelmarktColors.neutral200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: Spacing.s4),
            _buildProgressBar(),
            const SizedBox(height: Spacing.s3),
            _buildStatusText(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        const Icon(
          PhosphorIconsRegular.shieldCheck,
          size: DeelmarktIconSize.sm,
          color: DeelmarktColors.primary,
        ),
        const SizedBox(width: Spacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.sla.title'.tr(),
                style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                  fontWeight: FontWeight.w600,
                  color: DeelmarktColors.neutral900,
                ),
              ),
              const SizedBox(height: Spacing.s1),
              Text(
                'admin.sla.subtitle'.tr(),
                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: DeelmarktColors.neutral500,
                ),
              ),
            ],
          ),
        ),
        _buildPercentageLabel(),
      ],
    );
  }

  Widget _buildPercentageLabel() {
    final percentage = (progress * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s2,
        vertical: Spacing.s1,
      ),
      decoration: BoxDecoration(
        color: _progressColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      ),
      child: Text(
        '$percentage%',
        style: DeelmarktTypography.statLabel.copyWith(
          fontWeight: FontWeight.w600,
          color: _progressColor(),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DeelmarktRadius.full),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 8,
        backgroundColor: DeelmarktColors.neutral100,
        valueColor: AlwaysStoppedAnimation(_progressColor()),
      ),
    );
  }

  Widget _buildStatusText(BuildContext context) {
    return Text(
      'admin.sla.status'.tr(args: ['$completed', '$total']),
      style: DeelmarktTypography.statLabel.copyWith(
        color: DeelmarktColors.neutral500,
      ),
    );
  }

  static const double _slaSuccessThreshold = 0.8;
  static const double _slaWarningThreshold = 0.5;

  Color _progressColor() {
    if (progress >= _slaSuccessThreshold) return DeelmarktColors.success;
    if (progress >= _slaWarningThreshold) return DeelmarktColors.primary;
    return DeelmarktColors.error;
  }
}
