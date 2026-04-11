import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';

// Previously tested UploadedImage (removed in dedup refactor).
// ImageUploadResponse is the canonical DTO from PR #106.

void main() {
  group('ImageUploadResponse', () {
    const a = ImageUploadResponse(
      storagePath: 'uid/abc.jpg',
      deliveryUrl: 'https://cdn/abc.jpg',
      publicId: 'uid/abc',
      width: 1920,
      height: 1080,
      bytes: 204800,
      format: 'jpg',
    );

    const b = ImageUploadResponse(
      storagePath: 'uid/abc.jpg',
      deliveryUrl: 'https://cdn/abc.jpg',
      publicId: 'uid/abc',
      width: 1920,
      height: 1080,
      bytes: 204800,
      format: 'jpg',
    );

    const c = ImageUploadResponse(
      storagePath: 'uid/other.jpg',
      deliveryUrl: 'https://cdn/other.jpg',
      publicId: 'uid/other',
      width: 800,
      height: 600,
      bytes: 102400,
      format: 'png',
    );

    test('fromJson round-trip', () {
      final json = {
        'storage_path': 'uid/abc.jpg',
        'delivery_url': 'https://cdn/abc.jpg',
        'public_id': 'uid/abc',
        'width': 1920,
        'height': 1080,
        'bytes': 204800,
        'format': 'jpg',
      };
      final parsed = ImageUploadResponse.fromJson(json);
      expect(parsed.storagePath, a.storagePath);
      expect(parsed.deliveryUrl, a.deliveryUrl);
      expect(parsed.publicId, a.publicId);
    });

    test('fromJson throws FormatException on missing fields', () {
      expect(
        () => ImageUploadResponse.fromJson({'storage_path': 'only-this'}),
        throwsA(isA<FormatException>()),
      );
    });

    test('two instances with same values have equal fields', () {
      expect(a.storagePath, equals(b.storagePath));
      expect(a.deliveryUrl, equals(b.deliveryUrl));
      expect(a.publicId, equals(b.publicId));
    });

    test('two instances with different values differ', () {
      expect(a.storagePath, isNot(equals(c.storagePath)));
    });
  });
}
