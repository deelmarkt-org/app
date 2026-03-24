import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';

import '../../domain/entities/parcel_shop.dart';

/// List item for a parcel shop in the selector.
///
/// Shows: carrier icon, name, address, distance, today's hours.
///
/// Reference: docs/design-system/patterns.md §ParcelShop Selector
class ParcelShopListItem extends StatelessWidget {
  const ParcelShopListItem({
    required this.shop,
    required this.onTap,
    this.isSelected = false,
    super.key,
  });

  final ParcelShop shop;
  final VoidCallback onTap;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isSelected
            ? DeelmarktColors.primary
            : (isDark
                ? DeelmarktColors.darkBorder
                : DeelmarktColors.neutral200);

    return Semantics(
      label:
          '${shop.name}, ${shop.distanceKm.toStringAsFixed(1)} '
          '${'shipping.distanceKm'.tr()}, '
          '${shop.openToday ?? 'shipping.closed'.tr()}',
      button: true,
      selected: isSelected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(Spacing.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DeelmarktRadius.lg),
            border: Border.all(color: borderColor, width: isSelected ? 2 : 1),
            color: isSelected ? DeelmarktColors.primarySurface : null,
          ),
          child: Row(
            children: [
              _carrierIcon(),
              const SizedBox(width: Spacing.s3),
              Expanded(child: _details(context, isDark)),
              _distance(context, isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _carrierIcon() {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            shop.carrier == ParcelShopCarrier.postnl
                ? DeelmarktColors.primarySurface
                : DeelmarktColors.secondarySurface,
      ),
      child: Icon(
        PhosphorIcons.storefront(PhosphorIconsStyle.fill),
        color:
            shop.carrier == ParcelShopCarrier.postnl
                ? DeelmarktColors.primary
                : DeelmarktColors.secondary,
        size: 20,
      ),
    );
  }

  Widget _details(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          shop.name,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: Spacing.s1),
        Text(
          shop.fullAddress,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                isDark
                    ? DeelmarktColors.darkOnSurfaceSecondary
                    : DeelmarktColors.neutral500,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (shop.openToday != null) ...[
          const SizedBox(height: Spacing.s1),
          Row(
            children: [
              Icon(
                PhosphorIcons.clock(),
                size: 12,
                color: DeelmarktColors.success,
              ),
              const SizedBox(width: Spacing.s1),
              Flexible(
                child: Text(
                  'shipping.openUntil'.tr(args: [shop.openToday!]),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: DeelmarktColors.success,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _distance(BuildContext context, bool isDark) {
    return Column(
      children: [
        Text(
          shop.distanceKm.toStringAsFixed(1),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        Text(
          'shipping.distanceKm'.tr(),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color:
                isDark
                    ? DeelmarktColors.darkOnSurfaceSecondary
                    : DeelmarktColors.neutral500,
          ),
        ),
      ],
    );
  }
}
