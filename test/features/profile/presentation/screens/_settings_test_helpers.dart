import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/profile/domain/repositories/settings_repository.dart';
import 'package:deelmarkt/features/profile/domain/repositories/user_repository.dart';
import 'package:deelmarkt/features/profile/presentation/screens/settings_screen.dart';

import '_settings_repo_stubs.dart';
import '_settings_user_stubs.dart';

export '_settings_repo_stubs.dart';
export '_settings_user_stubs.dart';

// ── Pump helper ──────────────────────────────────────────────────────────────

/// Pumps the [SettingsScreen] with repository overrides driving the notifiers.
///
/// Uses real [SettingsNotifier] and [ProfileNotifier] with overridden repos.
/// When [hasAnimations] is true, uses `pump()` instead of `pumpAndSettle()`
/// to avoid timeout from continuous animations.
Future<void> pumpSettingsScreen(
  WidgetTester tester, {
  SettingsRepository? settingsRepo,
  UserRepository? userRepo,
  bool hasAnimations = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  final overrides = <Override>[
    settingsRepositoryProvider.overrideWithValue(
      settingsRepo ?? const InstantSettingsRepository(),
    ),
    userRepositoryProvider.overrideWithValue(
      userRepo ?? const InstantUserRepository(),
    ),
    listingRepositoryProvider.overrideWithValue(EmptyListingRepository()),
    reviewRepositoryProvider.overrideWithValue(EmptyReviewRepository()),
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: EasyLocalization(
        supportedLocales: AppLocales.supportedLocales,
        fallbackLocale: AppLocales.fallbackLocale,
        path: AppLocales.path,
        child: MaterialApp(
          theme: DeelmarktTheme.light,
          home: const SettingsScreen(),
        ),
      ),
    ),
  );

  if (hasAnimations) {
    // Pump a few frames without settling to avoid timeout from
    // continuous animations like CircularProgressIndicator.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  } else {
    await tester.pumpAndSettle();
  }
}
