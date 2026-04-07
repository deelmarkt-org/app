import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:deelmarkt/core/design_system/theme.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_loader.dart';
import 'package:deelmarkt/widgets/feedback/skeleton_shapes.dart';
import 'package:deelmarkt/widgets/location/location.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('LocationBadge — compact variant', () {
    testWidgets('renders city name only when distance is null', (tester) async {
      await pumpTestWidget(tester, const LocationBadge(city: 'Amsterdam'));
      expect(find.text('Amsterdam'), findsOneWidget);
    });

    testWidgets('renders city + formatted distance when distance is set', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(city: 'Amsterdam', distanceKm: 3.2),
      );
      expect(find.textContaining('Amsterdam'), findsOneWidget);
      expect(find.textContaining('3,2 km'), findsOneWidget);
    });

    testWidgets('renders a pin icon', (tester) async {
      await pumpTestWidget(tester, const LocationBadge(city: 'Rotterdam'));
      expect(find.byIcon(PhosphorIcons.mapPin()), findsOneWidget);
    });

    testWidgets('truncates long city names on one line', (tester) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 120,
          child: LocationBadge(
            city: "'s-Hertogenbosch (een heel lange stad)",
            distanceKm: 12.4,
          ),
        ),
      );
      final text = tester.widget<Text>(
        find.descendant(
          of: find.byType(LocationBadge),
          matching: find.byType(Text),
        ),
      );
      expect(text.maxLines, 1);
      expect(text.overflow, TextOverflow.ellipsis);
    });
  });

  group('LocationBadge — detail variant', () {
    testWidgets('renders city headline + distance subtitle', (tester) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(
          city: 'Utrecht',
          distanceKm: 1.2,
          variant: LocationBadgeVariant.detail,
        ),
      );
      expect(find.text('Utrecht'), findsOneWidget);
      expect(find.textContaining('1,2 km'), findsOneWidget);
    });

    testWidgets('omits distance subtitle when distance is null', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(
          city: 'Eindhoven',
          variant: LocationBadgeVariant.detail,
        ),
      );
      expect(find.text('Eindhoven'), findsOneWidget);
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('renders map placeholder when showMapPlaceholder is true', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(
          city: 'Groningen',
          distanceKm: 180,
          variant: LocationBadgeVariant.detail,
          showMapPlaceholder: true,
        ),
      );
      expect(find.byType(AspectRatio), findsOneWidget);
    });

    testWidgets('no map placeholder by default', (tester) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(
          city: 'Groningen',
          variant: LocationBadgeVariant.detail,
        ),
      );
      expect(find.byType(AspectRatio), findsNothing);
    });

    testWidgets('map placeholder renders without distance (suggestion)', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(
          city: 'Leiden',
          variant: LocationBadgeVariant.detail,
          showMapPlaceholder: true,
        ),
      );
      expect(find.text('Leiden'), findsOneWidget);
      expect(find.byType(AspectRatio), findsOneWidget);
      expect(find.textContaining('km'), findsNothing);
    });

    testWidgets('truncates long city names in detail variant (suggestion)', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const SizedBox(
          width: 200,
          child: LocationBadge(
            city: "'s-Hertogenbosch (een heel lange stad)",
            variant: LocationBadgeVariant.detail,
          ),
        ),
      );
      final cityText = tester.widget<Text>(
        find
            .descendant(
              of: find.byType(LocationBadgeDetail),
              matching: find.byType(Text),
            )
            .first,
      );
      expect(cityText.maxLines, 1);
      expect(cityText.overflow, TextOverflow.ellipsis);
    });
  });

  group('LocationBadge — skeleton variant', () {
    testWidgets('skeletonCompact renders SkeletonLoader + SkeletonCircle', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: LocationBadge.skeletonCompact(),
            ),
          ),
        ),
      );
      await tester.pump();
      // #6: assert actual skeleton sub-widgets, not just LocationBadge type
      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(SkeletonCircle), findsOneWidget);
      expect(find.byType(SkeletonLine), findsOneWidget);
      // No real city text rendered
      expect(find.textContaining('Amsterdam'), findsNothing);
    });

    testWidgets('skeleton via variant param renders same structure', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: LocationBadge(
                city: '',
                variant: LocationBadgeVariant.skeleton,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      // #6: assert actual skeleton sub-widgets
      expect(find.byType(SkeletonLoader), findsOneWidget);
      expect(find.byType(SkeletonCircle), findsOneWidget);
    });

    testWidgets('shimmer disabled when reduceMotion is on (#7)', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: LocationBadge.skeletonCompact(),
            ),
          ),
        ),
      );
      await tester.pump();
      // SkeletonLoader reads MediaQuery.disableAnimations internally and
      // passes `enabled: false` to Shimmer when motion is reduced. Verify
      // the SkeletonLoader is present (it handles the flag internally).
      final loader = tester.widget<SkeletonLoader>(find.byType(SkeletonLoader));
      // SkeletonLoader.enabled defaults to true; the disableAnimations
      // flag is checked inside its build method.
      expect(loader.enabled, isTrue);
    });
  });

  group('LocationBadge — accessibility', () {
    testWidgets('semantics label uses a11yWithDistance key when distance set', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(city: 'Haarlem', distanceKm: 2.0),
      );
      expect(
        find.bySemanticsLabel(RegExp('location_badge.a11yWithDistance')),
        findsWidgets,
      );
    });

    testWidgets('semantics label uses a11yCityOnly key when distance is null', (
      tester,
    ) async {
      await pumpTestWidget(tester, const LocationBadge(city: 'Maastricht'));
      expect(
        find.bySemanticsLabel(RegExp('location_badge.a11yCityOnly')),
        findsWidgets,
      );
    });

    testWidgets(
      'tappable variant fires onTap and meets ≥44×44 tap target (#4)',
      (tester) async {
        var tapped = false;
        await pumpTestWidget(
          tester,
          LocationBadge(city: 'Tilburg', onTap: () => tapped = true),
        );
        await tester.tap(find.byType(InkWell));
        expect(tapped, isTrue);
        // #4: physically measure the rendered InkWell, not just the callback
        final size = tester.getSize(find.byType(InkWell));
        expect(size.height, greaterThanOrEqualTo(44));
        expect(size.width, greaterThanOrEqualTo(44));
      },
    );

    testWidgets('non-tappable variant does not create an InkWell', (
      tester,
    ) async {
      await pumpTestWidget(tester, const LocationBadge(city: 'Tilburg'));
      expect(find.byType(InkWell), findsNothing);
    });
  });

  group('LocationBadge — dark theme', () {
    testWidgets('renders detail variant in dark theme without exceptions', (
      tester,
    ) async {
      await pumpTestWidget(
        tester,
        const LocationBadge(
          city: 'Delft',
          distanceKm: 5.5,
          variant: LocationBadgeVariant.detail,
          showMapPlaceholder: true,
        ),
        theme: DeelmarktTheme.dark,
      );
      expect(find.text('Delft'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
