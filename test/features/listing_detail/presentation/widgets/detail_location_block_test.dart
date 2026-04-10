import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_location_block.dart';

void main() {
  Widget buildApp({required Widget child}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(body: child),
    );
  }

  group('DetailLocationBlock', () {
    testWidgets('renders location text', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const DetailLocationBlock(
            location: 'Amsterdam',
            isDark: false,
          ),
        ),
      );

      expect(find.text('Amsterdam'), findsOneWidget);
    });

    testWidgets('renders map pin icon', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const DetailLocationBlock(
            location: 'Rotterdam',
            isDark: false,
          ),
        ),
      );

      expect(
        find.byIcon(PhosphorIcons.mapPin(PhosphorIconsStyle.fill)),
        findsWidgets,
      );
    });

    testWidgets('renders distance when provided', (tester) async {
      await tester.pumpWidget(
        buildApp(
          child: const DetailLocationBlock(
            location: 'Utrecht',
            distanceKm: 5.3,
            isDark: false,
          ),
        ),
      );

      expect(find.textContaining('5,3'), findsOneWidget);
    });

    testWidgets('renders in dark mode without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: const Scaffold(
            body: DetailLocationBlock(location: 'Den Haag', isDark: true),
          ),
        ),
      );

      expect(find.byType(DetailLocationBlock), findsOneWidget);
    });
  });
}
