import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/utils/formatters.dart';

import 'package:deelmarkt/features/transaction/domain/entities/transaction_entity.dart';

/// Displays item price, platform fee, shipping, and total.
class AmountSection extends StatelessWidget {
  const AmountSection({required this.transaction, super.key});

  final TransactionEntity transaction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.s4),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ?? DeelmarktColors.white,
        borderRadius: BorderRadius.circular(DeelmarktRadius.xl),
        border: Border.all(color: DeelmarktColors.neutral200),
      ),
      child: Column(
        children: [
          _row(
            context,
            'payment.itemPrice'.tr(),
            Formatters.euroFromCents(transaction.itemAmountCents),
          ),
          const SizedBox(height: Spacing.s2),
          _row(
            context,
            'payment.platformFee'.tr(),
            Formatters.euroFromCents(transaction.platformFeeCents),
          ),
          const SizedBox(height: Spacing.s2),
          _row(
            context,
            'payment.shippingCost'.tr(),
            Formatters.euroFromCents(transaction.shippingCostCents),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: Spacing.s2),
            child: Divider(),
          ),
          _row(
            context,
            'payment.total'.tr(),
            Formatters.euroFromCents(transaction.totalAmountCents),
            isBold: true,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String amount, {
    bool isBold = false,
  }) {
    return Semantics(
      label: '$label $amount',
      excludeSemantics: true,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
          Text(
            amount,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: isBold ? FontWeight.bold : null,
            ),
          ),
        ],
      ),
    );
  }
}
