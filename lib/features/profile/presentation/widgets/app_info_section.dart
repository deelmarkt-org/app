import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/settings_section_header.dart';

/// App info section — version number and licenses link.
class AppInfoSection extends StatelessWidget {
  const AppInfoSection({required this.version, super.key});

  final String version;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: 'settings.appInfo'.tr()),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('settings.version'.tr(), style: theme.textTheme.bodyMedium),
            Text(
              version,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: Spacing.s3),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text('settings.licenses'.tr()),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => showLicensePage(context: context),
        ),
      ],
    );
  }
}
