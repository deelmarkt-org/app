import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/listing_detail/presentation/widgets/detail_loading_view.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

void main() {
  group('DetailLoadingView', () {
    testWidgets('renders Scaffold with SkeletonLoader', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const DetailLoadingView(),
        ),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('has loading Semantics label', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const DetailLoadingView(),
        ),
      );
      await tester.pump();

      expect(find.byType(Semantics), findsWidgets);
    });

    testWidgets('renders image skeleton with 4:3 aspect ratio', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const DetailLoadingView(),
        ),
      );
      await tester.pump();

      expect(find.byType(AspectRatio), findsOneWidget);
      final aspectRatio = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectRatio.aspectRatio, 4 / 3);
    });

    testWidgets('renders with dark theme without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.dark,
          home: const DetailLoadingView(),
        ),
      );
      await tester.pump();

      expect(find.byType(DetailLoadingView), findsOneWidget);
    });
  });
}
