import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/features/profile/presentation/widgets/profile_skeleton.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';

void main() {
  group('ProfileSkeleton', () {
    // ProfileSkeleton uses SkeletonLoader (shimmer) which never settles.
    // Use pump() instead of pumpAndSettle().
    testWidgets('renders SkeletonLoader', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(body: ProfileSkeleton()),
        ),
      );
      await tester.pump();

      expect(find.byType(SkeletonLoader), findsOneWidget);
    });

    testWidgets('has circular avatar skeleton', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(
            body: SingleChildScrollView(child: ProfileSkeleton()),
          ),
        ),
      );
      await tester.pump();

      // Find containers with circle shape
      final containers = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) {
            final decoration = c.decoration;
            return decoration is BoxDecoration &&
                decoration.shape == BoxShape.circle;
          });

      expect(containers, isNotEmpty);
    });

    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: DeelmarktTheme.light,
          home: const Scaffold(body: ProfileSkeleton()),
        ),
      );
      await tester.pump();

      expect(find.byType(ProfileSkeleton), findsOneWidget);
    });
  });
}
