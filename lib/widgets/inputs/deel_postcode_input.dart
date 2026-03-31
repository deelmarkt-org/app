import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/widgets/inputs/deel_input.dart';
import 'package:deelmarkt/widgets/inputs/deel_postcode_formatter.dart';

/// Dutch postcode input with format enforcement and validation callback.
///
/// Composes [DeelInput] with postcode-specific behaviour:
/// - [PostcodeInputFormatter] for `[1-9]\d{3} [A-Z]{2}` format
/// - Auto-uppercase, auto-space after 4 digits
/// - [onValidPostcode] fires only for valid Dutch postcodes
/// - Excludes forbidden letter pairs (SA, SD, SS)
///
/// Reference: docs/design-system/patterns.md §Dutch Address Input
class DeelPostcodeInput extends StatelessWidget {
  const DeelPostcodeInput({
    required this.label,
    this.hint,
    this.errorText,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onValidPostcode,
    this.validator,
    this.onSaved,
    this.enabled = true,
    super.key,
  });

  final String label;
  final String? hint;
  final String? errorText;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// Fires only when the input matches a valid Dutch postcode pattern.
  /// Use this to trigger address auto-fill (city + street lookup).
  final ValueChanged<String>? onValidPostcode;

  final FormFieldValidator<String>? validator;
  final FormFieldSetter<String>? onSaved;
  final bool enabled;

  void _handleChanged(String value) {
    onChanged?.call(value);
    if (PostcodeInputFormatter.isValid(value)) {
      onValidPostcode?.call(value.toUpperCase().trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return DeelInput(
      label: label,
      hint: hint ?? 'input.postcode_hint'.tr(),
      errorText: errorText,
      controller: controller,
      focusNode: focusNode,
      onChanged: _handleChanged,
      validator: validator,
      onSaved: onSaved,
      enabled: enabled,
      textCapitalization: TextCapitalization.characters,
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.postalCode],
      inputFormatters: const [PostcodeInputFormatter()],
    );
  }
}
