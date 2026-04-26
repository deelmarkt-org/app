import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';

/// Pumps [child] (typically `ListingsTabView`) inside a bounded-height
/// Scaffold body so its self-scrolling [CustomScrollView] has a viewport.
///
/// The shared `pumpTestWidget` helper wraps in `SingleChildScrollView`
/// (unbounded height), which is incompatible with widgets that own their
/// own scroll position. Use this helper for any test exercising the
/// loading/data states of `ListingsTabView`.
Future<void> pumpListingsGrid(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: DeelmarktTheme.light,
      home: Scaffold(body: SizedBox(height: 800, child: child)),
    ),
  );
  await tester.pump();
}
