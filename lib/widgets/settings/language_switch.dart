import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:deelmarkt/core/l10n/l10n.dart';

/// NL/EN language toggle using Material 3 [SegmentedButton].
///
/// Instant switch, no reload. Locale persisted automatically via
/// easy_localization (SharedPreferences). Use [onChanged] for backend sync.
///
/// Theme-aware: active segment uses primary colour (configured in
/// DeelmarktTheme.segmentedButtonTheme). Min 44px touch target.
///
/// Reference: docs/design-system/patterns.md §Localisation
class LanguageSwitch extends StatelessWidget {
  const LanguageSwitch({this.onChanged, super.key});

  /// Called after the locale is switched. Use for backend sync.
  final ValueChanged<Locale>? onChanged;

  @override
  Widget build(BuildContext context) {
    final currentLocale = context.locale;

    return Semantics(
      label: 'a11y.languageSwitch'.tr(),
      child: _LanguageSwitchBody(
        currentLocale: currentLocale,
        onSelectionChanged: (locale) {
          context.setLocale(locale);
          onChanged?.call(locale);
        },
      ),
    );
  }
}

/// Inner body extracted for testability without EasyLocalization.
class _LanguageSwitchBody extends StatelessWidget {
  const _LanguageSwitchBody({
    required this.currentLocale,
    required this.onSelectionChanged,
  });

  final Locale currentLocale;
  final ValueChanged<Locale> onSelectionChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<Locale>(
      segments: [
        ButtonSegment(
          value: AppLocales.nl,
          label: Text('settings.languageNl'.tr()),
        ),
        ButtonSegment(
          value: AppLocales.en,
          label: Text('settings.languageEn'.tr()),
        ),
      ],
      selected: {currentLocale},
      onSelectionChanged: (selected) {
        onSelectionChanged(selected.first);
      },
      showSelectedIcon: false,
    );
  }
}
