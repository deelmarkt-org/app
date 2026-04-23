import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/spacing.dart';
import 'package:deelmarkt/widgets/cards/adaptive_listing_grid.dart';
import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

Widget _buildGridApp({required double width, int itemCount = 8}) {
  return MediaQuery(
    data: MediaQueryData(size: Size(width, 1200)),
    child: MaterialApp(
      home: Scaffold(
        body: CustomScrollView(
          slivers: [
            AdaptiveListingGrid(
              itemCount: itemCount,
              itemBuilder:
                  (context, index) => ColoredBox(
                    color: Colors.grey,
                    key: ValueKey('cell-$index'),
                  ),
            ),
          ],
        ),
      ),
    ),
  );
}

int _crossAxisCount(WidgetTester tester) {
  final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
  final delegate =
      grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
  return delegate.crossAxisCount;
}

void main() {
  group('AdaptiveListingGrid', () {
    testWidgets('uses 2 columns at 400px (compact)', (tester) async {
      await tester.pumpWidget(_buildGridApp(width: 400));
      expect(_crossAxisCount(tester), 2);
    });

    testWidgets('uses 3 columns at 700px (medium)', (tester) async {
      await tester.pumpWidget(_buildGridApp(width: 700));
      expect(_crossAxisCount(tester), 3);
    });

    testWidgets('uses 4 columns at 900px (expanded)', (tester) async {
      await tester.pumpWidget(_buildGridApp(width: 900));
      expect(_crossAxisCount(tester), 4);
    });

    testWidgets('uses 5 columns at 1400px (large)', (tester) async {
      await tester.pumpWidget(_buildGridApp(width: 1400));
      expect(_crossAxisCount(tester), 5);
    });

    testWidgets('uses canonical aspect ratio and listingCardGap spacing', (
      tester,
    ) async {
      await tester.pumpWidget(_buildGridApp(width: 900));
      final grid = tester.widget<SliverGrid>(find.byType(SliverGrid));
      final delegate =
          grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.childAspectRatio, DeelCardTokens.gridChildAspectRatio);
      expect(delegate.mainAxisSpacing, Spacing.listingCardGap);
      expect(delegate.crossAxisSpacing, Spacing.listingCardGap);
    });
  });
}
