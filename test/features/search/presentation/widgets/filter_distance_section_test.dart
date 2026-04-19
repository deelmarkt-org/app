import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/search/domain/search_filter.dart';
import 'package:deelmarkt/features/search/presentation/widgets/filter_distance_section.dart';

void main() {
  Widget build({SearchFilter filter = const SearchFilter()}) {
    return MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(
        body: FilterDistanceSection(filter: filter, onChanged: (_) {}),
      ),
    );
  }

  testWidgets('renders slider with current distance label', (tester) async {
    await tester.pumpWidget(
      build(filter: const SearchFilter(maxDistanceKm: 25)),
    );
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
    expect(find.text('25 km'), findsWidgets);
  });

  testWidgets('renders at default (max) distance', (tester) async {
    await tester.pumpWidget(build());
    await tester.pumpAndSettle();
    expect(find.byType(Slider), findsOneWidget);
  });
}
