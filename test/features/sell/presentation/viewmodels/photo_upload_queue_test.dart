import 'package:flutter_test/flutter_test.dart';

import 'package:deelmarkt/features/sell/domain/entities/uploaded_image.dart';
import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';
import 'package:deelmarkt/features/sell/domain/repositories/image_upload_repository.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

// ---------------------------------------------------------------------------
// Fake repository
// ---------------------------------------------------------------------------

enum _FakeBehavior { succeed, throwNetwork, throwBlocked }

class _FakeRepo implements ImageUploadRepository {
  _FakeBehavior behavior = _FakeBehavior.succeed;

  static const _fakeImage = UploadedImage(
    storagePath: 'uid/fake.jpg',
    deliveryUrl: 'https://cdn/fake.jpg',
    publicId: 'uid/fake',
    width: 800,
    height: 600,
    bytes: 50000,
    format: 'jpg',
  );

  @override
  Future<UploadedImage> upload({
    required String id,
    required String localPath,
    CancellationToken? token,
  }) async {
    // Yield control to allow cancellation tokens to be set before we process.
    await Future<void>.delayed(Duration.zero);
    token?.throwIfCancelled();

    switch (behavior) {
      case _FakeBehavior.succeed:
        return _fakeImage;
      case _FakeBehavior.throwNetwork:
        throw const ImageUploadNetworkException();
      case _FakeBehavior.throwBlocked:
        throw const ImageUploadBlockedException();
    }
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {}
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PhotoUploadQueue _makeQueue(
  _FakeRepo repo, {
  int maxAttempts = 3,
  int maxConcurrent = 1,
}) {
  return PhotoUploadQueue(
    repository: repo,
    maxConcurrent: maxConcurrent,
    maxAttempts: maxAttempts,
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PhotoUploadQueue', () {
    late _FakeRepo repo;

    setUp(() {
      repo = _FakeRepo();
    });

    test('enqueue → Started then Succeeded', () async {
      final queue = _makeQueue(repo);
      addTearDown(queue.dispose);

      final outcomesFuture = queue.outcomes.take(2).toList();
      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

      final outcomes = await outcomesFuture;
      expect(outcomes[0], isA<PhotoUploadStarted>());
      expect((outcomes[0] as PhotoUploadStarted).id, 'img-1');
      expect(outcomes[1], isA<PhotoUploadSucceeded>());
      expect((outcomes[1] as PhotoUploadSucceeded).id, 'img-1');
    });

    test(
      'cancel before queue processes: no Succeeded/Failed for that id',
      () async {
        final queue = _makeQueue(repo);
        addTearDown(queue.dispose);

        // Collect outcomes for a short window.
        final collected = <PhotoUploadOutcome>[];
        final sub = queue.outcomes.listen(collected.add);

        queue
          ..enqueue(id: 'img-cancel', localPath: '/tmp/img-cancel.jpg')
          // Cancel immediately — before the async upload starts.
          ..cancel('img-cancel');

        // Wait briefly to let any pending microtasks settle.
        await Future<void>.delayed(const Duration(milliseconds: 50));
        await sub.cancel();

        // If Started was emitted before cancel, it may appear; but Succeeded/Failed must not.
        final succeeded = collected.whereType<PhotoUploadSucceeded>();
        final failed = collected.whereType<PhotoUploadFailed>();
        expect(succeeded.where((o) => o.id == 'img-cancel'), isEmpty);
        expect(failed.where((o) => o.id == 'img-cancel'), isEmpty);
      },
    );

    test('cancel of non-existent id is a no-op', () {
      final queue = _makeQueue(repo);
      addTearDown(queue.dispose);
      // Should not throw.
      expect(() => queue.cancel('does-not-exist'), returnsNormally);
    });

    test(
      'non-retryable failure → Started then Failed immediately (no retry)',
      () async {
        repo.behavior = _FakeBehavior.throwBlocked;
        final queue = _makeQueue(repo);
        addTearDown(queue.dispose);

        final outcomesFuture = queue.outcomes.take(2).toList();
        queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

        final outcomes = await outcomesFuture;
        expect(outcomes[0], isA<PhotoUploadStarted>());
        expect(outcomes[1], isA<PhotoUploadFailed>());
        final failed = outcomes[1] as PhotoUploadFailed;
        expect(failed.exception.isRetryable, isFalse);
      },
    );

    test('inFlight is 0 after completion', () async {
      final queue = _makeQueue(repo);
      addTearDown(queue.dispose);

      final outcomesFuture = queue.outcomes.take(2).toList();
      queue.enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg');

      await outcomesFuture;
      expect(queue.inFlight, 0);
    });

    test(
      'idempotent enqueue: same id enqueued twice only processes once',
      () async {
        final queue = _makeQueue(repo);
        addTearDown(queue.dispose);

        final outcomes = <PhotoUploadOutcome>[];
        final sub = queue.outcomes.listen(outcomes.add);

        queue
          ..enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg')
          ..enqueue(id: 'img-1', localPath: '/tmp/img-1.jpg'); // duplicate

        // Wait for the first upload to fully complete.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        await sub.cancel();

        final startedCount = outcomes.whereType<PhotoUploadStarted>().length;
        expect(startedCount, 1);
      },
    );

    test('retryable failure → retry → success on second attempt', () async {
      // First call throws network error, second call succeeds.
      var callCount = 0;
      final mixedRepo = _CallCountRepo(
        onCall: () {
          callCount++;
          if (callCount == 1) throw const ImageUploadNetworkException();
          return _FakeRepo._fakeImage;
        },
      );

      final queue = PhotoUploadQueue(
        repository: mixedRepo,
        maxConcurrent: 1,
        maxAttempts: 2,
      );
      addTearDown(queue.dispose);

      // The queue emits Started once (before the retry loop) then Succeeded.
      // Retries happen internally — no second Started is emitted.
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
// Helper repo that delegates to a callback for each upload call
// ---------------------------------------------------------------------------

class _CallCountRepo implements ImageUploadRepository {
  _CallCountRepo({required this.onCall});
  final UploadedImage Function() onCall;

  @override
  Future<UploadedImage> upload({
    required String id,
    required String localPath,
    CancellationToken? token,
  }) async {
    await Future<void>.delayed(Duration.zero);
    token?.throwIfCancelled();
    return onCall();
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {}
}
