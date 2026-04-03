import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';

void main() {
  group('ImagePickerResult', () {
    test('isSuccess returns true for success type', () {
      const result = ImagePickerResult(
        type: ImagePickerResultType.success,
        paths: ['/test/image.jpg'],
      );

      expect(result.isSuccess, isTrue);
    });

    test('isSuccess returns false for cancelled type', () {
      const result = ImagePickerResult(type: ImagePickerResultType.cancelled);

      expect(result.isSuccess, isFalse);
    });

    test('isSuccess returns false for permissionDenied', () {
      const result = ImagePickerResult(
        type: ImagePickerResultType.permissionDenied,
      );

      expect(result.isSuccess, isFalse);
    });

    test('isSuccess returns false for permissionPermanentlyDenied', () {
      const result = ImagePickerResult(
        type: ImagePickerResultType.permissionPermanentlyDenied,
      );

      expect(result.isSuccess, isFalse);
    });

    test('isSuccess returns false for fileTooLarge', () {
      const result = ImagePickerResult(
        type: ImagePickerResultType.fileTooLarge,
      );

      expect(result.isSuccess, isFalse);
    });

    test('isSuccess returns false for unsupportedFormat', () {
      const result = ImagePickerResult(
        type: ImagePickerResultType.unsupportedFormat,
      );

      expect(result.isSuccess, isFalse);
    });

    test('paths defaults to empty list', () {
      const result = ImagePickerResult(type: ImagePickerResultType.cancelled);

      expect(result.paths, isEmpty);
    });

    test('paths contains provided values', () {
      const result = ImagePickerResult(
        type: ImagePickerResultType.success,
        paths: ['/a.jpg', '/b.png'],
      );

      expect(result.paths, hasLength(2));
      expect(result.paths, containsAll(['/a.jpg', '/b.png']));
    });
  });

  group('ImagePickerResultType', () {
    test('all enum values exist', () {
      expect(ImagePickerResultType.values, hasLength(6));
      expect(
        ImagePickerResultType.values,
        containsAll([
          ImagePickerResultType.success,
          ImagePickerResultType.permissionDenied,
          ImagePickerResultType.permissionPermanentlyDenied,
          ImagePickerResultType.cancelled,
          ImagePickerResultType.fileTooLarge,
          ImagePickerResultType.unsupportedFormat,
        ]),
      );
    });
  });

  group('ImagePickerService constants', () {
    test('maxFileSizeBytes is 15 MB', () {
      expect(ImagePickerService.maxFileSizeBytes, equals(15 * 1024 * 1024));
    });

    test('allowedExtensions contains expected formats', () {
      expect(
        ImagePickerService.allowedExtensions,
        containsAll(['jpg', 'jpeg', 'png', 'webp', 'heic']),
      );
    });

    test('allowedExtensions has exactly 5 entries', () {
      expect(ImagePickerService.allowedExtensions, hasLength(5));
    });
  });
}
