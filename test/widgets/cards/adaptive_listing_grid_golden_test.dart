/// Golden tests for [AdaptiveListingGrid] — captures the post-migration
/// grid geometry (2/3/4/5 columns, `DeelCardTokens.gridChildAspectRatio` = 0.7,
/// `Spacing.listingCardGap` = 12) so future regressions to the canonical
/// values (or the column-count progression) are caught visually.
///
/// Compact (400) is the dominant favourites/home/search viewport — that's
/// where the migration changed values most (favourites grid previously used
/// aspect 0.65 + gap 16; home/search used 0.7 + 12). Medium (700) and large
/// (1400) lock in the other column counts.
///
/// Reference: docs/design-system/tokens.md §Breakpoints, §Spacing.
/// Run with `--update-goldens` to regenerate.
@Tags(['golden'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';

import '../../helpers/tolerant_golden_comparator.dart';

Widget _cell(int i) => Container(
  decoration: BoxDecoration(
    color: i.isEven ? const Color(0xFFEAF5FF) : const Color(0xFFFFF3EE),
    borderRadius: BorderRadius.circular(12),
  ),
  alignment: Alignment.center,
  child: Text('$i', style: const TextStyle(fontSize: 16)),
);

Future<void> _pumpGridAt(
  WidgetTester tester, {
  required double width,
  required double height,
  int itemCount = 12,
}) async {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            AdaptiveListingGrid(
              itemCount: itemCount,
              itemBuilder: (context, index) => _cell(index),
            ),
          ],
        ),
      ),
    ),
  );
}

void main() {
  setUpAll(() {
    goldenFileComparator = TolerantGoldenFileComparator.forTestFile(
      'test/widgets/cards/adaptive_listing_grid_golden_test.dart',
    );
  });

  testWidgets('400px — compact (2 cols, favourites/home primary viewport)', (
    tester,
  ) async {
    await _pumpGridAt(tester, width: 400, height: 700);
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('goldens/adaptive_listing_grid_400.png'),
    );
  });

  testWidgets('700px — medium (3 cols)', (tester) async {
    await _pumpGridAt(tester, width: 700, height: 700);
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('goldens/adaptive_listing_grid_700.png'),
    );
  });

  testWidgets('1400px — large (5 cols)', (tester) async {
    await _pumpGridAt(tester, width: 1400, height: 700);
    await expectLater(
      find.byType(CustomScrollView),
      matchesGoldenFile('goldens/adaptive_listing_grid_1400.png'),
    );
  });
}
