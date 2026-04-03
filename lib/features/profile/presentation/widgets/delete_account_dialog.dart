import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Whether the password is visible in the delete account dialog.
final _obscurePasswordProvider = StateProvider.autoDispose<bool>((_) => true);

/// Destructive confirmation dialog for account deletion.
///
/// Requires password re-entry before confirming (OWASP ASVS L2 §4.2.1).
/// Returns the entered password if confirmed, `null` if cancelled.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  static Future<String?> show(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DeleteAccountDialog(),
    );
  }

  @override
  ConsumerState<DeleteAccountDialog> createState() =>
      _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final obscure = ref.watch(_obscurePasswordProvider);

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
              obscureText: obscure,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'form.pass_field'.tr(),
                suffixIcon: Semantics(
                  button: true,
                  label:
                      obscure
                          ? 'a11y.showPassword'.tr()
                          : 'a11y.hidePassword'.tr(),
                  child: IconButton(
                    icon: Icon(
                      obscure ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      ref.read(_obscurePasswordProvider.notifier).state =
                          !obscure;
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
