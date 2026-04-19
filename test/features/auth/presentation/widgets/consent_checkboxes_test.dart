import 'package:deelmarkt/features/auth/presentation/widgets/consent_checkboxes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

// ---------------------------------------------------------------------------
// Minimal url_launcher mock — records launched URLs and returns [returnValue].
// ---------------------------------------------------------------------------
class _MockUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  final List<LaunchOptions> launchOptions = [];
  bool returnValue = true;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    launchOptions.add(options);
    return returnValue;
  }

  @override
  Future<void> closeWebView() async {}
}

void main() {
  Widget buildSubject({
    bool termsAccepted = false,
    bool privacyAccepted = false,
    ValueChanged<bool>? onTermsChanged,
    ValueChanged<bool>? onPrivacyChanged,
    bool enabled = true,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: ConsentCheckboxes(
          termsAccepted: termsAccepted,
          privacyAccepted: privacyAccepted,
          onTermsChanged: onTermsChanged ?? (_) {},
          onPrivacyChanged: onPrivacyChanged ?? (_) {},
          enabled: enabled,
        ),
      ),
    );
  }

  group('ConsentCheckboxes', () {
    testWidgets('renders two CheckboxListTile widgets', (tester) async {
      await tester.pumpWidget(buildSubject());
      expect(find.byType(CheckboxListTile), findsNWidgets(2));
    });

    testWidgets('calls onTermsChanged when terms checkbox is toggled', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        buildSubject(onTermsChanged: (v) => captured = v),
      );

      // Tap the Checkbox widget directly (leading position) to avoid
      // the InkWell link inside the title Wrap intercepting the gesture.
      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.first);
      await tester.pump();

      expect(captured, isTrue);
    });

    testWidgets('calls onPrivacyChanged when privacy checkbox is toggled', (
      tester,
    ) async {
      bool? captured;
      await tester.pumpWidget(
        buildSubject(onPrivacyChanged: (v) => captured = v),
      );

      final checkboxes = find.byType(Checkbox);
      await tester.tap(checkboxes.last);
      await tester.pump();

      expect(captured, isTrue);
    });

    testWidgets('checkboxes are disabled when enabled is false', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject(enabled: false));

      final tiles =
          tester
              .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
              .toList();

      expect(tiles.every((t) => t.onChanged == null), isTrue);
    });

    testWidgets('link widgets have Semantics with link: true', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      final semanticsList =
          tester.widgetList<Semantics>(find.byType(Semantics)).toList();
      final linkSemantics =
          semanticsList.where((s) => s.properties.link == true).toList();

      expect(linkSemantics.length, greaterThanOrEqualTo(2));
    });

    testWidgets('reflects termsAccepted initial value', (tester) async {
      await tester.pumpWidget(buildSubject(termsAccepted: true));

      final tile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).first,
      );
      expect(tile.value, isTrue);
    });

    testWidgets('reflects privacyAccepted initial value', (tester) async {
      await tester.pumpWidget(buildSubject(privacyAccepted: true));

      final tile = tester.widget<CheckboxListTile>(
        find.byType(CheckboxListTile).last,
      );
      expect(tile.value, isTrue);
    });

    // -----------------------------------------------------------------------
    // H1 — Touch target ≥ 44 dp (WCAG 2.5.8 / EAA)
    // -----------------------------------------------------------------------
    testWidgets('link InkWell hit areas are at least 44 dp tall', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Each link is wrapped in Semantics(link: true) > InkWell > Padding >
      // Text. We measure the rendered size of the InkWell widgets.
      final inkWells =
          tester.widgetList<InkWell>(find.byType(InkWell)).toList();

      // There should be exactly 2 link InkWells (terms + privacy).
      expect(inkWells.length, greaterThanOrEqualTo(2));

      for (final inkWell in inkWells) {
        final size = tester.getSize(find.byWidget(inkWell));
        expect(
          size.height,
          greaterThanOrEqualTo(44),
          reason: 'Link InkWell must be ≥ 44 dp tall (WCAG 2.5.8)',
        );
      }
    });

    // -----------------------------------------------------------------------
    // L2a — Terms link opens via PreferredLaunchMode.externalApplication
    // -----------------------------------------------------------------------
    testWidgets('terms link launches URL with externalApplication mode', (
      tester,
    ) async {
      final mock = _MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = mock;

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Tap the first InkWell (terms link).
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(mock.launchedUrls, isNotEmpty);
      expect(mock.launchedUrls.first, contains('terms'));
      expect(
        mock.launchOptions.first.mode,
        PreferredLaunchMode.externalApplication,
        reason:
            'Must open in external browser to prevent in-app WebView '
            'phishing (OWASP M1)',
      );
    });

    // -----------------------------------------------------------------------
    // L2b — Privacy link opens via PreferredLaunchMode.externalApplication
    // -----------------------------------------------------------------------
    testWidgets('privacy link launches URL with externalApplication mode', (
      tester,
    ) async {
      final mock = _MockUrlLauncherPlatform();
      UrlLauncherPlatform.instance = mock;

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      // Tap the second InkWell (privacy link).
      await tester.tap(find.byType(InkWell).last);
      await tester.pumpAndSettle();

      expect(mock.launchedUrls, isNotEmpty);
      expect(mock.launchedUrls.first, contains('privacy'));
      expect(
        mock.launchOptions.first.mode,
        PreferredLaunchMode.externalApplication,
      );
    });

    // -----------------------------------------------------------------------
    // L2c — SnackBar shown when launchUrl returns false
    // -----------------------------------------------------------------------
    testWidgets('shows error SnackBar when URL cannot be launched', (
      tester,
    ) async {
      final mock = _MockUrlLauncherPlatform()..returnValue = false;
      UrlLauncherPlatform.instance = mock;

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
    });
  });
}
