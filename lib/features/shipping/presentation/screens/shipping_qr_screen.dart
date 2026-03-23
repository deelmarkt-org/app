import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';
import 'package:deelmarkt/widgets/trust/escrow_trust_banner.dart';

import '../../domain/entities/shipping_label.dart';
import '../widgets/shipping_qr_card.dart';

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const EscrowTrustBanner(),
                const SizedBox(height: Spacing.s4),
                ShippingQrCard(label: label),
                const SizedBox(height: Spacing.s4),
                _instructionCard(context),
                const SizedBox(height: Spacing.s6),
                _findServicePointButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _instructionCard(BuildContext context) {
    return Semantics(
      label: 'shipping.instructions'.tr(),
      child: Container(
        padding: const EdgeInsets.all(Spacing.s4),
        decoration: BoxDecoration(
          color: DeelmarktColors.infoSurface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              PhosphorIcons.info(PhosphorIconsStyle.fill),
              color: DeelmarktColors.info,
              size: 20,
            ),
            const SizedBox(width: Spacing.s3),
            Expanded(
              child: Text(
                'shipping.scanAtServicePoint'.tr(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DeelmarktColors.neutral700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _findServicePointButton() {
    return DeelButton(
      label: 'shipping.findServicePoint'.tr(),
      leadingIcon: PhosphorIcons.mapPin(),
      variant: DeelButtonVariant.primary,
      onPressed: null, // TODO: Wire to ParcelShop selector (B-31)
    );
  }
}
