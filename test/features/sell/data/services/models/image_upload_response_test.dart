import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';

void main() {
  const validJson = <String, dynamic>{
    'storage_path': 'user-123/photo.jpg',
    'delivery_url':
        'https://res.cloudinary.com/deelmarkt/image/upload/v1/x.jpg',
    'public_id': 'listings/user-123/photo',
    'width': 1200,
    'height': 900,
    'bytes': 200000,
    'format': 'jpg',
  };

  group('ImageUploadResponse.fromJson', () {
    test('parses a well-formed success payload', () {
      final result = ImageUploadResponse.fromJson(validJson);
      expect(result.storagePath, 'user-123/photo.jpg');
      expect(
        result.deliveryUrl,
        'https://res.cloudinary.com/deelmarkt/image/upload/v1/x.jpg',
      );
      expect(result.publicId, 'listings/user-123/photo');
      expect(result.width, 1200);
      expect(result.height, 900);
      expect(result.bytes, 200000);
      expect(result.format, 'jpg');
    });

    test('throws when delivery_url is missing', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('delivery_url');
      expect(
        () => ImageUploadResponse.fromJson(incomplete),
        throwsFormatException,
      );
    });

    test('throws when width is a string instead of int', () {
      final wrong = Map<String, dynamic>.from(validJson)..['width'] = '1200';
      expect(() => ImageUploadResponse.fromJson(wrong), throwsFormatException);
    });

    test('throws when format is null', () {
      final wrong = Map<String, dynamic>.from(validJson)..['format'] = null;
      expect(() => ImageUploadResponse.fromJson(wrong), throwsFormatException);
    });

    test('throws when storage_path is missing', () {
      final incomplete = Map<String, dynamic>.from(validJson)
        ..remove('storage_path');
      expect(
        () => ImageUploadResponse.fromJson(incomplete),
        throwsFormatException,
      );
    });
  });
}
