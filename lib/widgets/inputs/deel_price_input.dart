import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';

import 'package:deelmarkt/widgets/inputs/deel_input.dart';
import 'package:deelmarkt/widgets/inputs/deel_price_formatter.dart';

/// Controller for [DeelPriceInput] that tracks the canonical cents value.
///
/// Always use [valueInCents] to read the price — never parse display text
/// manually. This ensures financial data integrity across locales.
class DeelPriceController extends TextEditingController {
  DeelPriceController({
    this.decimalSeparator = ',',
    this.minCents = 100,
    this.maxCents = 10000000,
  });

  /// Locale-specific decimal separator: `,` for NL, `.` for EN.
  final String decimalSeparator;

  /// Minimum allowed value in cents (default: 100 = €1.00).
  final int minCents;

  /// Maximum allowed value in cents (default: 10000000 = €100,000.00).
  final int maxCents;

  late final formatter = PriceInputFormatter(
    decimalSeparator: decimalSeparator,
  );

  /// Current value as integer cents. Clamped to 0..[maxCents].
  int get valueInCents {
    if (text.isEmpty) return 0;
    final cents = formatter.parseToCents(text) ?? 0;
    return cents.clamp(0, maxCents);
  }

  /// Set the display text from a cents value. Rejects negative values.
  /// Uses [super.text] to bypass the overridden setter — the formatted
  /// string is already canonical so re-formatting is redundant.
  set valueInCents(int cents) {
    assert(cents >= 0, 'cents must be non-negative');
    final clamped = cents.clamp(0, maxCents);
    final euros = clamped ~/ 100;
    final remainder = clamped % 100;
    super.text =
        '$euros$decimalSeparator${remainder.toString().padLeft(2, '0')}';
  }

  /// Sanitises programmatic text assignment through the formatter.
  @override
  set text(String newText) {
    if (newText.isEmpty) {
      super.text = newText;
      return;
    }
    final cleaned = formatter.formatEditUpdate(
      TextEditingValue.empty,
      TextEditingValue(text: newText),
    );
    super.text = cleaned.text;
  }

  /// Whether the current value is within [minCents]..[maxCents].
  /// Uses raw (unclamped) value for accurate bounds checking.
  bool get isWithinBounds {
    if (text.isEmpty) return false;
    final rawCents = formatter.parseToCents(text) ?? 0;
    return rawCents >= minCents && rawCents <= maxCents;
  }
}

/// Price input with EUR prefix, tabular figures, and cents controller.
///
/// Composes [DeelInput] with price-specific behaviour:
/// - EUR prefix styling
/// - [PriceInputFormatter] with 2-decimal hard-cap
/// - [DeelPriceController] with canonical [valueInCents]
/// - Locale-aware decimal separator
///
/// Reference: docs/design-system/components.md §Inputs (Price)
class DeelPriceInput extends StatelessWidget {
  const DeelPriceInput({
    required this.label,
    required this.controller,
    this.hint,
    this.errorText,
    this.onChanged,
    this.validator,
    this.onSaved,
    this.enabled = true,
    this.focusNode,
    super.key,
  });

  final String label;
  final DeelPriceController controller;
  final String? hint;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final bool enabled;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    return DeelInput(
      label: label,
      hint: hint ?? 'input.price_hint'.tr(),
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      maxLength: 10,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      textInputAction: TextInputAction.done,
      inputFormatters: [controller.formatter],
      textStyle: DeelmarktTypography.priceInput,
      prefixIcon: Container(
        padding: const EdgeInsets.only(left: Spacing.s4, right: Spacing.s2),
        alignment: Alignment.centerLeft,
        constraints: const BoxConstraints(maxWidth: 56),
        child: Text(
          'input.price_prefix'.tr(),
          style: DeelmarktTypography.pricePrefix,
        ),
      ),
    );
  }
}
