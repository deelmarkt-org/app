import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:deelmarkt/core/constants.dart';
import 'package:deelmarkt/core/design_system/colors.dart';
import 'package:deelmarkt/core/design_system/radius.dart';
import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/design_system/typography.dart';

/// Parses a euro-formatted string to cents.
/// Handles "12,50", "12.50", and European thousands formats like "1.200,50".
/// Strategy: if both separators appear, the last one is the decimal separator.
/// If only one appears and it splits exactly 2 digits at the end, it's decimal.
/// Returns null if the input is not a valid positive amount.
int? _parseCents(String raw) {
  final trimmed = raw.trim();
  final hasDot = trimmed.contains('.');
  final hasComma = trimmed.contains(',');

  final String normalised;
  if (hasDot && hasComma) {
    // e.g. "1.200,50" (EU) or "1,200.50" (US) — last separator is decimal
    final lastDot = trimmed.lastIndexOf('.');
    final lastComma = trimmed.lastIndexOf(',');
    if (lastComma > lastDot) {
      // EU: dot = thousands, comma = decimal
      normalised = trimmed.replaceAll('.', '').replaceAll(',', '.');
    } else {
      // US: comma = thousands, dot = decimal
      normalised = trimmed.replaceAll(',', '');
    }
  } else if (hasComma) {
    normalised = trimmed.replaceAll(',', '.');
  } else {
    normalised = trimmed;
  }

  final value = double.tryParse(normalised);
  if (value == null || value <= 0) return null;
  final cents = (value * 100).round();
  if (cents > OfferConstants.maxOfferCents) return null;
  return cents;
}

/// Bottom sheet for composing a structured "Make an Offer" message (R-32).
///
/// Returns an [int] (cents) via [Navigator.pop] on confirmation, or null on
/// cancel. Usage:
/// ```dart
/// final cents = await MakeOfferSheet.show(context);
/// if (cents != null) notifier.sendOffer(cents);
/// ```
class MakeOfferSheet extends StatefulWidget {
  const MakeOfferSheet({super.key});

  static Future<int?> show(BuildContext context) {
    return showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const MakeOfferSheet(),
    );
  }

  @override
  State<MakeOfferSheet> createState() => _MakeOfferSheetState();
}

class _MakeOfferSheetState extends State<MakeOfferSheet> {
  final _controller = TextEditingController();

  /// Ephemeral validation error — drives a [ValueListenableBuilder] so the
  /// field rebuilds on error without calling setState (CLAUDE.md §1.3).
  final _errorNotifier = ValueNotifier<String?>('');

  @override
  void dispose() {
    _controller.dispose();
    _errorNotifier.dispose();
    super.dispose();
  }

  void _submit() {
    final cents = _parseCents(_controller.text);
    if (cents == null) {
      _errorNotifier.value = 'chat.makeOfferInvalidAmount'.tr();
      return;
    }
    Navigator.of(context).pop(cents);
  }

  Widget _buildAmountField() {
    return ValueListenableBuilder<String?>(
      valueListenable: _errorNotifier,
      builder:
          (_, errorText, _) => Semantics(
            label: 'chat.makeOfferA11y'.tr(),
            child: TextFormField(
              controller: _controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d,.]')),
              ],
              style: DeelmarktTypography.priceInput,
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'chat.makeOfferAmountLabel'.tr(),
                hintText: 'chat.makeOfferHint'.tr(),
                prefixText: '€ ',
                errorText: errorText?.isEmpty == true ? null : errorText,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(DeelmarktRadius.md),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: Spacing.s4,
                  vertical: Spacing.s3,
                ),
              ),
              onChanged: (_) => _errorNotifier.value = '',
              onFieldSubmitted: (_) => _submit(),
            ),
          ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton(
          onPressed: _submit,
          style: FilledButton.styleFrom(
            backgroundColor: DeelmarktColors.primary,
            foregroundColor: DeelmarktColors.white,
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(DeelmarktRadius.md),
            ),
          ),
          child: Text('chat.makeOfferSend'.tr()),
        ),
        const SizedBox(height: Spacing.s2),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          style: TextButton.styleFrom(minimumSize: const Size.fromHeight(44)),
          child: Text('chat.makeOfferCancel'.tr()),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.viewInsetsOf(context);

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(DeelmarktRadius.xl),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          Spacing.s5,
          Spacing.s4,
          Spacing.s5,
          Spacing.s5,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: DeelmarktColors.neutral300,
                  borderRadius: BorderRadius.circular(DeelmarktRadius.full),
                ),
              ),
            ),
            const SizedBox(height: Spacing.s4),
            Text(
              'chat.makeOfferTitle'.tr(),
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.s5),
            _buildAmountField(),
            const SizedBox(height: Spacing.s4),
            _buildActions(),
          ],
        ),
      ),
    );
  }
}
