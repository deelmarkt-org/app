import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/data.dart';
import 'package:uuid/uuid.dart';

import 'package:deelmarkt/features/sell/data/repositories/supabase_image_upload_repository.dart';
import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';

// ---------------------------------------------------------------------------
// Mocks (duplicated lightly from the sibling test file — both files are
// independent suites with their own setUp lifecycle).
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

const _userId = 'user-abc';
const _fixedUuid = 'fixed-uuid-1234';

Map<String, dynamic> _validResponseData() => {
  'storage_path': '$_userId/$_fixedUuid.jpg',
  'delivery_url': 'https://cdn.example.com/$_userId/$_fixedUuid.jpg',
  'public_id': 'pub-1',
  'width': 800,
  'height': 600,
  'bytes': 12345,
  'format': 'jpg',
};

Future<String> _createTempFile(String extension) async {
  final dir = await Directory.systemTemp.createTemp('img_upload_test_');
  final file = File('${dir.path}/photo.$extension');
  await file.writeAsBytes(List<int>.filled(64, 0));
  addTearDown(() async {
    try {
      await dir.delete(recursive: true);
    } on FileSystemException {
      // best-effort cleanup
    }
  });
  return file.path;
}

void main() {
  setUpAll(() {
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

    // Common arrangement — authenticated + storage + functions wired.
    when(() => client.auth).thenReturn(auth);
    when(() => auth.currentUser).thenReturn(_StubUser(id: _userId));
    when(() => client.storage).thenReturn(storage);
    when(() => storage.from(any())).thenReturn(fileApi);
    when(() => client.functions).thenReturn(functions);

    // Default happy Storage upload stub — most tests override only the
    // functions.invoke() behaviour.
    when(
      () => fileApi.uploadBinary(
        any(),
        any(),
        fileOptions: any(named: 'fileOptions'),
      ),
    ).thenAnswer((_) async => 'ok');
  });

  // =========================================================================
  // upload() — Edge Function happy path
  // =========================================================================

  group('upload() — Edge Function happy path', () {
    test('returns UploadedImage parsed from response payload', () async {
      final path = await _createTempFile('jpg');
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: _validResponseData()),
      );

      final result = await repo.upload(id: 'i1', localPath: path);

      expect(result.storagePath, equals('$_userId/$_fixedUuid.jpg'));
      expect(
        result.deliveryUrl,
        equals('https://cdn.example.com/$_userId/$_fixedUuid.jpg'),
      );
      expect(result.publicId, equals('pub-1'));
      expect(result.width, equals(800));
      expect(result.height, equals(600));
      expect(result.bytes, equals(12345));
      expect(result.format, equals('jpg'));
    });

    test('passes storage_path to the Edge Function body', () async {
      final path = await _createTempFile('png');
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: _validResponseData()),
      );

      await repo.upload(id: 'i1', localPath: path);

      final captured =
          verify(
                () => functions.invoke(
                  'image-upload-process',
                  body: captureAny(named: 'body'),
                ),
              ).captured.single
              as Map<String, dynamic>;
      expect(captured['storage_path'], equals('$_userId/$_fixedUuid.png'));
    });
  });

  // =========================================================================
  // upload() — Edge Function error status mapping
  // =========================================================================

  group('upload() — Edge Function status mapping', () {
    late String path;

    setUp(() async {
      path = await _createTempFile('jpg');
    });

    Future<void> expectStatus(int status, Type exceptionType) async {
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenAnswer((_) async => FunctionResponse(status: status, data: {}));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(predicate((e) => e.runtimeType == exceptionType)),
      );
    }

    test('status 401 → ImageUploadAuthException', () async {
      await expectStatus(401, ImageUploadAuthException);
    });

    test('status 403 → ImageUploadAuthException', () async {
      await expectStatus(403, ImageUploadAuthException);
    });

    test('status 413 → ImageUploadTooLargeException', () async {
      await expectStatus(413, ImageUploadTooLargeException);
    });

    test('status 422 → ImageUploadBlockedException', () async {
      await expectStatus(422, ImageUploadBlockedException);
    });

    test('status 429 → ImageUploadServerException', () async {
      await expectStatus(429, ImageUploadServerException);
    });

    test('status 500 → ImageUploadServerException', () async {
      await expectStatus(500, ImageUploadServerException);
    });

    test('status 502 → ImageUploadServerException', () async {
      await expectStatus(502, ImageUploadServerException);
    });

    test('status 503 → ImageUploadServerException', () async {
      await expectStatus(503, ImageUploadServerException);
    });

    test('status 400 → ImageUploadInvalidException', () async {
      await expectStatus(400, ImageUploadInvalidException);
    });

    test('status 404 → ImageUploadInvalidException', () async {
      await expectStatus(404, ImageUploadInvalidException);
    });
  });

  // =========================================================================
  // upload() — Edge Function exception + invalid response
  // =========================================================================

  group('upload() — Edge Function exception paths', () {
    test('FunctionException is mapped via status code', () async {
      final path = await _createTempFile('jpg');
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenThrow(const FunctionException(status: 500, reasonPhrase: 'boom'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadServerException>()),
      );
    });

    test('generic exception → ImageUploadNetworkException', () async {
      final path = await _createTempFile('jpg');
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenThrow(Exception('dns failure'));

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadNetworkException>()),
      );
    });

    test('non-map data → ImageUploadInvalidException', () async {
      final path = await _createTempFile('jpg');
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => FunctionResponse(status: 200, data: 'not-a-map'),
      );

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadInvalidException>()),
      );
    });

    test('missing fields in response → ImageUploadInvalidException', () async {
      final path = await _createTempFile('jpg');
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenAnswer(
        (_) async => FunctionResponse(
          status: 200,
          data: <String, dynamic>{'storage_path': 'x'},
        ),
      );

      await expectLater(
        repo.upload(id: 'i1', localPath: path),
        throwsA(isA<ImageUploadInvalidException>()),
      );
    });
  });

  // =========================================================================
  // upload() — CancellationToken checkpoints
  // =========================================================================

  group('upload() — CancellationToken', () {
    test('CP-1: pre-cancelled token aborts before any work', () async {
      final token = CancellationToken()..cancel();

      await expectLater(
        repo.upload(id: 'i1', localPath: '/tmp/photo.jpg', token: token),
        throwsA(isA<ImageUploadCancelledException>()),
      );
      verifyNever(() => client.storage);
    });
  });

  // =========================================================================
  // deleteStorageObject()
  // =========================================================================

  group('deleteStorageObject()', () {
    test('calls remove() on the listings-images bucket', () async {
      when(() => fileApi.remove(any())).thenAnswer((_) async => []);

      await repo.deleteStorageObject('$_userId/$_fixedUuid.jpg');

      verify(() => storage.from('listings-images')).called(1);
      verify(() => fileApi.remove(['$_userId/$_fixedUuid.jpg'])).called(1);
    });

    test('swallows storage errors (best-effort cleanup)', () async {
      when(
        () => fileApi.remove(any()),
      ).thenThrow(const StorageException('boom', statusCode: '500'));

      // Must not throw.
      await repo.deleteStorageObject('$_userId/$_fixedUuid.jpg');
    });

    test('swallows unexpected errors (best-effort cleanup)', () async {
      when(() => fileApi.remove(any())).thenThrow(Exception('network'));

      await repo.deleteStorageObject('$_userId/$_fixedUuid.jpg');
    });
  });
}
