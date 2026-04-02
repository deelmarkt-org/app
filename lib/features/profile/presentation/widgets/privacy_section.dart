import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/settings_section_header.dart';
import 'package:deelmarkt/widgets/buttons/deel_button.dart';

/// Privacy section — GDPR export and account deletion.
class PrivacySection extends StatelessWidget {
  const PrivacySection({
    required this.onExport,
    required this.onDeleteAccount,
    required this.isExporting,
    required this.isDeleting,
    super.key,
  });

  final VoidCallback onExport;
  final VoidCallback onDeleteAccount;
  final bool isExporting;
  final bool isDeleting;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: 'settings.privacy'.tr()),
        DeelButton(
          label: 'settings.exportData'.tr(),
          onPressed: isExporting ? null : onExport,
          variant: DeelButtonVariant.outline,
          size: DeelButtonSize.medium,
          isLoading: isExporting,
        ),
        const SizedBox(height: Spacing.s3),
        DeelButton(
          label: 'settings.deleteAccount'.tr(),
          onPressed: isDeleting ? null : onDeleteAccount,
          variant: DeelButtonVariant.destructive,
          size: DeelButtonSize.medium,
          isLoading: isDeleting,
          semanticDestructiveHint: 'settings.deleteConfirmBody'.tr(),
        ),
      ],
    );
  }
}
