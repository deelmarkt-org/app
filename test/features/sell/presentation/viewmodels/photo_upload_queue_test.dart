import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

// ---------------------------------------------------------------------------
// Minimal Supabase mock so _FakeService can satisfy the base class constructor
// without a live Supabase session. All upload/delete methods are overridden.
// ---------------------------------------------------------------------------
class _MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Fake ImageUploadService (no network needed)
// ---------------------------------------------------------------------------

enum _FakeBehavior { succeed, throwNetwork, throwBlocked }

class _FakeService extends ImageUploadService {
  _FakeService._() : super(_MockSupabaseClient());

  static _FakeService create([_FakeBehavior b = _FakeBehavior.succeed]) {
    return _FakeService._()..behavior = b;
  }

  _FakeBehavior behavior = _FakeBehavior.succeed;

  static const _fakeResponse = ImageUploadResponse(
    storagePath: 'uid/fake.jpg',
    deliveryUrl: 'https://cdn/fake.jpg',
    publicId: 'uid/fake',
    width: 800,
    height: 600,
    bytes: 50000,
    format: 'jpg',
  );

  @override
  Future<ImageUploadResponse> uploadAndProcess(File localFile) async {
    // Yield control so cancellation tokens can be set before processing.
    await Future<void>.delayed(Duration.zero);

    switch (behavior) {
      case _FakeBehavior.succeed:
        return _fakeResponse;
      case _FakeBehavior.throwNetwork:
        throw const NetworkException(debugMessage: 'fake network error');
      case _FakeBehavior.throwBlocked:
        throw const ValidationException(
          'error.image.blocked',
          debugMessage: 'fake blocked',
        );
    }
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PhotoUploadQueue _makeQueue(
  ImageUploadService svc, {
  int maxAttempts = 3,
  int maxConcurrent = 1,
}) {
  return PhotoUploadQueue(
    service: svc,
    maxConcurrent: maxConcurrent,
    maxAttempts: maxAttempts,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PhotoUploadQueue', () {
    late _FakeService service;

    setUp(() {
      service = _FakeService.create();
    });

    test('enqueue → Started then Succeeded', () async {
      final queue = _makeQueue(service);
      addTearDown(queue.dispose);

      final outcomesFuture = queue.outcomes.take(2).toList();
      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

      final outcomes = await outcomesFuture;
      expect(outcomes[0], isA<PhotoUploadStarted>());
      expect((outcomes[0] as PhotoUploadStarted).id, 'img-1');
      expect(outcomes[1], isA<PhotoUploadSucceeded>());
      expect((outcomes[1] as PhotoUploadSucceeded).id, 'img-1');
    });

    test('succeeded outcome carries ImageUploadResponse', () async {
      final queue = _makeQueue(service);
      addTearDown(queue.dispose);

      final outcomesFuture = queue.outcomes.take(2).toList();
      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

      final outcomes = await outcomesFuture;
      final succeeded = outcomes[1] as PhotoUploadSucceeded;
      expect(succeeded.response.deliveryUrl, 'https://cdn/fake.jpg');
      expect(succeeded.response.publicId, 'uid/fake');
    });

    test(
      'cancel before queue processes: no Succeeded/Failed for that id',
      () async {
        final queue = _makeQueue(service);
        addTearDown(queue.dispose);

        final collected = <PhotoUploadOutcome>[];
        final sub = queue.outcomes.listen(collected.add);

        queue
          ..enqueue(id: 'img-cancel', localPath: '/tmp/img-cancel.jpg')
          // Cancel immediately — before the async upload starts.
          ..cancel('img-cancel');

        // Wait briefly to let any pending microtasks settle.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        final succeeded = collected.whereType<PhotoUploadSucceeded>();
        final failed = collected.whereType<PhotoUploadFailed>();
        expect(succeeded.where((o) => o.id == 'img-cancel'), isEmpty);
        expect(failed.where((o) => o.id == 'img-cancel'), isEmpty);
      },
    );

    test('cancel of non-existent id is a no-op', () {
      final queue = _makeQueue(service);
      addTearDown(queue.dispose);
      expect(() => queue.cancel('does-not-exist'), returnsNormally);
    });

    test(
      'non-retryable failure → Started then Failed immediately (no retry)',
      () async {
        final blockedService = _FakeService.create(_FakeBehavior.throwBlocked);
        final queue = _makeQueue(blockedService);
        addTearDown(queue.dispose);

        final outcomesFuture = queue.outcomes.take(2).toList();
        queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

        final outcomes = await outcomesFuture;
        expect(outcomes[0], isA<PhotoUploadStarted>());
        expect(outcomes[1], isA<PhotoUploadFailed>());
        final failed = outcomes[1] as PhotoUploadFailed;
        expect(failed.isRetryable, isFalse);
      },
    );

    test('network failure is retryable', () async {
      final networkService = _FakeService.create(_FakeBehavior.throwNetwork);
      final queue = _makeQueue(networkService, maxAttempts: 2);
      addTearDown(queue.dispose);

      final outcomesFuture = queue.outcomes.take(2).toList();
      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

      final outcomes = await outcomesFuture.timeout(const Duration(seconds: 5));
      final failed = outcomes[1] as PhotoUploadFailed;
      expect(failed.isRetryable, isTrue);
    });

    test('inFlight is 0 after completion', () async {
      final queue = _makeQueue(service);
      addTearDown(queue.dispose);

      final outcomesFuture = queue.outcomes.take(2).toList();
      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

      await outcomesFuture;
      expect(queue.inFlight, 0);
    });

    test(
      'idempotent enqueue: same id enqueued twice only processes once',
      () async {
        final queue = _makeQueue(service);
        addTearDown(queue.dispose);

        final outcomes = <PhotoUploadOutcome>[];
        final sub = queue.outcomes.listen(outcomes.add);

        queue
          ..enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg')
          ..enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg'); // duplicate

        await Future<void>.delayed(const Duration(milliseconds: 100));
        await sub.cancel();

        final startedCount = outcomes.whereType<PhotoUploadStarted>().length;
        expect(startedCount, 1);
      },
    );

    test('retryable failure → retry → success on second attempt', () async {
      var callCount = 0;
      final mixedService = _CallCountService(
        onCall: () {
          callCount++;
          if (callCount == 1) {
            throw const NetworkException(debugMessage: 'first call network');
          }
          return _FakeService._fakeResponse;
        },
      );

      final queue = PhotoUploadQueue(
        service: mixedService,
        maxConcurrent: 1,
        maxAttempts: 2,
      );
      addTearDown(queue.dispose);

      final outcomesFuture = queue.outcomes.take(2).toList();
      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

      final outcomes = await outcomesFuture.timeout(const Duration(seconds: 5));
      expect(outcomes[0], isA<PhotoUploadStarted>());
      expect(outcomes[1], isA<PhotoUploadSucceeded>());
      expect(callCount, 2); // confirms a retry did occur
    });
  });
}

// ---------------------------------------------------------------------------
// Helper service that delegates to a callback for each upload call
// ---------------------------------------------------------------------------

class _CallCountService extends ImageUploadService {
  _CallCountService({required this.onCall}) : super(_MockSupabaseClient());

  final ImageUploadResponse Function() onCall;

  @override
  Future<ImageUploadResponse> uploadAndProcess(File localFile) async {
    await Future<void>.delayed(Duration.zero);
    return onCall();
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {}
}
