import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';

/// Displays the latest tracking status in a themed card.
class TrackingStatusCard extends StatelessWidget {
  const TrackingStatusCard({
    required this.latestEvent,
    required this.isDark,
    super.key,
  });

  final TrackingEvent? latestEvent;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final statusText = latestEvent?.description ?? 'tracking.noUpdates'.tr();
    final isTerminal = latestEvent?.status.isTerminal == true;
    final statusColor =
        isTerminal
            ? DeelmarktColors.trustVerified
            : isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral700;

    return Semantics(
      label: '${'tracking.latestUpdate'.tr()} $statusText',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: shippingCardDecoration(isDark),
        child: _statusRow(context, statusText, statusColor, isTerminal),
      ),
    );
  }

  Widget _statusRow(
    BuildContext context,
    String statusText,
    Color statusColor,
    bool isTerminal,
  ) {
    return Row(
      children: [
        Icon(
          isTerminal
              ? PhosphorIcons.checkCircle(PhosphorIconsStyle.fill)
              : PhosphorIcons.clockCountdown(),
          color: statusColor,
        ),
        const SizedBox(width: Spacing.s3),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'tracking.latestUpdate'.tr(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color:
                      isDark
                          ? DeelmarktColors.darkOnSurfaceSecondary
                          : DeelmarktColors.neutral500,
                ),
              ),
              const SizedBox(height: Spacing.s1),
              Text(
                statusText,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Shared card decoration for shipping detail cards.
BoxDecoration shippingCardDecoration(bool isDark) {
  return BoxDecoration(
    color:
        isDark
            ? DeelmarktColors.darkSurfaceElevated
            : DeelmarktColors.neutral50,
    borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
    border: Border.all(
      color: isDark ? DeelmarktColors.darkBorder : DeelmarktColors.neutral200,
    ),
  );
}
