import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
// Hide gotrue.AuthException so it doesn't collide with our domain one.
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthException;

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';

// ---------------------------------------------------------------------------
// Mocks
// ---------------------------------------------------------------------------

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSupabaseStorageClient extends Mock implements SupabaseStorageClient {}

class MockStorageFileApi extends Mock implements StorageFileApi {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

/// Fake [User] with a fixed id. Avoids stubbing non-nullable getters
/// through `when()`, which poisons mocktail's _whenCall state.
class _StubUser extends Fake implements User {
  _StubUser({required this.id});

  @override
  final String id;
}

// ---------------------------------------------------------------------------
// Fixtures
// ---------------------------------------------------------------------------

/// A valid UUIDv4 so generated storage paths pass the EF regex.
const _userId = '550e8400-e29b-41d4-a716-446655440000';

const _successResponse = <String, dynamic>{
  'storage_path': '$_userId/test.jpg',
  'delivery_url': 'https://res.cloudinary.com/demo/image/upload/v1/test.jpg',
  'public_id': 'listings/$_userId/test',
  'width': 800,
  'height': 600,
  'bytes': 123456,
  'format': 'jpg',
};

/// Creates a tiny temporary file the service can read for size + upload.
/// The returned file is auto-deleted via [addTearDown].
Future<File> _makeTempFile({
  required String extension,
  int sizeBytes = 1024,
}) async {
  final dir = await Directory.systemTemp.createTemp('image_upload_test');
  addTearDown(() async {
    if (dir.existsSync()) {
      await dir.delete(recursive: true);
    }
  });
  final file = File('${dir.path}/photo.$extension');
  await file.writeAsBytes(List<int>.filled(sizeBytes, 0));
  return file;
}

void main() {
  late MockSupabaseClient client;
  late MockGoTrueClient auth;
  late MockSupabaseStorageClient storage;
  late MockStorageFileApi fileApi;
  late MockFunctionsClient functions;
  late ImageUploadService service;

  setUpAll(() {
    registerFallbackValue(File('fallback.jpg'));
  });

  setUp(() {
    client = MockSupabaseClient();
    auth = MockGoTrueClient();
    storage = MockSupabaseStorageClient();
    fileApi = MockStorageFileApi();
    functions = MockFunctionsClient();

    when(() => client.auth).thenReturn(auth);
    when(() => client.storage).thenReturn(storage);
    when(() => client.functions).thenReturn(functions);
    when(() => storage.from(any())).thenReturn(fileApi);

    service = ImageUploadService(client);
  });

  void arrangeAuthenticated() {
    when(() => auth.currentUser).thenReturn(_StubUser(id: _userId));
  }

  void arrangeSuccessfulStorageUpload() {
    when(() => fileApi.upload(any(), any())).thenAnswer((_) async => 'ok');
  }

  void arrangeEfResponse(FunctionResponse response) {
    when(
      () => functions.invoke('image-upload-process', body: any(named: 'body')),
    ).thenAnswer((_) async => response);
  }

  group('ImageUploadService.uploadAndProcess — happy path', () {
    test('returns typed response on 200', () async {
      arrangeAuthenticated();
      arrangeSuccessfulStorageUpload();
      arrangeEfResponse(FunctionResponse(status: 200, data: _successResponse));

      final file = await _makeTempFile(extension: 'jpg');
      final result = await service.uploadAndProcess(file);

      expect(result.deliveryUrl, _successResponse['delivery_url']);
      expect(result.width, 800);
      expect(result.height, 600);
      expect(result.bytes, 123456);
      expect(result.format, 'jpg');
    });

    test(
      'uploads to listings-images bucket under the user id folder',
      () async {
        arrangeAuthenticated();
        arrangeSuccessfulStorageUpload();
        arrangeEfResponse(
          FunctionResponse(status: 200, data: _successResponse),
        );

        String? capturedPath;
        when(() => fileApi.upload(any(), any())).thenAnswer((invocation) async {
          capturedPath = invocation.positionalArguments[0] as String;
          return 'ok';
        });

        await service.uploadAndProcess(await _makeTempFile(extension: 'png'));

        verify(() => storage.from('listings-images')).called(1);
        expect(capturedPath, isNotNull);
        expect(capturedPath!.startsWith('$_userId/'), isTrue);
        expect(capturedPath!.endsWith('.png'), isTrue);
        // Regex from the EF: user_id (UUID) / filename.ext
        final regex = RegExp(
          r'^[a-f0-9-]{36}/[A-Za-z0-9._-]+\.[A-Za-z0-9]{2,5}$',
        );
        expect(regex.hasMatch(capturedPath!), isTrue);
      },
    );

    test('forwards the generated path to the EF body', () async {
      arrangeAuthenticated();
      arrangeSuccessfulStorageUpload();

      String? capturedStoragePathInEf;
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenAnswer((invocation) async {
        final body = invocation.namedArguments[#body] as Map<String, dynamic>;
        capturedStoragePathInEf = body['storage_path'] as String?;
        return FunctionResponse(status: 200, data: _successResponse);
      });

      await service.uploadAndProcess(await _makeTempFile(extension: 'jpg'));

      expect(capturedStoragePathInEf, isNotNull);
      expect(capturedStoragePathInEf!.startsWith('$_userId/'), isTrue);
    });
  });

  group('ImageUploadService.uploadAndProcess — client-side rejections', () {
    test('throws AuthException when no user is signed in', () async {
      when(() => auth.currentUser).thenReturn(null);

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.auth.unauthenticated',
          ),
        ),
      );
      verifyNever(() => fileApi.upload(any(), any()));
      verifyNever(() => functions.invoke(any(), body: any(named: 'body')));
    });

    test('rejects files over 15 MiB before touching storage', () async {
      arrangeAuthenticated();

      final bigFile = await _makeTempFile(
        extension: 'jpg',
        sizeBytes: ImageUploadService.maxBytes + 1,
      );

      await expectLater(
        service.uploadAndProcess(bigFile),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.too_large',
          ),
        ),
      );
      verifyNever(() => fileApi.upload(any(), any()));
      verifyNever(() => functions.invoke(any(), body: any(named: 'body')));
    });

    test('rejects unsupported extensions', () async {
      arrangeAuthenticated();

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'bmp')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.unsupported_format',
          ),
        ),
      );
      verifyNever(() => fileApi.upload(any(), any()));
    });
  });

  group('ImageUploadService.uploadAndProcess — server-side rejections', () {
    setUp(() {
      arrangeAuthenticated();
      arrangeSuccessfulStorageUpload();
    });

    test('401 → AuthException', () async {
      arrangeEfResponse(
        FunctionResponse(status: 401, data: const {'error': 'Unauthorized'}),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.auth.unauthenticated',
          ),
        ),
      );
    });

    test('403 → AuthException with ownership_mismatch key', () async {
      arrangeEfResponse(
        FunctionResponse(
          status: 403,
          data: const {'error': 'Path ownership mismatch'},
        ),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<AuthException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.ownership_mismatch',
          ),
        ),
      );
    });

    test('413 → ValidationException(too_large)', () async {
      arrangeEfResponse(
        FunctionResponse(
          status: 413,
          data: const {'error': 'File exceeds 15 MiB limit'},
        ),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.too_large',
          ),
        ),
      );
    });

    test(
      '422 → ValidationException(blocked) with threat in debugMessage',
      () async {
        arrangeEfResponse(
          FunctionResponse(
            status: 422,
            data: const {'error': 'Image blocked: virus: Eicar-Test'},
          ),
        );

        await expectLater(
          service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
          throwsA(
            isA<ValidationException>()
                .having(
                  (e) => e.messageKey,
                  'messageKey',
                  'error.image.blocked',
                )
                .having(
                  (e) => e.debugMessage,
                  'debugMessage',
                  contains('Eicar-Test'),
                ),
          ),
        );
      },
    );

    test('429 → ValidationException(rate_limited)', () async {
      arrangeEfResponse(
        FunctionResponse(
          status: 429,
          data: const {
            'error': 'Too many image uploads.',
            'retry_after_seconds': 120,
          },
        ),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<ValidationException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.rate_limited',
          ),
        ),
      );
    });

    test('502 → NetworkException (Cloudinary outage)', () async {
      arrangeEfResponse(
        FunctionResponse(
          status: 502,
          data: const {'error': 'Image upload failed'},
        ),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(isA<NetworkException>()),
      );
    });

    test('503 → NetworkException (scan unavailable)', () async {
      arrangeEfResponse(
        FunctionResponse(
          status: 503,
          data: const {'error': 'Virus scan unavailable'},
        ),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(isA<NetworkException>()),
      );
    });

    test(
      'Storage upload failure → NetworkException before EF is called',
      () async {
        when(
          () => fileApi.upload(any(), any()),
        ).thenThrow(const StorageException('Bucket policy denied'));

        await expectLater(
          service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
          throwsA(isA<NetworkException>()),
        );
        verifyNever(() => functions.invoke(any(), body: any(named: 'body')));
      },
    );

    test('FunctionException → NetworkException', () async {
      when(
        () =>
            functions.invoke('image-upload-process', body: any(named: 'body')),
      ).thenThrow(
        const FunctionException(
          status: 503,
          reasonPhrase: 'Service Unavailable',
        ),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(isA<NetworkException>()),
      );
    });
  });
}
