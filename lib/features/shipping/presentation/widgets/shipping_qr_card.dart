import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/presentation/extensions/shipping_carrier_ext.dart';

/// Displays a QR code card for label-free shipping at PostNL/DHL.
///
/// Reference: docs/design-system/patterns.md §Shipping QR Card
class ShippingQrCard extends StatelessWidget {
  const ShippingQrCard({required this.label, super.key});

  final ShippingLabel label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label:
          '${'shipping.scanAtServicePoint'.tr()} ${label.carrier.localizedName}',
      child: Container(
        padding: const EdgeInsets.all(Spacing.s6),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color ?? DeelmarktColors.white,
          borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
          border: Border.all(color: DeelmarktColors.neutral200),
        ),
        child: Column(
          children: [
            _carrierBadge(context),
            const SizedBox(height: Spacing.s4),
            _qrCode(context),
            const SizedBox(height: Spacing.s4),
            _trackingInfo(context),
            if (label.shipByDeadline != null) ...[
              const SizedBox(height: Spacing.s3),
              _deadlineInfo(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _carrierBadge(BuildContext context) {
    return Semantics(
      label: label.carrier.localizedName,
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.package(PhosphorIconsStyle.fill),
            color: DeelmarktColors.secondary,
            size: 20,
          ),
          const SizedBox(width: Spacing.s2),
          Text(
            label.carrier.localizedName,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: DeelmarktColors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrCode(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: DeelmarktColors.white,
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
      ),
      child: QrImageView(
        data: label.qrData,
        size: 200,
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: DeelmarktColors.neutral900,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: DeelmarktColors.neutral900,
        ),
        semanticsLabel: 'shipping.qrCode'.tr(),
      ),
    );
  }

  Widget _trackingInfo(BuildContext context) {
    return Semantics(
      label: '${'shipping.trackingNumber'.tr()} ${label.trackingNumber}',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            PhosphorIcons.barcode(),
            size: 16,
            color: DeelmarktColors.neutral500,
          ),
          const SizedBox(width: Spacing.s1),
          Text(
            label.trackingNumber,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: DeelmarktColors.neutral700,
              fontFeatures: const [FontFeature.tabularFigures()],
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _deadlineInfo(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final deadlineText = 'shipping.shipByDeadline'.tr(
      args: [Formatters.shortDateTime(label.shipByDeadline!, locale: locale)],
    );

    return Semantics(
      label: deadlineText,
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.s3,
          vertical: Spacing.s2,
        ),
        decoration: BoxDecoration(
          color: DeelmarktColors.warningSurface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.sm),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.clock(),
              size: 16,
              color: DeelmarktColors.warning,
            ),
            const SizedBox(width: Spacing.s1),
            Text(
              deadlineText,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: DeelmarktColors.neutral700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
