import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/shared_prefs_provider.dart';
import 'package:deelmarkt/features/profile/domain/entities/report_reason.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_notifier.dart';
import 'package:deelmarkt/features/profile/presentation/notifiers/public_profile_state.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/public_profile_more_actions.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/report_reason_sheet.dart';

/// Stub notifier that records share/report calls without I/O.
class _SpyNotifier extends PublicProfileNotifier {
  int shareCalls = 0;
  ReportReason? lastReason;

  @override
  PublicProfileState build(String userId) => const PublicProfileState();

  @override
  Future<void> shareProfile() async {
    shareCalls++;
  }

  @override
  Future<void> reportUser(ReportReason reason) async {
    lastReason = reason;
  }
}

Future<void> _pumpButton(
  WidgetTester tester, {
  required _SpyNotifier spy,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Tall viewport so ReportReasonSheet (≈700 px content) doesn't overflow
  // when opened via the report menu action.
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        useMockDataProvider.overrideWithValue(true),
        sharedPreferencesProvider.overrideWithValue(prefs),
        publicProfileNotifierProvider('user-001').overrideWith(() => spy),
      ],
      child: EasyLocalization(
        supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
        fallbackLocale: const Locale('en', 'US'),
        path: 'assets/l10n',
        child: const MaterialApp(
          home: Scaffold(appBar: _MockAppBar(), body: SizedBox.shrink()),
        ),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

class _MockAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MockAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Profile'),
      actions: const [PublicProfileMoreButton(userId: 'user-001')],
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PublicProfileMoreButton', () {
    testWidgets('renders popup with share + report items', (tester) async {
      await _pumpButton(tester, spy: _SpyNotifier());

      expect(find.byTooltip('seller_profile.more_actions'), findsOneWidget);

      await tester.tap(find.byTooltip('seller_profile.more_actions'));
      await tester.pumpAndSettle();

      expect(find.text('seller_profile.share_action'), findsOneWidget);
      expect(find.text('seller_profile.report_action'), findsOneWidget);
    });

    testWidgets('share action invokes notifier.shareProfile + snackbar', (
      tester,
    ) async {
      final spy = _SpyNotifier();
      await _pumpButton(tester, spy: spy);

      await tester.tap(find.byTooltip('seller_profile.more_actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('seller_profile.share_action'));
      await tester.pumpAndSettle();

      expect(spy.shareCalls, 1);
      expect(find.text('seller_profile.share_copied'), findsOneWidget);
    });

    testWidgets('report action opens ReportReasonSheet', (tester) async {
      final spy = _SpyNotifier();
      await _pumpButton(tester, spy: spy);

      await tester.tap(find.byTooltip('seller_profile.more_actions'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('seller_profile.report_action'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportReasonSheet), findsOneWidget);
    });
  });

  group('showReportReasonSheet', () {
    testWidgets('opens a ReportReasonSheet via showModalBottomSheet', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({});
      await EasyLocalization.ensureInitialized();
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      ReportReason? captured;

      await tester.pumpWidget(
        ProviderScope(
          child: EasyLocalization(
            supportedLocales: const [Locale('nl', 'NL'), Locale('en', 'US')],
            fallbackLocale: const Locale('en', 'US'),
            path: 'assets/l10n',
            child: MaterialApp(
              home: Scaffold(
                body: Builder(
                  builder:
                      (ctx) => ElevatedButton(
                        onPressed:
                            () => showReportReasonSheet(ctx, (r) async {
                              captured = r;
                            }),
                        child: const Text('open'),
                      ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(ReportReasonSheet), findsOneWidget);
      // The captured callback wiring is exercised — concrete reason
      // selection is tested in report_reason_sheet_test.dart.
      expect(captured, isNull);
    });
  });
}
