import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/sell/domain/entities/listing_creation_state.dart';

/// Shipping carrier toggle + weight range dropdown.
///
/// Two sections:
/// 1. PostNL / DHL segmented button
/// 2. Weight range dropdown (0-2 kg through 23-31.5 kg)
class ShippingSelector extends StatelessWidget {
  const ShippingSelector({
    required this.carrier,
    required this.weightRange,
    required this.onCarrierChanged,
    required this.onWeightRangeChanged,
    super.key,
  });

  final ShippingCarrier carrier;
  final WeightRange? weightRange;
  final void Function(ShippingCarrier) onCarrierChanged;
  final void Function(WeightRange?) onWeightRangeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'sell.shipping'.tr(),
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: Spacing.s2),

        // Carrier toggle.
        SegmentedButton<ShippingCarrier>(
          segments: [
            ButtonSegment(
              value: ShippingCarrier.postnl,
              label: Text('sell.postnl'.tr()),
            ),
            ButtonSegment(
              value: ShippingCarrier.dhl,
              label: Text('sell.dhl'.tr()),
            ),
          ],
          selected: {
            carrier == ShippingCarrier.none ? ShippingCarrier.postnl : carrier,
          },
          onSelectionChanged: (s) => onCarrierChanged(s.first),
        ),
        const SizedBox(height: Spacing.s3),

        // Weight range dropdown.
        DropdownButtonFormField<WeightRange>(
          initialValue: weightRange,
          decoration: InputDecoration(labelText: 'sell.weightRange'.tr()),
          items:
              WeightRange.values
                  .map((w) => DropdownMenuItem(value: w, child: Text(w.label)))
                  .toList(),
          onChanged: onWeightRangeChanged,
        ),
      ],
    );
  }
}
