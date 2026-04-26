import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/colors.dart';

/// Confirmation dialog asking the user whether to discard unsaved changes.
///
/// Wraps [AlertDialog] with Tier-1 defaults:
/// - Destructive confirm action styled with [DeelmarktColors.error] when
///   [destructive] is `true` (the typical case for edit / form / appeal flows).
/// - Returns `true` only when the user explicitly confirms; barrier-tap and
///   system-back both return `false` (interpreted as cancel — never discard
///   accidentally).
/// - All copy is l10n-key driven; `cancelLabelKey` defaults to
///   `'action.cancel'` (existing project key) so call sites only need to
///   provide the discard-specific strings.
///
/// References:
/// - `docs/PLAN-P54-screen-decomposition.md` §4 (D4 shared primitive)
/// - CLAUDE.md §3.1 (≥2 call sites — currently 3: appeal, listing_creation,
///   review)
class DiscardChangesDialog {
  const DiscardChangesDialog._();

  /// Shows the dialog. Returns `true` if the user confirms, `false` for any
  /// cancel path (button, barrier-tap, back-button).
  static Future<bool> show(
    BuildContext context, {
    required String titleKey,
    required String messageKey,
    required String confirmLabelKey,
    String cancelLabelKey = 'action.cancel',
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      // barrierDismissible defaults to true; null result means cancel.
      builder:
          (ctx) => _DiscardDialog(
            titleKey: titleKey,
            messageKey: messageKey,
            confirmLabelKey: confirmLabelKey,
            cancelLabelKey: cancelLabelKey,
            destructive: destructive,
          ),
    );
    return result ?? false;
  }
}

class _DiscardDialog extends StatelessWidget {
  const _DiscardDialog({
    required this.titleKey,
    required this.messageKey,
    required this.confirmLabelKey,
    required this.cancelLabelKey,
    required this.destructive,
  });

  final String titleKey;
  final String messageKey;
  final String confirmLabelKey;
  final String cancelLabelKey;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final destructiveStyle =
        destructive
            ? theme.textTheme.labelLarge?.copyWith(color: DeelmarktColors.error)
            : null;
    return AlertDialog(
      title: Text(titleKey.tr()),
      content: Text(messageKey.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelLabelKey.tr()),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabelKey.tr(), style: destructiveStyle),
        ),
      ],
    );
  }
}
