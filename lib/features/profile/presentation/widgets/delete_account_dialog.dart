import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Destructive confirmation dialog for account deletion.
///
/// Returns `true` if the user confirms, `null` or `false` otherwise.
class DeleteAccountDialog extends StatelessWidget {
  const DeleteAccountDialog({super.key});

  /// Show the dialog and return whether the user confirmed.
  static Future<bool?> show(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('settings.deleteConfirmTitle'.tr()),
      content: Text(
        'settings.deleteConfirmBody'.tr(),
        style: theme.textTheme.bodyMedium,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.s2),
          child: DeelButton(
            label: 'action.cancel'.tr(),
            onPressed: () => Navigator.of(context).pop(false),
            variant: DeelButtonVariant.ghost,
            size: DeelButtonSize.medium,
            fullWidth: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.s2),
          child: DeelButton(
            label: 'settings.deleteAccount'.tr(),
            onPressed: () => Navigator.of(context).pop(true),
            variant: DeelButtonVariant.destructive,
            size: DeelButtonSize.medium,
            fullWidth: false,
          ),
        ),
      ],
    );
  }
}
