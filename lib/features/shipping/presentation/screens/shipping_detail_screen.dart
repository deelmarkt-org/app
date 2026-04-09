import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/domain/entities/tracking_event.dart';
import 'package:deelmarkt/features/shipping/presentation/extensions/shipping_carrier_ext.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/shipping_action_buttons.dart';

/// Shipping overview screen — hub linking to QR, tracking, and parcel shops.
///
/// Reference: docs/epics/E05-shipping-logistics.md
class ShippingDetailScreen extends StatelessWidget {
  const ShippingDetailScreen({
    required this.label,
    required this.events,
    super.key,
  });

  final ShippingLabel label;
  final List<TrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: Text('shipping.details'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
          child: ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TrustBanner.escrow(),
                const SizedBox(height: Spacing.s4),
                _carrierCard(context, isDark: isDark),
                const SizedBox(height: Spacing.s4),
                _trackingStatus(context, isDark: isDark),
                const SizedBox(height: Spacing.s6),
                ShippingActionButtons(shippingId: label.id),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _carrierCard(BuildContext context, {required bool isDark}) {
    return Semantics(
      label:
          '${label.carrier.localizedName} ${'shipping.trackingNumber'.tr()} ${label.trackingNumber}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: _cardDecoration(isDark),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.package(PhosphorIconsStyle.fill),
              color:
                  isDark
                      ? DeelmarktColors.darkSecondary
                      : DeelmarktColors.secondary,
            ),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.carrier.localizedName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: Spacing.s1),
                  Text(
                    label.trackingNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 1.2,
                      color:
                          isDark
                              ? DeelmarktColors.darkOnSurfaceSecondary
                              : DeelmarktColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackingStatus(BuildContext context, {required bool isDark}) {
    return _TrackingStatusCard(
      latestEvent: events.isNotEmpty ? events.first : null,
      isDark: isDark,
    );
  }
}

class _TrackingStatusCard extends StatelessWidget {
  const _TrackingStatusCard({required this.latestEvent, required this.isDark});

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
        decoration: _cardDecoration(isDark),
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

BoxDecoration _cardDecoration(bool isDark) {
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
