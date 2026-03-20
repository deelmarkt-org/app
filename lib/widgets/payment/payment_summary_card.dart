import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import '../buttons/buttons.dart';
import '../trust/escrow_trust_banner.dart';

/// Payment summary card shown before checkout.
///
/// Displays: item price, platform fee, shipping, total.
/// Includes escrow trust banner and iDEAL pay button.
///
/// Reference: docs/design-system/patterns.md §Payment Summary
class PaymentSummaryCard extends StatelessWidget {
  const PaymentSummaryCard({
    required this.itemName,
    required this.itemAmountCents,
    required this.platformFeeCents,
    required this.shippingCostCents,
    required this.onPayPressed,
    this.isLoading = false,
    super.key,
  });

  final String itemName;
  final int itemAmountCents;
  final int platformFeeCents;
  final int shippingCostCents;
  final VoidCallback? onPayPressed;
  final bool isLoading;

  int get _totalCents => itemAmountCents + platformFeeCents + shippingCostCents;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? DeelmarktColors.white,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: DeelmarktColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(Spacing.s4),
            child: Text(
              'payment.orderSummary'.tr(),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),

          // Line items
          _LineItem(label: itemName, amountCents: itemAmountCents),
          _LineItem(
            label: 'payment.platformFee'.tr(),
            amountCents: platformFeeCents,
          ),
          _LineItem(
            label: 'payment.shippingCost'.tr(),
            amountCents: shippingCostCents,
          ),

          // Divider
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.s4),
            child: Divider(),
          ),

          // Total
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.s4,
              vertical: Spacing.s2,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'payment.total'.tr(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Formatters.euroFromCents(_totalCents),
                      style: DeelmarktTypography.price,
                    ),
                    Text(
                      'payment.inclBtw'.tr(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: DeelmarktColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: Spacing.s2),

          // Escrow trust banner
          const EscrowTrustBanner(),

          const SizedBox(height: Spacing.s4),

          // Pay button
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.s4,
              0,
              Spacing.s4,
              Spacing.s4,
            ),
            child: DeelButton(
              label: 'payment.payWithIdeal'.tr(),
              leadingIcon: PhosphorIcons.bank(),
              onPressed: onPayPressed,
              isLoading: isLoading,
              loadingLabel: 'payment.processing'.tr(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineItem extends StatelessWidget {
  const _LineItem({required this.label, required this.amountCents});

  final String label;
  final int amountCents;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.s4,
        vertical: Spacing.s1,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            Formatters.euroFromCents(amountCents),
            style: DeelmarktTypography.priceSm,
          ),
        ],
      ),
    );
  }
}
