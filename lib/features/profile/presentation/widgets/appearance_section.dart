import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:deelmarkt/core/services/theme_mode_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/settings_section_header.dart';

/// Appearance section in Settings — lets the user pick Light / Dark / System.
///
/// Persisted to [SharedPreferences] via [ThemeModeNotifier] and immediately
/// applied to [MaterialApp.themeMode] in `main.dart`.
class AppearanceSection extends ConsumerWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(themeModeNotifierProvider);
    void onChange(ThemeMode? mode) => ref
        .read(themeModeNotifierProvider.notifier)
        .setThemeMode(mode ?? ThemeMode.system);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionHeader(title: 'settings.appearanceTitle'.tr()),
        RadioGroup<ThemeMode>(
          groupValue: current,
          onChanged: onChange,
          child: Column(
            children: [
              _ThemeOption(
                label: 'settings.themeLight'.tr(),
                value: ThemeMode.light,
                groupValue: current,
              ),
              _ThemeOption(
                label: 'settings.themeDark'.tr(),
                value: ThemeMode.dark,
                groupValue: current,
              ),
              _ThemeOption(
                label: 'settings.themeSystem'.tr(),
                value: ThemeMode.system,
                groupValue: current,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.value,
    required this.groupValue,
  });

  final String label;
  final ThemeMode value;

  /// The currently selected [ThemeMode].
  ///
  /// NOT wired into [RadioListTile] — the ancestor [RadioGroup] propagates
  /// `groupValue` and `onChanged` via InheritedWidget.
  /// Used exclusively for [Semantics.checked] to satisfy WCAG 4.1.2.
  final ThemeMode groupValue;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      inMutuallyExclusiveGroup: true,
      checked: value == groupValue,
      child: RadioListTile<ThemeMode>(
        title: Text(label),
        value: value,
        contentPadding: EdgeInsets.zero,
      ),
    );
  }
}
