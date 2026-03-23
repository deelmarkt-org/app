import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

import '../../domain/entities/shipping_label.dart';
import '../../domain/entities/tracking_event.dart';
import '../extensions/shipping_carrier_ext.dart';
import '../widgets/tracking_timeline.dart';

/// Tracking screen showing shipment status for buyer and seller.
///
/// Displays: carrier info, tracking number, vertical timeline, delivery status.
///
/// Reference: docs/epics/E05-shipping-logistics.md
class TrackingScreen extends StatelessWidget {
  const TrackingScreen({required this.label, required this.events, super.key});

  final ShippingLabel label;
  final List<TrackingEvent> events;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('tracking.title'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
          child: ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _carrierHeader(context),
                const SizedBox(height: Spacing.s4),
                _trackingNumberCard(context),
                const SizedBox(height: Spacing.s6),
                _timelineSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _carrierHeader(BuildContext context) {
    return Semantics(
      label: '${label.carrier.localizedName} ${'tracking.shipment'.tr()}',
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            PhosphorIcons.package(PhosphorIconsStyle.fill),
            color: DeelmarktColors.secondary,
          ),
          const SizedBox(width: Spacing.s2),
          Flexible(
            child: Text(
              '${label.carrier.localizedName} ${'tracking.shipment'.tr()}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _trackingNumberCard(BuildContext context) {
    return Semantics(
      label: '${'shipping.trackingNumber'.tr()} ${label.trackingNumber}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: DeelmarktColors.neutral50,
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
          border: Border.all(color: DeelmarktColors.neutral200),
        ),
        child: Row(
          children: [
            Icon(PhosphorIcons.barcode(), color: DeelmarktColors.neutral700),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'shipping.trackingNumber'.tr(),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: DeelmarktColors.neutral500,
                    ),
                  ),
                  const SizedBox(height: Spacing.s1),
                  Text(
                    label.trackingNumber,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      letterSpacing: 1.2,
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

  Widget _timelineSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'tracking.updates'.tr(),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: Spacing.s4),
        if (events.isEmpty)
          _emptyState(context)
        else
          TrackingTimeline(events: events),
      ],
    );
  }

  Widget _emptyState(BuildContext context) {
    return Semantics(
      label: 'tracking.noUpdates'.tr(),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s6),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(
              PhosphorIcons.clockCountdown(),
              size: 48,
              color: DeelmarktColors.neutral300,
            ),
            const SizedBox(height: Spacing.s3),
            Text(
              'tracking.noUpdates'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DeelmarktColors.neutral500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
