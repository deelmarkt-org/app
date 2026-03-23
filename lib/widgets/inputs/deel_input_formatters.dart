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

    for (var i = 0; i < raw.length && buffer.length < 7; i++) {
      if (!cursorSet && i >= cursorPos) {
        newCursorOffset = buffer.length;
        cursorSet = true;
      }
      _appendChar(buffer, raw[i]);
    }

    if (!cursorSet) newCursorOffset = buffer.length;

    final result = buffer.toString();
    return _rejectForbiddenPairs(result, newCursorOffset);
  }

  /// Appends [char] to [buffer] if it's valid for the current position.
  void _appendChar(StringBuffer buffer, String char) {
    final pos = buffer.length;

    // Position 0: must be 1-9.
    if (pos == 0) {
      if (_digit19.hasMatch(char)) buffer.write(char);
      return;
    }

    // Positions 1-3: digits only, auto-space after 4th digit.
    if (pos >= 1 && pos <= 3) {
      if (!_digit09.hasMatch(char)) return;
      buffer.write(char);
      if (buffer.length == 4) buffer.write(' ');
      return;
    }

    // Position 4 is the auto-inserted space — skip input spaces.
    if (pos == 4 && char == ' ') return;

    // Positions 5-6: letters only.
    if (pos >= 5 && pos <= 6) {
      if (_letterAZ.hasMatch(char)) buffer.write(char);
    }
  }

  /// Rejects forbidden letter pairs (SA, SD, SS) at formatter level.
  TextEditingValue _rejectForbiddenPairs(String result, int cursorOffset) {
    if (result.length == 7) {
      final letters = result.substring(5, 7);
      if (const {'SA', 'SD', 'SS'}.contains(letters)) {
        return TextEditingValue(
          text: result.substring(0, 6),
          selection: TextSelection.collapsed(offset: cursorOffset.clamp(0, 6)),
        );
      }
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(
        offset: cursorOffset.clamp(0, result.length),
      ),
    );
  }
}
