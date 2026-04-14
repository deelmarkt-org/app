import 'package:deelmarkt/widgets/cards/deel_card_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'deel_card_test_helper.dart';

void main() {
  const testUrl = 'https://example.com/img.jpg';

  Widget buildSubject({
    String imageUrl = testUrl,
    double aspectRatio = 4 / 3,
    String? heroTag,
  }) {
    return buildCardApp(
      child: DeelCardImage(
        imageUrl: imageUrl,
        aspectRatio: aspectRatio,
        heroTag: heroTag,
      ),
    );
  }

  group('DeelCardImage', () {
    testWidgets('wraps image in ExcludeSemantics (decorative)', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(ExcludeSemantics), findsAtLeastNWidgets(1));
    });

    testWidgets('does not wrap in Hero when heroTag is null', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byType(Hero), findsNothing);
    });

    testWidgets('wraps in Hero when heroTag is provided', (tester) async {
      await tester.pumpWidget(buildSubject(heroTag: 'listing-42'));

      final hero = tester.widget<Hero>(find.byType(Hero));
      expect(hero.tag, 'listing-42');
    });

    testWidgets('respects given aspectRatio', (tester) async {
      await tester.pumpWidget(buildSubject(aspectRatio: 1.0));

      final aspectWidget = tester.widget<AspectRatio>(find.byType(AspectRatio));
      expect(aspectWidget.aspectRatio, 1.0);
    });
  });
}
