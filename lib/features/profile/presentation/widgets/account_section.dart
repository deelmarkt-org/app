import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/settings_section_header.dart';

/// Account section — displays email and masked phone number.
class AccountSection extends StatelessWidget {
  const AccountSection({required this.email, required this.phone, super.key});

  final String email;
  final String phone;

  /// Masks a phone number, preserving format: "+31 6 1234 5678" → "+31 6 •••• 5678"
  static String maskPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 4) return phone;
    final lastFour = digits.substring(digits.length - 4);
    final prefix = phone.substring(0, phone.length - 4);
    return '${prefix.replaceAll(RegExp(r'\d'), '\u2022')}$lastFour';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: 'settings.account'.tr()),
        _InfoRow(label: 'settings.email'.tr(), value: email, theme: theme),
        const SizedBox(height: Spacing.s2),
        _InfoRow(
          label: 'settings.phone'.tr(),
          value: maskPhone(phone),
          theme: theme,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.theme,
  });

  final String label;
  final String value;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: theme.textTheme.bodyMedium),
        Flexible(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
