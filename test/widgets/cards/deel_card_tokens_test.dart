import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/widgets/cards/deel_card_tokens.dart';

void main() {
  group('DeelCardTokens', () {
    test('gridImageAspectWidth/Height yield a landscape-biased ratio', () {
      expect(
        DeelCardTokens.gridImageAspectWidth /
            DeelCardTokens.gridImageAspectHeight,
        greaterThan(1.0),
      );
    });

    test('gridChildAspectRatio is portrait (height > width)', () {
      expect(DeelCardTokens.gridChildAspectRatio, lessThan(1.0));
    });

    test('favouriteTapTarget meets 44px minimum touch target', () {
      expect(DeelCardTokens.favouriteTapTarget, greaterThanOrEqualTo(44.0));
    });

    test('listThumbnailSize is positive', () {
      expect(DeelCardTokens.listThumbnailSize, greaterThan(0));
    });

    test('titleMaxLines is at least 1', () {
      expect(DeelCardTokens.titleMaxLines, greaterThanOrEqualTo(1));
    });
  });
}
