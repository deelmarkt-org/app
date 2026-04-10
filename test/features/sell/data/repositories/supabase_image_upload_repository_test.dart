import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

import 'package:deelmarkt/features/sell/data/repositories/supabase_image_upload_repository.dart';
import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class _StubUser extends Fake implements User {
  _StubUser({required this.id});

  @override
  final String id;
}

class _FixedUuid extends Fake implements Uuid {
  _FixedUuid(this._value);
  final String _value;

  @override
  String v4({Map<String, dynamic>? options, V4Options? config}) => _value;
}

// ---------------------------------------------------------------------------
// Fixtures / helpers
// ---------------------------------------------------------------------------

const _userId = 'user-abc';
const _fixedUuid = 'fixed-uuid-1234';

void _arrangeAuth(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(_StubUser(id: _userId));
}

void _arrangeUnauth(MockSupabaseClient client, MockGoTrueClient auth) {
  when(() => client.auth).thenReturn(auth);
  when(() => auth.currentUser).thenReturn(null);
}

void _arrangeStorage(
  MockSupabaseClient client,
  MockSupabaseStorageClient storage,
  MockStorageFileApi fileApi,
) {
  when(() => client.storage).thenReturn(storage);
  when(() => storage.from(any())).thenReturn(fileApi);
}

void _arrangeFunctions(
  MockSupabaseClient client,
  MockFunctionsClient functions,
) {
  when(() => client.functions).thenReturn(functions);
}

/// Writes a temporary file with [contents] and the given [extension].
/// Returns its absolute path. Cleaned up via [addTearDown].
Future<String> _createTempFile(String extension, {List<int>? contents}) async {
  final dir = await Directory.systemTemp.createTemp('img_upload_test_');
  final file = File('${dir.path}/photo.$extension');
  await file.writeAsBytes(contents ?? List<int>.filled(64, 0));
  addTearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // best-effort cleanup
    }
  });
  return file.path;
}

Map<String, dynamic> _validResponseData() => {
  'storage_path': '$_userId/$_fixedUuid.jpg',
  'delivery_url': 'https://cdn.example.com/$_userId/$_fixedUuid.jpg',
  'public_id': 'pub-1',
  'width': 800,
  'height': 600,
  'bytes': 12345,
  'format': 'jpg',
};

void main() {
  setUpAll(() {
    // Register fallback values for any() matchers on custom types.
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(const FileOptions());
  });

  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockFunctionsClient functions;
  late MockSupabaseStorageClient storage;
  late MockStorageFileApi fileApi;
  late SupabaseImageUploadRepository repo;

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    functions = MockFunctionsClient();
    storage = MockSupabaseStorageClient();
    fileApi = MockStorageFileApi();
    repo = SupabaseImageUploadRepository(client, uuid: _FixedUuid(_fixedUuid));
  });

  // =========================================================================
  // upload() — pre-flight validation
  // =========================================================================

  group('upload() — pre-flight validation', () {
    test('throws ImageUploadAuthException when user not signed in', () async {
      _arrangeUnauth(client, auth);
      final path = await _createTempFile('jpg');

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadAuthException>()),
      );
    });

    test(
      'throws ImageUploadInvalidException when path has no extension',
      () async {
        _arrangeAuth(client, auth);

        await expectLater(
          repo.upload(id: 'i1', localPath: '/tmp/no_ext'),
          throwsA(isA<ImageUploadInvalidException>()),
        );
      },
    );

    test(
      'throws ImageUploadInvalidException when extension is empty',
      () async {
        _arrangeAuth(client, auth);

        await expectLater(
          repo.upload(id: 'i1', localPath: '/tmp/photo.'),
          throwsA(isA<ImageUploadInvalidException>()),
        );
      },
    );

    test(
      'throws ImageUploadInvalidException when extension not allowed',
      () async {
        _arrangeAuth(client, auth);

        await expectLater(
          repo.upload(id: 'i1', localPath: '/tmp/photo.gif'),
          throwsA(isA<ImageUploadInvalidException>()),
        );
      },
    );

    test(
      'throws ImageUploadInvalidException when file does not exist',
      () async {
        _arrangeAuth(client, auth);
        _arrangeStorage(client, storage, fileApi);

        await expectLater(
          repo.upload(id: 'i1', localPath: '/definitely/not/here.jpg'),
          throwsA(isA<ImageUploadInvalidException>()),
        );
      },
    );

    test(
      'accepts all allowed extensions (jpg, jpeg, png, webp, heic)',
      () async {
        _arrangeAuth(client, auth);
        _arrangeStorage(client, storage, fileApi);
        _arrangeFunctions(client, functions);

        when(
          () => fileApi.uploadBinary(
            any(),
            any(),
            fileOptions: any(named: 'fileOptions'),
          ),
        ).thenAnswer((_) async => 'ok');
        when(
          () => functions.invoke(any(), body: any(named: 'body')),
        ).thenAnswer(
          (_) async =>
              FunctionResponse(status: 200, data: _validResponseData()),
        );

        for (final ext in ['jpg', 'jpeg', 'png', 'webp', 'heic']) {
          final path = await _createTempFile(ext);
          final result = await repo.upload(id: 'i', localPath: path);
          expect(result.format, equals('jpg'));
        }
      },
    );
  });

  // =========================================================================
  // upload() — file size guard
  // =========================================================================

  group('upload() — file size guard', () {
    test(
      'throws ImageUploadTooLargeException when file exceeds 15 MB',
      () async {
        _arrangeAuth(client, auth);
        _arrangeStorage(client, storage, fileApi);

        // Build a 15 MB + 1 byte file.
        final bigBytes = List<int>.filled(15 * 1024 * 1024 + 1, 0);
        final path = await _createTempFile('jpg', contents: bigBytes);

        await expectLater(
          repo.upload(id: 'i1', localPath: path),
          throwsA(isA<ImageUploadTooLargeException>()),
        );
      },
      // File writing 15MB is a bit slow, but still fast enough for CI.
    );
  });

  // =========================================================================
  // upload() — Storage step failures
  // =========================================================================

  group('upload() — Storage step failures', () {
    setUp(() {
      _arrangeAuth(client, auth);
      _arrangeStorage(client, storage, fileApi);
    });

    test('401 from storage → ImageUploadAuthException', () async {
      final path = await _createTempFile('jpg');
      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenThrow(const StorageException('denied', statusCode: '401'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadAuthException>()),
      );
    });

    test('403 from storage → ImageUploadAuthException', () async {
      final path = await _createTempFile('jpg');
      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenThrow(const StorageException('forbidden', statusCode: '403'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadAuthException>()),
      );
    });

    test('413 from storage → ImageUploadTooLargeException', () async {
      final path = await _createTempFile('jpg');
      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenThrow(const StorageException('too large', statusCode: '413'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadTooLargeException>()),
      );
    });

    test('500 from storage → ImageUploadServerException', () async {
      final path = await _createTempFile('jpg');
      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenThrow(const StorageException('boom', statusCode: '500'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadServerException>()),
      );
    });

    test('429 from storage → ImageUploadServerException', () async {
      final path = await _createTempFile('jpg');
      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenThrow(const StorageException('slow down', statusCode: '429'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadServerException>()),
      );
    });

    test('400 from storage → ImageUploadInvalidException', () async {
      final path = await _createTempFile('jpg');
      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenThrow(const StorageException('bad', statusCode: '400'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadInvalidException>()),
      );
    });

    test('generic error → ImageUploadNetworkException', () async {
      final path = await _createTempFile('jpg');
      when(
        () => fileApi.uploadBinary(
          any(),
          any(),
          fileOptions: any(named: 'fileOptions'),
        ),
      ).thenThrow(Exception('socket closed'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadNetworkException>()),
      );
    });
  });
}
