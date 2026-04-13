import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/core/domain/entities/dutch_address.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Destructive confirmation dialog for address deletion.
///
/// Returns `true` when the user confirms, `null` when cancelled.
/// Uses [barrierDismissible: false] so accidental taps outside the dialog
/// cannot trigger a deletion (OWASP user-consent principle).
///
/// Reference: docs/screens/07-profile/03-settings.md — addresses section
class DeleteAddressDialog extends StatelessWidget {
  const DeleteAddressDialog({required this.address, super.key});

  final DutchAddress address;

  /// Shows the dialog and returns [true] on confirm, [null] on cancel.
  static Future<bool?> show(BuildContext context, DutchAddress address) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteAddressDialog(address: address),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('settings.deleteAddressTitle'.tr()),
      content: Text(address.formatted, style: theme.textTheme.bodyMedium),
      actions: [
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.s2),
          child: DeelButton(
            label: 'action.cancel'.tr(),
            onPressed: () => Navigator.of(context).pop(),
            variant: DeelButtonVariant.ghost,
            size: DeelButtonSize.medium,
            fullWidth: false,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: Spacing.s2),
          child: DeelButton(
            label: 'action.delete'.tr(),
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
