import 'package:flutter/services.dart';

/// Price input formatter for EUR amounts.
///
/// Allows digits and a single decimal separator. Hard-caps at 2 decimal
/// places. Gracefully handles paste of formatted amounts.
///
/// Reference: docs/design-system/components.md §Inputs (Price)
class PriceInputFormatter extends TextInputFormatter {
  const PriceInputFormatter({this.decimalSeparator = ','});

  /// Locale-specific decimal separator: `,` for NL, `.` for EN.
  final String decimalSeparator;

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
    s = s.replaceAll(RegExp(r'[Ee][Uu][Rr]'), '');
    s = s.replaceAll('€', '');
    s = s.replaceAll(' ', '');

    // Normalise: if separator is comma, strip dots (thousands); vice versa.
    if (decimalSeparator == ',') {
      s = s.replaceAll('.', '');
    } else {
      s = s.replaceAll(',', '');
    }

    // Keep only digits and the decimal separator.
    final allowed = RegExp('[0-9${RegExp.escape(decimalSeparator)}]');
    final buffer = StringBuffer();
    for (final char in s.split('')) {
      if (allowed.hasMatch(char)) buffer.write(char);
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

/// Dutch postcode formatter: `[1-9]\d{3} [A-Z]{2}`.
///
/// Auto-inserts space after 4 digits, uppercases letters, and enforces
/// forbidden letter pairs (SA, SD, SS).
///
/// Reference: docs/design-system/patterns.md §Dutch Address Input
class PostcodeInputFormatter extends TextInputFormatter {
  const PostcodeInputFormatter();

  static final _validPostcode = RegExp(
    r'^[1-9][0-9]{3}\s?(?!SA|SD|SS)[A-Z]{2}$',
  );
  static final _digit19 = RegExp(r'[1-9]');
  static final _digit09 = RegExp(r'[0-9]');
  static final _letterAZ = RegExp(r'[A-Z]');

  /// Whether [value] is a complete, valid Dutch postcode.
  static bool isValid(String value) =>
      _validPostcode.hasMatch(value.toUpperCase().trim());

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.toUpperCase();
    if (raw.isEmpty) return newValue.copyWith(text: '');

    final cursorPos = newValue.selection.baseOffset.clamp(0, raw.length);
    final buffer = StringBuffer();
    var newCursorOffset = 0;
    var cursorSet = false;

    for (var i = 0; i < raw.length; i++) {
      final char = raw[i];

      // Track cursor: when we've consumed chars up to the original cursor,
      // record the current buffer position.
      if (!cursorSet && i >= cursorPos) {
        newCursorOffset = buffer.length;
        cursorSet = true;
      }

      // Position 0: must be 1-9.
      if (buffer.length == 0) {
        if (!_digit19.hasMatch(char)) continue;
        buffer.write(char);
        continue;
      }

      // Positions 1-3: digits only.
      if (buffer.length >= 1 && buffer.length <= 3) {
        if (!_digit09.hasMatch(char)) continue;
        buffer.write(char);
        // Auto-insert space after 4th digit.
        if (buffer.length == 4) {
          buffer.write(' ');
        }
        continue;
      }

      // Position 4 in buffer is the space — skip input spaces.
      if (buffer.length == 4 && char == ' ') continue;

      // Positions 5-6 (after space): letters only.
      if (buffer.length >= 5 && buffer.length <= 6) {
        if (!_letterAZ.hasMatch(char)) continue;
        buffer.write(char);
        continue;
      }

      // Max 7 chars (4 digits + space + 2 letters).
      if (buffer.length >= 7) break;
    }

    // If cursor was at or past the end of input, put it at end of buffer.
    if (!cursorSet) newCursorOffset = buffer.length;

    // Reject forbidden letter pairs at formatter level (defense-in-depth).
    final result = buffer.toString();
    if (result.length == 7) {
      final letters = result.substring(5, 7);
      if (const {'SA', 'SD', 'SS'}.contains(letters)) {
        // Remove the second forbidden letter, keep first.
        return TextEditingValue(
          text: result.substring(0, 6),
          selection: TextSelection.collapsed(
            offset: newCursorOffset.clamp(0, 6),
          ),
        );
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: newCursorOffset.clamp(0, result.length),
      ),
    );
  }
}
