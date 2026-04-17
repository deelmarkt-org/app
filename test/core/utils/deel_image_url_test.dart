import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/core/utils/deel_image_url.dart';

void main() {
  group('DeelImageUrl.transform', () {
    const cloudinaryBase =
        'https://res.cloudinary.com/demo/image/upload/sample.jpg';

    test('inserts f_auto,q_auto,w_N for Cloudinary URL', () {
      final result = DeelImageUrl.transform(cloudinaryBase, renderWidth: 300);
      expect(
        result,
        'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_320/sample.jpg',
      );
    });

    test('snaps physical width to next breakpoint', () {
      // 200 * 2.0 = 400 → snaps to 480
      final result = DeelImageUrl.transform(
        cloudinaryBase,
        renderWidth: 200,
        devicePixelRatio: 2.0,
      );
      expect(result, contains('w_480'));
    });

    test('caps at 1280 for very large physical sizes', () {
      final result = DeelImageUrl.transform(
        cloudinaryBase,
        renderWidth: 800,
        devicePixelRatio: 3.0,
      );
      expect(result, contains('w_1280'));
    });

    test('returns unchanged URL for non-Cloudinary origin', () {
      const supabaseUrl =
          'https://ehxrhyqhtngwqkguwdiv.supabase.co/storage/v1/object/public/listings-images/photo.jpg';
      final result = DeelImageUrl.transform(
        supabaseUrl,
        renderWidth: 300,
        devicePixelRatio: 2.0,
      );
      expect(result, supabaseUrl);
    });

    test('returns unchanged URL for empty string', () {
      final result = DeelImageUrl.transform(
        '',
        renderWidth: 300,
        devicePixelRatio: 2.0,
      );
      expect(result, '');
    });

    test('does not double-transform already-transformed URL', () {
      // If called twice, a second /upload/ marker would not be found after
      // the first transform segment, so no second insertion should occur.
      const url =
          'https://res.cloudinary.com/demo/image/upload/f_auto,q_auto,w_320/sample.jpg';
      final result = DeelImageUrl.transform(url, renderWidth: 300);
      // URL has no second /upload/, so it passes through unchanged.
      expect(result, url);
    });

    test('default devicePixelRatio is 1.0', () {
      final result = DeelImageUrl.transform(cloudinaryBase, renderWidth: 300);
      // 300 * 1.0 = 300 → snaps to 320
      expect(result, contains('w_320'));
    });

    group('breakpoint snapping', () {
      final cases = <int, int>{
        1: 160,
        160: 160,
        161: 320,
        320: 320,
        321: 480,
        480: 480,
        640: 640,
        641: 960,
        960: 960,
        961: 1280,
        9999: 1280,
      };

      for (final entry in cases.entries) {
        final physicalWidth = entry.key;
        final expectedBp = entry.value;
        test('$physicalWidth px → w_$expectedBp', () {
          final result = DeelImageUrl.transform(
            cloudinaryBase,
            renderWidth: physicalWidth.toDouble(),
          );
          expect(result, contains('w_$expectedBp'));
        });
      }
    });
  });
}
