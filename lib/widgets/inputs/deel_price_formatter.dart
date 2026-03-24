import 'package:flutter/services.dart';

/// Price input formatter for EUR amounts.
///
/// Allows digits and a single decimal separator. Hard-caps at 2 decimal
/// places. Gracefully handles paste of formatted amounts.
///
/// Reference: docs/design-system/components.md §Inputs (Price)
class PriceInputFormatter extends TextInputFormatter {
  PriceInputFormatter({this.decimalSeparator = ','})
    : _allowedChars = RegExp('[0-9${RegExp.escape(decimalSeparator)}]');

  /// Locale-specific decimal separator: `,` for NL, `.` for EN.
  final String decimalSeparator;

  /// Pre-compiled regex for allowed characters (Fix: avoid per-keystroke allocation).
  final RegExp _allowedChars;

  static final _eurPattern = RegExp(r'[Ee][Uu][Rr]');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;

    // Strip everything except digits and the decimal separator.
    final cleaned = _clean(raw);
    if (cleaned.isEmpty) return oldValue;

    // Enforce single decimal separator + max 2 decimal digits.
    final parts = cleaned.split(decimalSeparator);
    if (parts.length > 2) return oldValue;

    final wholePart = parts[0];
    if (wholePart.isEmpty && parts.length == 1) return oldValue;

    // Block leading zeros (allow "0," for sub-euro amounts).
    if (wholePart.length > 1 && wholePart.startsWith('0')) {
      return oldValue;
    }

    if (parts.length == 2) {
      // Hard-cap: max 2 decimal digits.
      if (parts[1].length > 2) return oldValue;
    }

    // Preserve cursor position relative to surviving characters.
    final cursorPos = newValue.selection.baseOffset.clamp(0, raw.length);
    final cleanedBeforeCursor = _clean(raw.substring(0, cursorPos));
    final newCursorPos = cleanedBeforeCursor.length.clamp(0, cleaned.length);

    return TextEditingValue(
      text: cleaned,
      selection: TextSelection.collapsed(offset: newCursorPos),
    );
  }

  String _clean(String input) {
    var s = input;

    // Strip common paste artefacts: "EUR", "€", spaces, thousands seps.
    s = s.replaceAll(_eurPattern, '');
    s = s.replaceAll('€', '');
    s = s.replaceAll(' ', '');

    // Normalise: if separator is comma, strip dots (thousands); vice versa.
    if (decimalSeparator == ',') {
      s = s.replaceAll('.', '');
    } else {
      s = s.replaceAll(',', '');
    }

    // Keep only digits and the decimal separator.
    final buffer = StringBuffer();
    for (final char in s.split('')) {
      if (_allowedChars.hasMatch(char)) buffer.write(char);
    }

    return buffer.toString();
  }

  /// Parse a display string to cents (integer). Returns `null` on failure.
  ///
  /// Uses integer-only arithmetic to avoid IEEE 754 floating-point errors.
  /// Example: `'45,50'` → `4550` cents.
  int? parseToCents(String displayText) {
    if (displayText.isEmpty) return 0;

    final parts = displayText.split(decimalSeparator);
    if (parts.length > 2) return null;
    final whole = int.tryParse(parts[0].isEmpty ? '0' : parts[0]);
    if (whole == null) return null;
    if (parts.length == 1) return whole * 100;

    // Reject 3+ decimal digits for financial precision.
    if (parts[1].length > 2) return null;
    final fracStr = parts[1].padRight(2, '0').substring(0, 2);
    final frac = int.tryParse(fracStr);
    if (frac == null) return null;

    return whole * 100 + frac;
  }
}
