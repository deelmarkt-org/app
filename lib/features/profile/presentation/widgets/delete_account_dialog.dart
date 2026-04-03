import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Destructive confirmation dialog for account deletion.
///
/// Requires password re-entry before confirming (OWASP ASVS L2 §4.2.1).
/// Returns the entered password if confirmed, `null` if cancelled.
///
/// Uses setState for ephemeral password-visibility toggle — this is
/// purely local UI state, not app state (CLAUDE.md §12 setState_allowlist).
class DeleteAccountDialog extends StatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  State<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<DeleteAccountDialog> {
  final _controller = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: Text('settings.deleteConfirmTitle'.tr()),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'settings.deleteConfirmBody'.tr(),
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: Spacing.s4),
          Semantics(
            textField: true,
            label: 'form.pass_field'.tr(),
            child: TextField(
              controller: _controller,
              obscureText: _obscurePassword,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'form.pass_field'.tr(),
                suffixIcon: Semantics(
                  button: true,
                  label:
                      _obscurePassword
                          ? 'a11y.showPassword'.tr()
                          : 'a11y.hidePassword'.tr(),
                  child: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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
            label: 'settings.deleteAccount'.tr(),
            onPressed: () {
              final password = _controller.text;
              if (password.isNotEmpty) {
                Navigator.of(context).pop(password);
              }
            },
            variant: DeelButtonVariant.destructive,
            size: DeelButtonSize.medium,
            fullWidth: false,
          ),
        ),
      ],
    );
  }
}
