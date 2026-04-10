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

  /// Arranges a non-2xx Edge Function response the way supabase_flutter
  /// actually surfaces it: `FunctionsClient.invoke()` throws a
  /// `FunctionException` on any status >= 300. Tests that use
  /// `FunctionResponse(status: 4xx)` via thenAnswer exercise dead code,
  /// so server-side error paths must route through this helper.
  void arrangeEfFailure(int status, Map<String, dynamic>? details) {
    when(
      () => functions.invoke('image-upload-process', body: any(named: 'body')),
    ).thenThrow(FunctionException(status: status, details: details));
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

  // supabase_flutter's FunctionsClient throws FunctionException on any
  // non-2xx — it never returns a FunctionResponse with status >= 300.
  // Tests in this group all route through `arrangeEfFailure` so they
  // exercise the real error-handling code path, not dead code.
  group('ImageUploadService.uploadAndProcess — server-side rejections', () {
    setUp(() {
      arrangeAuthenticated();
      arrangeSuccessfulStorageUpload();
    });

    test('401 → AuthException(error.auth.unauthenticated)', () async {
      arrangeEfFailure(401, const {'error': 'Unauthorized'});

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

    test('403 → AuthException(error.image.ownership_mismatch)', () async {
      arrangeEfFailure(403, const {'error': 'Path ownership mismatch'});

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

    test('404 → NetworkException(error.image.not_found)', () async {
      arrangeEfFailure(404, const {'error': 'Storage object not found'});

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.not_found',
          ),
        ),
      );
    });

    test('413 → ValidationException(error.image.too_large)', () async {
      arrangeEfFailure(413, const {'error': 'File exceeds 15 MiB limit'});

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
        arrangeEfFailure(422, const {
          'error': 'Image blocked: virus: Eicar-Test',
        });

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

    test(
      '429 → ValidationException(rate_limited) with retry in debugMessage',
      () async {
        arrangeEfFailure(429, const {
          'error': 'Too many image uploads.',
          'retry_after_seconds': 120,
        });

        await expectLater(
          service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
          throwsA(
            isA<ValidationException>()
                .having(
                  (e) => e.messageKey,
                  'messageKey',
                  'error.image.rate_limited',
                )
                .having((e) => e.debugMessage, 'debugMessage', contains('120')),
          ),
        );
      },
    );

    test('502 → NetworkException(error.image.upload_failed)', () async {
      arrangeEfFailure(502, const {'error': 'Image upload failed'});

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.upload_failed',
          ),
        ),
      );
    });

    test('503 → NetworkException(error.image.scan_unavailable)', () async {
      arrangeEfFailure(503, const {'error': 'Virus scan unavailable'});

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.scan_unavailable',
          ),
        ),
      );
    });

    test('unknown 5xx → NetworkException(error.network)', () async {
      arrangeEfFailure(599, const {'error': 'Unknown'});

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.network',
          ),
        ),
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

    test('Happy-path 200 with a malformed body → NetworkException', () async {
      // Unlike the other server rejections, this one tests the
      // parsing-failure branch in _invokeProcessingFunction: the EF
      // returned 200 but the payload is missing required fields.
      arrangeEfResponse(
        FunctionResponse(status: 200, data: const {'storage_path': 'x/y.jpg'}),
      );

      await expectLater(
        service.uploadAndProcess(await _makeTempFile(extension: 'jpg')),
        throwsA(
          isA<NetworkException>().having(
            (e) => e.messageKey,
            'messageKey',
            'error.image.upload_failed',
          ),
        ),
      );
    });
  });
}
