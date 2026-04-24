import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

/// Sets the actual test-view physical size so `SliverLayoutBuilder`
/// reports a matching `crossAxisExtent`. Replacing a fake `MediaQuery`
/// with this is necessary post-#193 PR D — the grid now reads the
/// real sliver constraints, not `MediaQuery.sizeOf`.
Future<void> _pumpGridAt(
  WidgetTester tester, {
  required double width,
  int itemCount = 8,
  Widget Function(Widget child)? wrap,
}) async {
  tester.view.physicalSize = Size(width, 1200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final grid = CustomScrollView(
    slivers: [
      AdaptiveListingGrid(
        itemCount: itemCount,
        itemBuilder:
            (context, index) =>
                ColoredBox(color: Colors.grey, key: ValueKey('cell-$index')),
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp(home: Scaffold(body: wrap?.call(grid) ?? grid)),
  );
}

int _crossAxisCount(WidgetTester tester) {
  final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

void main() {
  group('AdaptiveListingGrid — full-width viewport', () {
    testWidgets('uses 2 columns at 400px (compact)', (tester) async {
      await _pumpGridAt(tester, width: 400);
      expect(_crossAxisCount(tester), 2);
    });

    testWidgets('uses 3 columns at 700px (medium)', (tester) async {
      await _pumpGridAt(tester, width: 700);
      expect(_crossAxisCount(tester), 3);
    });

    testWidgets('uses 4 columns at 900px (expanded)', (tester) async {
      await _pumpGridAt(tester, width: 900);
      expect(_crossAxisCount(tester), 4);
    });

    testWidgets('uses 5 columns at 1400px (large)', (tester) async {
      await _pumpGridAt(tester, width: 1400);
      expect(_crossAxisCount(tester), 5);
    });

    testWidgets('uses canonical aspect ratio and listingCardGap spacing', (
      tester,
    ) async {
      await _pumpGridAt(tester, width: 900);
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.childAspectRatio, DeelCardTokens.gridChildAspectRatio);
      expect(delegate.mainAxisSpacing, Spacing.listingCardGap);
      expect(delegate.crossAxisSpacing, Spacing.listingCardGap);
    });
  });

  group('AdaptiveListingGrid — container-aware (#193 PR D)', () {
    testWidgets(
      'column count tracks sidebar-constrained pane, not viewport '
      '(1400 viewport - 240 sidebar - 1 divider = 959 pane → 4 cols, not 5)',
      (tester) async {
        await _pumpGridAt(
          tester,
          width: 1400,
          wrap:
              (grid) => Row(
                children: [
                  const SizedBox(width: 240),
                  const VerticalDivider(width: 1),
                  Expanded(child: grid),
                ],
              ),
        );
        // Pane width ≈ 1400 - 240 - 1 = 1159, which is still < 1200 so the
        // helper returns 4 (not 5). This is the bug the refactor fixes:
        // before #193 PR D, the viewport-based helper would return 5 here.
        expect(_crossAxisCount(tester), 4);
      },
    );

    testWidgets('column count tracks ResponsiveBody.wide-capped pane '
        '(1800 viewport, container capped at 1200 → 5 cols from container)', (
      tester,
    ) async {
      await _pumpGridAt(
        tester,
        width: 1800,
        wrap:
            (grid) => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: grid,
              ),
            ),
      );
      // 1200 cap is EXACTLY the `large` threshold → gets 5 cols because
      // the helper uses `< large` (i.e. strictly less than 1200) → 4;
      // at exactly 1200 → 5.
      expect(_crossAxisCount(tester), 5);
    });

    testWidgets('column count drops to 3 when container narrows below medium '
        '(800 pane inside 1400 viewport → 3 cols)', (tester) async {
      await _pumpGridAt(
        tester,
        width: 1400,
        wrap:
            (grid) => Row(
              children: [const SizedBox(width: 600), Expanded(child: grid)],
            ),
      );
      // 1400 - 600 = 800 → medium range → 3 cols (was 5 pre-fix).
      expect(_crossAxisCount(tester), 3);
    });
  });
}
