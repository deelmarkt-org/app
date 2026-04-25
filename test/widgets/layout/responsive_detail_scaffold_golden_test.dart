/// Golden tests for [ResponsiveDetailScaffold] — verifies master-detail
/// behaviour at compact (700), expanded (900), and large (1400) breakpoints.
///
/// Reference: docs/design-system/tokens.md §Breakpoints.
/// Run with `--update-goldens` to regenerate.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/layout/responsive_detail_scaffold.dart';

import '../../helpers/tolerant_golden_comparator.dart';

final _master = Container(
  color: const Color(0xFFEAF5FF),
  alignment: Alignment.center,
  child: const Text('MASTER', style: TextStyle(fontSize: 16)),
);

final _detail = Container(
  color: const Color(0xFFFFF3EE),
  alignment: Alignment.center,
  child: const Text('DETAIL', style: TextStyle(fontSize: 16)),
);

Future<void> _pumpAt(
  WidgetTester tester, {
  required double width,
  required double height,
  required Widget child,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  setUpAll(() {
    goldenFileComparator = TolerantGoldenFileComparator.forTestFile(
      'test/widgets/layout/responsive_detail_scaffold_golden_test.dart',
    );
  });

  testWidgets('700px — compact: detail replaces master (single pane)', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      width: 700,
      height: 600,
      child: ResponsiveDetailScaffold(master: _master, detail: _detail),
    );
    await expectLater(
      find.byType(ResponsiveDetailScaffold),
      matchesGoldenFile('goldens/responsive_detail_scaffold_700.png'),
    );
  });

  testWidgets('900px — expanded: side-by-side split', (tester) async {
    await _pumpAt(
      tester,
      width: 900,
      height: 600,
      child: ResponsiveDetailScaffold(master: _master, detail: _detail),
    );
    await expectLater(
      find.byType(ResponsiveDetailScaffold),
      matchesGoldenFile('goldens/responsive_detail_scaffold_900.png'),
    );
  });

  testWidgets('1400px — large: detail expands, master stays 360', (
    tester,
  ) async {
    await _pumpAt(
      tester,
      width: 1400,
      height: 600,
      child: ResponsiveDetailScaffold(master: _master, detail: _detail),
    );
    await expectLater(
      find.byType(ResponsiveDetailScaffold),
      matchesGoldenFile('goldens/responsive_detail_scaffold_1400.png'),
    );
  });
}
