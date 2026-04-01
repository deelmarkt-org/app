import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/l10n/l10n.dart';
import 'package:deelmarkt/features/profile/domain/entities/notification_preferences.dart';
import 'package:deelmarkt/features/profile/domain/entities/user_entity.dart';
import 'package:deelmarkt/features/profile/presentation/screens/settings_screen.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/profile_viewmodel.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/settings_viewmodel.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/account_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/addresses_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/app_info_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/notifications_section.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/privacy_section.dart';
import 'package:deelmarkt/features/shipping/domain/entities/dutch_address.dart';

/// Fake [SettingsNotifier] that does not call any repository.
class _FakeSettingsNotifier extends StateNotifier<SettingsState>
    implements SettingsNotifier {
  _FakeSettingsNotifier(super.initial);

  @override
  Future<void> load() async {}
  @override
  Future<void> updateNotificationPrefs(NotificationPreferences prefs) async {}
  @override
  Future<void> saveAddress(DutchAddress address) async {}
  @override
  Future<void> deleteAddress(DutchAddress address) async {}
  @override
  Future<void> exportUserData() async {}
  @override
  Future<void> deleteAccount({required String password}) async {}
}

/// Fake [ProfileNotifier] that does not call any repository.
class _FakeProfileNotifier extends StateNotifier<ProfileState>
    implements ProfileNotifier {
  _FakeProfileNotifier(super.initial);

  @override
  Future<void> load() async {}
}

final _testUser = UserEntity(
  id: 'user-001',
  displayName: 'Jan de Vries',
  email: 'jan@example.com',
  phone: '+31 6 1234 5678',
  kycLevel: KycLevel.level1,
  location: 'Amsterdam',
  badges: const [BadgeType.emailVerified],
  averageRating: 4.7,
  reviewCount: 23,
  responseTimeMinutes: 15,
  createdAt: DateTime(2025, 6),
);

const _testAddresses = [
  DutchAddress(
    postcode: '1012 AB',
    houseNumber: '42',
    street: 'Damstraat',
    city: 'Amsterdam',
  ),
];

const _testPrefs = NotificationPreferences(offers: false);

/// Pumps the [SettingsScreen] with the given states.
///
/// EasyLocalization is required because [LanguageSwitch] calls `context.locale`.
/// When [hasAnimations] is true (e.g. loading indicators), uses `pump()`
/// instead of `pumpAndSettle()` to avoid the settle timeout.
Future<void> _pumpSettingsScreen(
  WidgetTester tester, {
  SettingsState? settingsState,
  ProfileState? profileState,
  bool hasAnimations = false,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  final sState =
      settingsState ??
      const SettingsState(
        addresses: AsyncValue.data(_testAddresses),
        notificationPrefs: AsyncValue.data(_testPrefs),
      );

  final pState =
      profileState ??
      ProfileState(
        user: AsyncValue.data(_testUser),
        listings: const AsyncValue.data([]),
        reviews: const AsyncValue.data([]),
      );

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        settingsProvider.overrideWith((_) => _FakeSettingsNotifier(sState)),
        profileProvider.overrideWith((_) => _FakeProfileNotifier(pState)),
      ],
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

void main() {
  group('SettingsScreen', () {
    testWidgets('renders Scaffold with AppBar', (tester) async {
      await _pumpSettingsScreen(tester);

      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders AccountSection when user is loaded', (tester) async {
      await _pumpSettingsScreen(tester);

      expect(find.byType(AccountSection), findsOneWidget);
      expect(find.text('jan@example.com'), findsOneWidget);
    });

    testWidgets('renders AddressesSection with formatted address', (
      tester,
    ) async {
      await _pumpSettingsScreen(tester);

      expect(find.byType(AddressesSection), findsOneWidget);
      expect(find.text('Damstraat 42, 1012 AB Amsterdam'), findsOneWidget);
    });

    testWidgets('renders NotificationsSection with SwitchListTiles', (
      tester,
    ) async {
      await _pumpSettingsScreen(tester);

      expect(find.byType(NotificationsSection), findsOneWidget);
      expect(find.byType(SwitchListTile), findsNWidgets(4));
    });

    testWidgets('renders PrivacySection', (tester) async {
      await _pumpSettingsScreen(tester);

      expect(find.byType(PrivacySection), findsOneWidget);
    });

    testWidgets('renders AppInfoSection', (tester) async {
      await _pumpSettingsScreen(tester);

      expect(find.byType(AppInfoSection), findsOneWidget);
    });

    testWidgets('shows CircularProgressIndicator when addresses are loading', (
      tester,
    ) async {
      await _pumpSettingsScreen(
        tester,
        hasAnimations: true,
        settingsState: const SettingsState(
          notificationPrefs: AsyncValue.data(_testPrefs),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.byType(AddressesSection), findsNothing);
    });

    testWidgets('shows error widget when addresses fail to load', (
      tester,
    ) async {
      await _pumpSettingsScreen(
        tester,
        settingsState: SettingsState(
          addresses: AsyncValue.error(
            Exception('Network error'),
            StackTrace.empty,
          ),
          notificationPrefs: const AsyncValue.data(_testPrefs),
        ),
      );

      expect(find.byType(AddressesSection), findsNothing);
    });

    testWidgets('shows CircularProgressIndicator when notifications loading', (
      tester,
    ) async {
      await _pumpSettingsScreen(
        tester,
        hasAnimations: true,
        settingsState: const SettingsState(
          addresses: AsyncValue.data(_testAddresses),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsAtLeastNWidgets(1));
      expect(find.byType(NotificationsSection), findsNothing);
    });

    testWidgets('shows error widget when notifications fail to load', (
      tester,
    ) async {
      await _pumpSettingsScreen(
        tester,
        settingsState: SettingsState(
          addresses: const AsyncValue.data(_testAddresses),
          notificationPrefs: AsyncValue.error(
            Exception('Network error'),
            StackTrace.empty,
          ),
        ),
      );

      expect(find.byType(NotificationsSection), findsNothing);
    });

    testWidgets('hides account section when user is loading', (tester) async {
      await _pumpSettingsScreen(tester, profileState: const ProfileState());

      expect(find.byType(AccountSection), findsNothing);
    });

    testWidgets('hides account section when user has error', (tester) async {
      await _pumpSettingsScreen(
        tester,
        profileState: ProfileState(
          user: AsyncValue.error(Exception('Auth failed'), StackTrace.empty),
          listings: const AsyncValue.data([]),
          reviews: const AsyncValue.data([]),
        ),
      );

      expect(find.byType(AccountSection), findsNothing);
    });

    testWidgets('hides account section when user is null', (tester) async {
      await _pumpSettingsScreen(
        tester,
        profileState: const ProfileState(
          user: AsyncValue.data(null),
          listings: AsyncValue.data([]),
          reviews: AsyncValue.data([]),
        ),
      );

      expect(find.byType(AccountSection), findsNothing);
    });

    testWidgets('renders all five section widgets in happy path', (
      tester,
    ) async {
      await _pumpSettingsScreen(tester);

      expect(find.byType(AccountSection), findsOneWidget);
      expect(find.byType(AddressesSection), findsOneWidget);
      expect(find.byType(NotificationsSection), findsOneWidget);
      expect(find.byType(PrivacySection), findsOneWidget);
      expect(find.byType(AppInfoSection), findsOneWidget);
    });

    testWidgets('privacy section renders in exporting state', (tester) async {
      await _pumpSettingsScreen(
        tester,
        hasAnimations: true,
        settingsState: const SettingsState(
          addresses: AsyncValue.data(_testAddresses),
          notificationPrefs: AsyncValue.data(_testPrefs),
          isExporting: true,
        ),
      );

      expect(find.byType(PrivacySection), findsOneWidget);
    });

    testWidgets('privacy section renders in deleting state', (tester) async {
      await _pumpSettingsScreen(
        tester,
        hasAnimations: true,
        settingsState: const SettingsState(
          addresses: AsyncValue.data(_testAddresses),
          notificationPrefs: AsyncValue.data(_testPrefs),
          isDeleting: true,
        ),
      );

      expect(find.byType(PrivacySection), findsOneWidget);
    });

    testWidgets('addresses section has edit and delete action buttons', (
      tester,
    ) async {
      await _pumpSettingsScreen(tester);

      // AddressesSection renders edit/delete IconButtons with tooltips
      expect(find.byTooltip('action.edit'), findsOneWidget);
      expect(find.byTooltip('action.delete'), findsOneWidget);
    });
  });
}
