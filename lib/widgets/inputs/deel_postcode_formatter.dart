import 'package:flutter/services.dart';

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
