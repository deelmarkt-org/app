import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/profile/data/mock/mock_avatar_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/image_picker_service.dart';

void main() {
  group('MockAvatarUploadService', () {
    late MockAvatarUploadService service;

    setUp(() {
      service = MockAvatarUploadService();
    });

    test('upload returns a non-empty URL', () async {
      final url = await service.upload(
        userId: 'user-001',
        filePath: '/tmp/avatar.jpg',
      );

      expect(url, isNotEmpty);
      expect(url, startsWith('https://'));
    });

    test('upload includes userId in the returned URL', () async {
      const userId = 'user-42';
      final url = await service.upload(
        userId: userId,
        filePath: '/tmp/photo.png',
      );

      expect(url, contains(userId));
    });

    test('upload returns different URLs for subsequent calls', () async {
      final url1 = await service.upload(
        userId: 'user-001',
        filePath: '/tmp/a.jpg',
      );
      // Small delay to ensure different timestamps.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      final url2 = await service.upload(
        userId: 'user-001',
        filePath: '/tmp/b.jpg',
      );

      expect(url1, isNot(equals(url2)));
    });

    test(
      'upload completes within a reasonable time (mock delay ~300ms)',
      () async {
        final stopwatch = Stopwatch()..start();
        await service.upload(userId: 'user-001', filePath: '/tmp/avatar.jpg');
        stopwatch.stop();

        // Mock has 300ms delay — should complete within 1s.
        expect(stopwatch.elapsedMilliseconds, lessThan(1000));
      },
    );
  });

  group(
    'ImagePickerService constants (used by SupabaseAvatarUploadService)',
    () {
      test('allowedExtensions includes common image formats', () {
        expect(ImagePickerService.allowedExtensions, contains('jpg'));
        expect(ImagePickerService.allowedExtensions, contains('jpeg'));
        expect(ImagePickerService.allowedExtensions, contains('png'));
        expect(ImagePickerService.allowedExtensions, contains('webp'));
        expect(ImagePickerService.allowedExtensions, contains('heic'));
      });

      test('maxFileSizeBytes is 15 MB', () {
        expect(ImagePickerService.maxFileSizeBytes, equals(15 * 1024 * 1024));
      });
    },
  );
}
