import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/inputs/deel_postcode_formatter.dart';
import 'package:deelmarkt/widgets/inputs/deel_price_formatter.dart';

void main() {
  // ── Helper ────────────────────────────────────────────────────────────
  TextEditingValue applyFormat(
    TextInputFormatter formatter,
    String oldText,
    String newText,
  ) {
    return formatter.formatEditUpdate(
      TextEditingValue(
        text: oldText,
        selection: TextSelection.collapsed(offset: oldText.length),
      ),
      TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length),
      ),
    );
  }

  // ── PriceInputFormatter ───────────────────────────────────────────────

  group('PriceInputFormatter (NL comma)', () {
    final formatter = PriceInputFormatter(decimalSeparator: ',');

    test('allows digits', () {
      final result = applyFormat(formatter, '', '123');
      expect(result.text, '123');
    });

    test('allows digits + comma', () {
      final result = applyFormat(formatter, '12', '12,5');
      expect(result.text, '12,5');
    });

    test('allows max 2 decimal digits', () {
      final result = applyFormat(formatter, '12,5', '12,50');
      expect(result.text, '12,50');
    });

    test('blocks third decimal digit', () {
      final result = applyFormat(formatter, '12,50', '12,501');
      expect(result.text, '12,50');
    });

    test('blocks letters', () {
      final result = applyFormat(formatter, '12', '12a');
      expect(result.text, '12');
    });

    test('blocks multiple commas', () {
      final result = applyFormat(formatter, '12,5', '12,5,');
      expect(result.text, '12,5');
    });

    test('blocks leading zeros (except single 0)', () {
      final result = applyFormat(formatter, '0', '01');
      expect(result.text, '0');
    });

    test('allows 0 followed by comma', () {
      final result = applyFormat(formatter, '', '0,5');
      expect(result.text, '0,5');
    });

    test('strips EUR prefix on paste', () {
      final result = applyFormat(formatter, '', 'EUR 45,50');
      expect(result.text, '45,50');
    });

    test('strips euro sign on paste', () {
      final result = applyFormat(formatter, '', '€45,50');
      expect(result.text, '45,50');
    });

    test('empty input returns empty', () {
      final result = applyFormat(formatter, '5', '');
      expect(result.text, '');
    });

    test('parseToCents: 45,50 -> 4550', () {
      expect(formatter.parseToCents('45,50'), 4550);
    });

    test('parseToCents: empty -> 0', () {
      expect(formatter.parseToCents(''), 0);
    });

    test('parseToCents: 0,99 -> 99', () {
      expect(formatter.parseToCents('0,99'), 99);
    });

    test('parseToCents: invalid -> null', () {
      expect(formatter.parseToCents('abc'), isNull);
    });

    test('preserves cursor position when editing in middle', () {
      // User inserts '3' at position 1 of '1,50' → '13,50', cursor at 2.
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1,50',
          selection: TextSelection.collapsed(offset: 1),
        ),
        const TextEditingValue(
          text: '13,50',
          selection: TextSelection.collapsed(offset: 2),
        ),
      );
      expect(result.text, '13,50');
      expect(result.selection.baseOffset, 2);
    });

    test('cursor at end stays at end after append', () {
      // User types '5' at end of '12,' → '12,5', cursor at 4.
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '12,',
          selection: TextSelection.collapsed(offset: 3),
        ),
        const TextEditingValue(
          text: '12,5',
          selection: TextSelection.collapsed(offset: 4),
        ),
      );
      expect(result.text, '12,5');
      expect(result.selection.baseOffset, 4);
    });
  });

  group('PriceInputFormatter (EN dot)', () {
    final formatter = PriceInputFormatter(decimalSeparator: '.');

    test('allows digits + dot', () {
      final result = applyFormat(formatter, '12', '12.5');
      expect(result.text, '12.5');
    });

    test('strips commas (thousands) on paste', () {
      final result = applyFormat(formatter, '', '1,234.56');
      expect(result.text, '1234.56');
    });

    test('parseToCents: 45.50 -> 4550', () {
      expect(formatter.parseToCents('45.50'), 4550);
    });
  });

  // ── PostcodeInputFormatter ────────────────────────────────────────────

  group('PostcodeInputFormatter', () {
    final formatter = PostcodeInputFormatter();

    test('allows valid digits 1-9 as first char', () {
      final result = applyFormat(formatter, '', '1');
      expect(result.text, '1');
    });

    test('blocks 0 as first char', () {
      final result = applyFormat(formatter, '', '0');
      expect(result.text, '');
    });

    test('auto-inserts space after 4 digits', () {
      final result = applyFormat(formatter, '101', '1012');
      expect(result.text, '1012 ');
    });

    test('uppercases letters', () {
      final result = applyFormat(formatter, '1012 ', '1012 ab');
      expect(result.text, '1012 AB');
    });

    test('blocks digits in letter positions', () {
      final result = applyFormat(formatter, '1012 ', '1012 1');
      expect(result.text, '1012 ');
    });

    test('max 7 characters', () {
      final result = applyFormat(formatter, '1012 AB', '1012 ABC');
      expect(result.text, '1012 AB');
    });

    test('handles full paste', () {
      final result = applyFormat(formatter, '', '1012AB');
      expect(result.text, '1012 AB');
    });

    test('blocks letters in digit positions', () {
      final result = applyFormat(formatter, '1', '1A');
      expect(result.text, '1');
    });

    test('rejects forbidden pair SA at formatter level', () {
      final result = applyFormat(formatter, '1234 S', '1234 SA');
      expect(result.text, '1234 S');
    });

    test('rejects forbidden pair SD at formatter level', () {
      final result = applyFormat(formatter, '1234 S', '1234 SD');
      expect(result.text, '1234 S');
    });

    test('rejects forbidden pair SS at formatter level', () {
      final result = applyFormat(formatter, '1234 S', '1234 SS');
      expect(result.text, '1234 S');
    });

    test('allows valid pair AB at formatter level', () {
      final result = applyFormat(formatter, '1234 A', '1234 AB');
      expect(result.text, '1234 AB');
    });

    test('preserves cursor position when editing digit in middle', () {
      // User inserts '2' at position 2 of '103 AB' → '1023 AB', cursor at 3.
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '103 AB',
          selection: TextSelection.collapsed(offset: 2),
        ),
        const TextEditingValue(
          text: '1023 AB',
          selection: TextSelection.collapsed(offset: 3),
        ),
      );
      expect(result.text, '1023 AB');
      expect(result.selection.baseOffset, 3);
    });

    test('cursor at end stays at end after append', () {
      // User types 'B' at end of '1234 A' → '1234 AB', cursor at 7.
      final result = formatter.formatEditUpdate(
        const TextEditingValue(
          text: '1234 A',
          selection: TextSelection.collapsed(offset: 6),
        ),
        const TextEditingValue(
          text: '1234 AB',
          selection: TextSelection.collapsed(offset: 7),
        ),
      );
      expect(result.text, '1234 AB');
      expect(result.selection.baseOffset, 7);
    });
  });

  // ── Fuzz tests ────────────────────────────────────────────────────────

  group('Formatter fuzz tests', () {
    test('PriceInputFormatter handles emoji without crash', () {
      final formatter = PriceInputFormatter();
      final result = applyFormat(formatter, '', '😀123,45');
      expect(result.text, '123,45');
    });

    test('PostcodeInputFormatter handles emoji without crash', () {
      final formatter = PostcodeInputFormatter();
      final result = applyFormat(formatter, '', '😀1012AB');
      expect(result.text, '1012 AB');
    });

    test('PriceInputFormatter handles very long input', () {
      final formatter = PriceInputFormatter();
      final longInput = '9' * 100;
      final result = applyFormat(formatter, '', longInput);
      // Should not crash; result depends on formatter logic.
      expect(result.text, isNotEmpty);
    });

    test('PostcodeInputFormatter handles very long input', () {
      final formatter = PostcodeInputFormatter();
      final longInput = '1234ABCDEF'; // pragma: allowlist secret
      final result = applyFormat(formatter, '', longInput);
      expect(result.text, '1234 AB');
    });

    test('PriceInputFormatter handles special characters', () {
      final formatter = PriceInputFormatter();
      final result = applyFormat(formatter, '', '!@#\$%^&*()');
      // All chars stripped, nothing valid remains — should return old value.
      expect(result.text, '');
    });
  });
}
