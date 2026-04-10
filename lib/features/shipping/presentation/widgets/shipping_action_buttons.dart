import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/router/routes.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

/// Navigation buttons for shipping detail: QR code, tracking, service point.
class ShippingActionButtons extends StatelessWidget {
  const ShippingActionButtons({required this.shippingId, super.key});

  final String shippingId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DeelButton(
          label: 'shipping.viewQrCode'.tr(),
          leadingIcon: PhosphorIcons.qrCode(),
          onPressed: () {
            final route = AppRoutes.shippingQr.replaceFirst(':id', shippingId);
            context.push(route);
          },
        ),
        const SizedBox(height: Spacing.s3),
        DeelButton(
          label: 'tracking.viewTracking'.tr(),
          leadingIcon: PhosphorIcons.path(),
          variant: DeelButtonVariant.secondary,
          onPressed: () {
            final route = AppRoutes.shippingTracking.replaceFirst(
              ':id',
              shippingId,
            );
            context.push(route);
          },
        ),
        const SizedBox(height: Spacing.s3),
        DeelButton(
          label: 'shipping.findServicePoint'.tr(),
          leadingIcon: PhosphorIcons.mapPin(),
          variant: DeelButtonVariant.secondary,
          onPressed: () {
            final route = AppRoutes.parcelShopSelector.replaceFirst(
              ':id',
              shippingId,
            );
            context.push(route);
          },
        ),
      ],
    );
  }
}
