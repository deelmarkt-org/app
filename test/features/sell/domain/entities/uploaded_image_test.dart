import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/uploaded_image.dart';

void main() {
  group('UploadedImage', () {
    const a = UploadedImage(
      storagePath: 'uid/abc.jpg',
      deliveryUrl: 'https://cdn/abc.jpg',
      publicId: 'uid/abc',
      width: 1920,
      height: 1080,
      bytes: 204800,
      format: 'jpg',
    );

    const b = UploadedImage(
      storagePath: 'uid/abc.jpg',
      deliveryUrl: 'https://cdn/abc.jpg',
      publicId: 'uid/abc',
      width: 1920,
      height: 1080,
      bytes: 204800,
      format: 'jpg',
    );

    const c = UploadedImage(
      storagePath: 'uid/other.jpg',
      deliveryUrl: 'https://cdn/other.jpg',
      publicId: 'uid/other',
      width: 800,
      height: 600,
      bytes: 102400,
      format: 'png',
    );

    test('two instances with same values are equal', () {
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('two instances with different values are not equal', () {
      expect(a, isNot(equals(c)));
    });

    test('props list contains all 7 fields', () {
      expect(a.props, [
        a.storagePath,
        a.deliveryUrl,
        a.publicId,
        a.width,
        a.height,
        a.bytes,
        a.format,
      ]);
    });
  });
}
