import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/core/utils/formatters.dart';
import 'package:deelmarkt/features/home/presentation/widgets/listing_location_row.dart';

void main() {
  Widget buildRow({required String location, double? distanceKm}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: ListingLocationRow(location: location, distanceKm: distanceKm),
      ),
    );
  }

  group('ListingLocationRow', () {
    testWidgets('renders location name', (tester) async {
      await tester.pumpWidget(buildRow(location: 'Amsterdam'));
      expect(find.text('Amsterdam'), findsOneWidget);
    });

    testWidgets('renders location with distance', (tester) async {
      await tester.pumpWidget(buildRow(location: 'Amsterdam', distanceKm: 3.2));
      expect(
        find.text('Amsterdam · ${Formatters.distanceKm(3.2)}'),
        findsOneWidget,
      );
    });

    testWidgets('renders without distance when null', (tester) async {
      await tester.pumpWidget(buildRow(location: 'Rotterdam'));
      expect(find.text('Rotterdam'), findsOneWidget);
    });

    testWidgets('renders map pin icon', (tester) async {
      await tester.pumpWidget(buildRow(location: 'Utrecht'));
      expect(find.byType(Icon), findsOneWidget);
    });
  });
}
