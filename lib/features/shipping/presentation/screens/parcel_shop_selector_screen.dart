import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

import '../../domain/entities/parcel_shop.dart';
import '../widgets/parcel_shop_list_item.dart';

/// Screen for selecting a PostNL/DHL service point.
///
/// Responsive layout:
/// - compact (<600px): full-width list with select button
/// - expanded (≥600px): master-detail — list on left, details on right
///
/// Reference: docs/epics/E05-shipping-logistics.md §ParcelShop Selector
class ParcelShopSelectorScreen extends StatefulWidget {
  const ParcelShopSelectorScreen({required this.shops, super.key});

  final List<ParcelShop> shops;

  @override
  State<ParcelShopSelectorScreen> createState() =>
      _ParcelShopSelectorScreenState();
}

class _ParcelShopSelectorScreenState extends State<ParcelShopSelectorScreen> {
  ParcelShop? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('shipping.selectParcelShop'.tr())),
      body: SafeArea(
        child:
            Breakpoints.isCompact(context)
                ? _buildCompactLayout(context)
                : _buildExpandedLayout(context),
      ),
    );
  }

  Widget _buildCompactLayout(BuildContext context) {
    return Column(
      children: [
        Expanded(child: _buildShopList(context)),
        if (_selected != null) _buildSelectBar(context),
      ],
    );
  }

  Widget _buildExpandedLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: 380, child: _buildShopList(context)),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              _selected != null
                  ? _buildDetailPanel(context, _selected!)
                  : _buildEmptyDetail(context),
        ),
      ],
    );
  }

  Widget _buildShopList(BuildContext context) {
    if (widget.shops.isEmpty) {
      return _buildEmptyState(context);
    }

    return ListView.separated(
      padding: const EdgeInsets.all(Spacing.s4),
      itemCount: widget.shops.length,
      separatorBuilder: (_, _) => const SizedBox(height: Spacing.s3),
      itemBuilder: (context, index) {
        final shop = widget.shops[index];
        return ParcelShopListItem(
          shop: shop,
          isSelected: _selected?.id == shop.id,
          onTap: () => setState(() => _selected = shop),
        );
      },
    );
  }

  Widget _buildSelectBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: const Border(
          top: BorderSide(color: DeelmarktColors.neutral200),
        ),
      ),
      child: SafeArea(
        top: false,
        child: DeelButton(
          label: 'shipping.selectThisShop'.tr(),
          leadingIcon: PhosphorIcons.checkCircle(),
          variant: DeelButtonVariant.primary,
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ),
    );
  }

  Widget _buildDetailPanel(BuildContext context, ParcelShop shop) {
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
            onPressed: () => Navigator.of(context).pop(shop),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, IconData icon, String text) {
    return Semantics(
      label: text,
      excludeSemantics: true,
      child: Row(
        children: [
          Icon(icon, size: 16, color: DeelmarktColors.neutral500),
          const SizedBox(width: Spacing.s2),
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DeelmarktColors.neutral700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyDetail(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            PhosphorIcons.storefront(),
            size: 48,
            color: DeelmarktColors.neutral300,
          ),
          const SizedBox(height: Spacing.s3),
          Text(
            'shipping.selectFromList'.tr(),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: DeelmarktColors.neutral500),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: ResponsiveBody(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              PhosphorIcons.mapPinArea(),
              size: 48,
              color: DeelmarktColors.neutral300,
            ),
            const SizedBox(height: Spacing.s3),
            Text(
              'shipping.noShopsFound'.tr(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DeelmarktColors.neutral500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
