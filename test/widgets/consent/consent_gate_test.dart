import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/services/consent/consent_record.dart';
import 'package:deelmarkt/widgets/consent/consent_gate.dart';
import 'package:deelmarkt/widgets/consent/gdpr_consent_banner.dart';

Widget _buildApp({ConsentRecord? consentRecord}) {
  return MaterialApp(
    theme: DeelmarktTheme.light,
    home: ConsentGate(
      consentRecord: consentRecord,
      onAcceptAll: () {},
      onNecessaryOnly: () {},
      child: const Scaffold(body: Text('App Content')),
    ),
  );
}

ConsentRecord _createRecord({String version = '1.0.0'}) {
  return ConsentRecord(
    level: ConsentLevel.allCookies,
    version: version,
    timestamp: DateTime.utc(2026, 3, 24),
    locale: 'nl',
    source: ConsentSource.banner,
    purposes: {
      ConsentPurpose.essential: true,
      ConsentPurpose.analytics: true,
      ConsentPurpose.marketing: true,
    },
  );
}

void main() {
  group('ConsentGate', () {
    testWidgets('shows banner when consentRecord is null', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.byType(GdprConsentBanner), findsOneWidget);
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('shows banner when consent version outdated', (tester) async {
      await tester.pumpWidget(
        _buildApp(consentRecord: _createRecord(version: '0.9.0')),
      );
      expect(find.byType(GdprConsentBanner), findsOneWidget);
    });

    testWidgets('hides banner when consent is current', (tester) async {
      await tester.pumpWidget(_buildApp(consentRecord: _createRecord()));
      expect(find.byType(GdprConsentBanner), findsNothing);
      expect(find.text('App Content'), findsOneWidget);
    });

    testWidgets('child is always rendered under banner', (tester) async {
      await tester.pumpWidget(_buildApp());
      expect(find.text('App Content'), findsOneWidget);
    });
  });
}
