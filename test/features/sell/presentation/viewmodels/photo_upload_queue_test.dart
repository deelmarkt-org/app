import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
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

  static const _fakePath = 'uid/fake.jpg';

  static const _fakeResponse = ImageUploadResponse(
    storagePath: 'uid/fake.jpg',
    deliveryUrl: 'https://cdn/fake.jpg',
    publicId: 'uid/fake',
    width: 800,
    height: 600,
    bytes: 50000,
    format: 'jpg',
  );

  /// Phase 1 refactored the queue to call reserveAndUpload + processUploaded
  /// separately (for orphan-cleanup on cancellation). Fakes must match.
  @override
  Future<String> reserveAndUpload(File localFile) async {
    await Future<void>.delayed(Duration.zero);
    switch (behavior) {
      case _FakeBehavior.succeed:
        return _fakePath;
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
  Future<ImageUploadResponse> processUploaded(String storagePath) async {
    await Future<void>.delayed(Duration.zero);
    return _fakeResponse;
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

    // ── Coverage for PR #175 review fixes (M-1, M-2) ──

    test(
      'orphan cleanup swallows deleteStorageObject failure (no rethrow)',
      () async {
        // State B: reserveAndUpload succeeds, processUploaded blocks long
        // enough for the user to cancel — triggers _deleteOrphan path.
        final svc = _OrphanCleanupService(deleteThrows: true);
        final queue = _makeQueue(svc);
        addTearDown(queue.dispose);

        final outcomesFuture =
            queue.outcomes
                .take(1)
                .toList(); // only Started — cancel discards the rest

        queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');
        // Allow reserveAndUpload to complete and processUploaded to start.
        await Future<void>.delayed(const Duration(milliseconds: 30));
        queue.cancel('img-1');

        // Wait for the run to drain. If the unguarded exception escaped, the
        // future would never complete or would surface as an unhandled error.
        await outcomesFuture.timeout(const Duration(seconds: 2));
        expect(svc.deleteCallCount, 1);
        // Cancellation: only Started should have been emitted.
      },
    );

    test('cancel during backoff returns silently (no Failed emitted)', () async {
      // First attempt fails (retryable network) → enters backoff. We cancel
      // while the backoff timer is still pending, exercising the
      // UploadCancelledException catch around _backoff().
      var attempts = 0;
      final svc = _CallCountService(
        onCall: () {
          attempts++;
          throw const NetworkException(debugMessage: 'first attempt fails');
        },
      );
      final queue = _makeQueue(svc, maxAttempts: 5);
      addTearDown(queue.dispose);

      // Collect outcomes for 200ms to verify no Failed event fires.
      final emitted = <PhotoUploadOutcome>[];
      final sub = queue.outcomes.listen(emitted.add);
      addTearDown(sub.cancel);

      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');
      // Allow first attempt to fail and the backoff sleep to start.
      await Future<void>.delayed(const Duration(milliseconds: 20));
      queue.cancel('img-1');
      // Drain pending microtasks + any in-flight backoff (full jitter ≤ 500ms).
      await Future<void>.delayed(const Duration(milliseconds: 600));

      expect(attempts, 1); // no retry happened after cancel
      expect(emitted.whereType<PhotoUploadFailed>().isEmpty, isTrue);
    });
  });
}

// ---------------------------------------------------------------------------
// Service that holds processUploaded open so we can cancel during State B
// (upload completed, processing in-flight) and toggles delete failure.
// ---------------------------------------------------------------------------

class _OrphanCleanupService extends ImageUploadService {
  _OrphanCleanupService({required this.deleteThrows})
    : super(_MockSupabaseClient());

  final bool deleteThrows;
  int deleteCallCount = 0;

  @override
  Future<String> reserveAndUpload(File localFile) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return _FakeService._fakePath;
  }

  @override
  Future<ImageUploadResponse> processUploaded(String storagePath) async {
    // Simulate a cooperative cancel detected during processing — fires the
    // orphan-cleanup branch (uploadCompleted=true, processingCompleted=false).
    await Future<void>.delayed(const Duration(milliseconds: 5));
    throw const UploadCancelledException();
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {
    deleteCallCount++;
    if (deleteThrows) {
      throw const NetworkException(debugMessage: 'storage cleanup down');
    }
  }
}

// ---------------------------------------------------------------------------
// Helper service that delegates to a callback for each upload call
// ---------------------------------------------------------------------------

class _CallCountService extends ImageUploadService {
  _CallCountService({required this.onCall}) : super(_MockSupabaseClient());

  /// Called once per upload attempt (in reserveAndUpload).
  /// Throw to simulate failure; return anything to simulate success.
  final ImageUploadResponse Function() onCall;

  @override
  Future<String> reserveAndUpload(File localFile) async {
    await Future<void>.delayed(Duration.zero);
    onCall(); // increments callCount; throws on failure attempts
    return _FakeService._fakePath;
  }

  @override
  Future<ImageUploadResponse> processUploaded(String storagePath) async {
    await Future<void>.delayed(Duration.zero);
    return _FakeService._fakeResponse;
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {}
}
