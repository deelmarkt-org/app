import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/trust_banner.dart';
import 'package:go_router/go_router.dart';

import 'package:deelmarkt/features/shipping/domain/entities/shipping_label.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/shipping_qr_card.dart';

/// Screen displaying shipping QR code for seller to scan at service point.
///
/// Reference: docs/epics/E05-shipping-logistics.md
/// Reference: docs/design-system/patterns.md §Shipping QR Card
class ShippingQrScreen extends StatelessWidget {
  const ShippingQrScreen({required this.label, super.key});

  final ShippingLabel label;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('shipping.sendPackage'.tr())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: Spacing.s4),
          child: ResponsiveBody(
            // Wider than the default form cap — the QR card + instruction
            // card + CTA stack reads cramped at 600px on tablet/desktop.
            // See docs/screens/05-shipping/01-shipping-qr.md §Expanded.
            maxWidth: 800,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const TrustBanner.escrow(),
                const SizedBox(height: Spacing.s4),
                ShippingQrCard(label: label),
                const SizedBox(height: Spacing.s4),
                _instructionCard(context),
                const SizedBox(height: Spacing.s6),
                _findServicePointButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _instructionCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: 'shipping.instructions'.tr(),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color:
              isDark
                  ? DeelmarktColors.darkInfoSurface
                  : DeelmarktColors.infoSurface,
          borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.info(PhosphorIconsStyle.fill),
              color: isDark ? DeelmarktColors.darkInfo : DeelmarktColors.info,
              size: 20,
            ),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Text(
                'shipping.scanAtServicePoint'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color:
                      isDark
                          ? DeelmarktColors.darkOnSurfaceSecondary
                          : DeelmarktColors.neutral700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _findServicePointButton(BuildContext context) {
    return DeelButton(
      label: 'shipping.findServicePoint'.tr(),
      leadingIcon: PhosphorIcons.mapPin(),
      onPressed: () {
        assert(label.id.isNotEmpty, 'ShippingLabel.id must not be empty');
        final route = AppRoutes.parcelShopSelector.replaceFirst(
          ':id',
          label.id,
        );
        assert(
          route != AppRoutes.parcelShopSelector,
          'Route interpolation failed — :id segment not found',
        );
        context.push(route);
      },
    );
  }
}
