import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';

import '../../domain/entities/parcel_shop.dart';

/// Detail panel for the selected parcel shop (expanded layout).
///
/// Shows: name, full address, distance, opening hours, select button.
class ParcelShopDetailPanel extends StatelessWidget {
  const ParcelShopDetailPanel({
    required this.shop,
    required this.onSelect,
    super.key,
  });

  final ParcelShop shop;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(Spacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            shop.name,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: Spacing.s2),
          _detailRow(context, PhosphorIcons.mapPin(), shop.fullAddress),
          const SizedBox(height: Spacing.s2),
          _detailRow(
            context,
            PhosphorIcons.path(),
            '${shop.distanceKm.toStringAsFixed(1)} ${'shipping.distanceKm'.tr()}',
          ),
          if (shop.openToday != null) ...[
            const SizedBox(height: Spacing.s2),
            _detailRow(
              context,
              PhosphorIcons.clock(),
              '${'shipping.today'.tr()}: ${shop.openToday}',
            ),
          ],
          const SizedBox(height: Spacing.s6),
          DeelButton(
            label: 'shipping.selectThisShop'.tr(),
            leadingIcon: PhosphorIcons.checkCircle(),
            variant: DeelButtonVariant.primary,
            onPressed: onSelect,
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color:
                isDark
                    ? DeelmarktColors.darkOnSurfaceSecondary
                    : DeelmarktColors.neutral500,
          ),
          const SizedBox(width: Spacing.s2),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color:
                    isDark
                        ? DeelmarktColors.darkOnSurface
                        : DeelmarktColors.neutral700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
