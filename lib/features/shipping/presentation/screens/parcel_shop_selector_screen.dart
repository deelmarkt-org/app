import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/breakpoints.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/buttons.dart';
import 'package:deelmarkt/widgets/layout/responsive_body.dart';

import 'package:deelmarkt/features/shipping/domain/entities/parcel_shop.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/parcel_shop_detail_panel.dart';
import 'package:deelmarkt/features/shipping/presentation/widgets/parcel_shop_list_item.dart';

/// Screen for selecting a PostNL/DHL service point.
///
/// Responsive layout:
/// - compact (<600px): full-width list with bottom select bar
/// - medium/expanded (≥600px): master-detail — list on left, details on right
///
/// Reference: docs/epics/E05-shipping-logistics.md §ParcelShop Selector
class ParcelShopSelectorScreen extends StatefulWidget {
  const ParcelShopSelectorScreen({required this.shops, super.key});

  final List<ParcelShop> shops;

  @override
  State<ParcelShopSelectorScreen> createState() =>
      _ParcelShopSelectorScreenState();
}

/// Uses StatefulWidget + setState for local selection state.
/// Accepted deviation from §1.3 (Riverpod) — selection is purely
/// ephemeral UI state with no business logic.
class _ParcelShopSelectorScreenState extends State<ParcelShopSelectorScreen> {
  static const double _masterPanelWidth = 380;
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
        SizedBox(width: _masterPanelWidth, child: _buildShopList(context)),
        const VerticalDivider(width: 1),
        Expanded(
          child:
              _selected != null
                  ? ParcelShopDetailPanel(
                    shop: _selected!,
                    onSelect: () => Navigator.of(context).pop(_selected),
                  )
                  : _buildEmptyDetail(context),
        ),
      ],
    );
  }

  Widget _buildShopList(BuildContext context) {
    if (widget.shops.isEmpty) return _buildEmptyState(context);

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
        border: Border(
          top: BorderSide(
            color:
                Theme.of(context).brightness == Brightness.dark
                    ? DeelmarktColors.darkBorder
                    : DeelmarktColors.neutral200,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: DeelButton(
          label: 'shipping.selectThisShop'.tr(),
          leadingIcon: PhosphorIcons.checkCircle(),
          onPressed: () => Navigator.of(context).pop(_selected),
        ),
      ),
    );
  }

  Widget _buildEmptyDetail(BuildContext context) {
    return _buildEmptyPlaceholder(
      context,
      icon: PhosphorIcons.storefront(),
      message: 'shipping.selectFromList'.tr(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return _buildEmptyPlaceholder(
      context,
      icon: PhosphorIcons.mapPinArea(),
      message: 'shipping.noShopsFound'.tr(),
      wrap: (child) => ResponsiveBody(child: child),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildEmptyPlaceholder(
    BuildContext context, {
    required IconData icon,
    required String message,
    Widget Function(Widget child)? wrap,
    TextAlign? textAlign,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral300;
    final textColor =
        isDark
            ? DeelmarktColors.darkOnSurfaceSecondary
            : DeelmarktColors.neutral500;

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 48, color: iconColor),
        const SizedBox(height: Spacing.s3),
        Text(
          message,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: textColor),
          textAlign: textAlign,
        ),
      ],
    );

    return Center(child: wrap != null ? wrap(content) : content);
  }
}
