import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/features/profile/data/services/supabase_avatar_upload_service.dart';
import 'package:deelmarkt/features/profile/domain/services/avatar_upload_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MockSupabaseStorageClient extends Mock
    implements SupabaseStorageClient {}

class _MockStorageFileApi extends Mock implements StorageFileApi {}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

/// Creates a temporary file with the given [extension] and [sizeBytes] content.
/// Auto-deleted via [addTearDown].
Future<File> _makeTempFile({
  required String extension,
  int sizeBytes = 512,
}) async {
  final dir = await Directory.systemTemp.createTemp('avatar_svc_test');
  addTearDown(() async {
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  });
  final file = File('${dir.path}/avatar.$extension');
  await file.writeAsBytes(List<int>.filled(sizeBytes, 0));
  return file;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  setUpAll(() {
    registerFallbackValue(File('fallback.jpg'));
    registerFallbackValue(const FileOptions());
  });

  group('SupabaseAvatarUploadService', () {
    test('implements AvatarUploadService interface', () {
      final client = _MockSupabaseClient();
      final AvatarUploadService service = SupabaseAvatarUploadService(client);

      expect(service, isA<AvatarUploadService>());
    });

    test('rejects unsupported file extensions', () {
      final client = _MockSupabaseClient();
      final service = SupabaseAvatarUploadService(client);

      // Extension check happens before file.length() — no real file needed.
      expect(
        () => service.upload(userId: 'user-1', filePath: '/tmp/avatar.bmp'),
        throwsA(isA<FormatException>()),
      );
    });

    test('uploads file to storage and returns public URL', () async {
      final client = _MockSupabaseClient();
      final storage = _MockSupabaseStorageClient();
      final fileApi = _MockStorageFileApi();
      final service = SupabaseAvatarUploadService(client);

      const publicUrl =
          'https://supabase.co/storage/v1/object/public/avatars/u1/123.jpg';

      when(() => client.storage).thenReturn(storage);
      when(() => storage.from(any())).thenReturn(fileApi);
      when(
        () => fileApi.upload(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenAnswer((_) async => '');
      when(() => fileApi.getPublicUrl(any())).thenReturn(publicUrl);

      final file = await _makeTempFile(extension: 'jpg');
      final result = await service.upload(userId: 'u1', filePath: file.path);

      expect(result, equals(publicUrl));
      verify(() => storage.from('avatars')).called(2);
      verify(
        () => fileApi.upload(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).called(1);
      verify(() => fileApi.getPublicUrl(any())).called(1);
    });

    test(
      'storage path includes userId and timestamp with correct extension',
      () async {
        final client = _MockSupabaseClient();
        final storage = _MockSupabaseStorageClient();
        final fileApi = _MockStorageFileApi();
        final service = SupabaseAvatarUploadService(client);

        when(() => client.storage).thenReturn(storage);
        when(() => storage.from(any())).thenReturn(fileApi);
        when(
          () => fileApi.upload(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => '');
        when(
          () => fileApi.getPublicUrl(any()),
        ).thenReturn('https://example.com');

        final file = await _makeTempFile(extension: 'png');
        await service.upload(userId: 'user-42', filePath: file.path);

        final captured =
            verify(
              () => fileApi.upload(
                captureAny(),
                any(),
                fileOptions: any(named: 'fileOptions'),
              ),
            ).captured;

        final path = captured.first as String;
        expect(path, startsWith('user-42/'));
        expect(path, endsWith('.png'));
      },
    );

    test('upsert FileOptions is passed to storage upload', () async {
      final client = _MockSupabaseClient();
      final storage = _MockSupabaseStorageClient();
      final fileApi = _MockStorageFileApi();
      final service = SupabaseAvatarUploadService(client);

      when(() => client.storage).thenReturn(storage);
      when(() => storage.from(any())).thenReturn(fileApi);
      when(
        () => fileApi.upload(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenAnswer((_) async => '');
      when(() => fileApi.getPublicUrl(any())).thenReturn('https://example.com');

      final file = await _makeTempFile(extension: 'webp');
      await service.upload(userId: 'u1', filePath: file.path);

      final captured =
          verify(
            () => fileApi.upload(
              any(),
              any(),
              fileOptions: captureAny(named: 'fileOptions'),
            ),
          ).captured;

      final opts = captured.first as FileOptions;
      expect(opts.upsert, isTrue);
    });

    test('maxFileSizeBytes is 15 MiB', () {
      expect(
        SupabaseAvatarUploadService.maxFileSizeBytes,
        equals(15 * 1024 * 1024),
      );
    });
  });
}
