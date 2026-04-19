import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

// ---------------------------------------------------------------------------
// Supabase mock
// ---------------------------------------------------------------------------

class _MockSupabaseClient extends Mock implements SupabaseClient {}

// ---------------------------------------------------------------------------
// Shared fake data
// ---------------------------------------------------------------------------

const _fakePath = 'uid/fake.jpg';

const _fakeResponse = ImageUploadResponse(
  storagePath: 'uid/fake.jpg',
  deliveryUrl: 'https://cdn/fake.jpg',
  publicId: 'uid/fake',
  width: 800,
  height: 600,
  bytes: 50000,
  format: 'jpg',
);

// ---------------------------------------------------------------------------
// Controlled service — blocks in reserveAndUpload until the test signals it.
// Tracks whether deleteStorageObject was called and can be set to fail.
// ---------------------------------------------------------------------------

class _ControlledService extends ImageUploadService {
  _ControlledService() : super(_MockSupabaseClient());

  final _reserveCompleter = Completer<String>();
  var deleteWasCalled = false;
  var throwOnDelete = false;

  void completeReserve([String path = _fakePath]) =>
      _reserveCompleter.complete(path);

  @override
  Future<String> reserveAndUpload(File localFile) => _reserveCompleter.future;

  @override
  Future<ImageUploadResponse> processUploaded(String storagePath) async =>
      _fakeResponse;

  @override
  Future<void> deleteStorageObject(String storagePath) async {
    deleteWasCalled = true;
    if (throwOnDelete) throw Exception('storage failure');
  }
}

// ---------------------------------------------------------------------------
// Always-failing service (retryable NetworkException)
// ---------------------------------------------------------------------------

class _AlwaysNetworkErrorService extends ImageUploadService {
  _AlwaysNetworkErrorService() : super(_MockSupabaseClient());

  @override
  Future<String> reserveAndUpload(File localFile) async {
    await Future<void>.delayed(Duration.zero);
    throw const NetworkException(debugMessage: 'fake network error');
  }

  @override
  Future<ImageUploadResponse> processUploaded(String storagePath) async =>
      _fakeResponse;

  @override
  Future<void> deleteStorageObject(String storagePath) async {}
}

// ---------------------------------------------------------------------------
// Fixed-value Random so backoff delay is deterministic
// ---------------------------------------------------------------------------

class _FixedRandom implements Random {
  const _FixedRandom(this._fixed);
  final int _fixed;

  @override
  int nextInt(int max) => _fixed < max ? _fixed : max - 1;

  @override
  double nextDouble() => 0;

  @override
  bool nextBool() => false;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('PhotoUploadQueue — cancellation scenarios', () {
    test('cancel after storage write (State B) → orphan is deleted', () async {
      final svc = _ControlledService();
      final queue = PhotoUploadQueue(
        service: svc,
        maxConcurrent: 1,
        maxAttempts: 1,
      );
      addTearDown(queue.dispose);

      queue.enqueue(id: 'img-orphan', localPath: '/tmp/img.jpg');

      // Yield so _runJob reaches the reserveAndUpload await.
      await Future<void>.delayed(Duration.zero);

      // Cancel while upload is in-flight — token is now cancelled.
      queue.cancel('img-orphan');

      // Complete the upload → job enters State B → CP-2 fires → orphan deleted.
      svc.completeReserve();

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(svc.deleteWasCalled, isTrue);
    });

    test('orphan delete failure is swallowed — no exception escapes', () async {
      final svc = _ControlledService()..throwOnDelete = true;
      final queue = PhotoUploadQueue(
        service: svc,
        maxConcurrent: 1,
        maxAttempts: 1,
      );
      addTearDown(queue.dispose);

      queue.enqueue(id: 'img-orphan', localPath: '/tmp/img.jpg');
      await Future<void>.delayed(Duration.zero);
      queue.cancel('img-orphan');
      svc.completeReserve();

      // Must complete without throwing despite storage failure.
      await expectLater(
        Future<void>.delayed(const Duration(milliseconds: 50)),
        completes,
      );
    });

    test(
      'cancel during backoff delay → no phantom PhotoUploadFailed emitted',
      () async {
        // Fixed delay of 200 ms → test cancels after 50 ms → backoff token check fires.
        const backoffMs = 200;
        final queue = PhotoUploadQueue(
          service: _AlwaysNetworkErrorService(),
          maxConcurrent: 1,
          random: const _FixedRandom(backoffMs),
        );
        addTearDown(queue.dispose);

        final outcomes = <PhotoUploadOutcome>[];
        final sub = queue.outcomes.listen(outcomes.add);

        queue.enqueue(id: 'img-backoff', localPath: '/tmp/img.jpg');

        // Let first attempt run and fail → backoff starts (200 ms delay).
        await Future<void>.delayed(const Duration(milliseconds: 30));

        // Cancel mid-backoff.
        queue.cancel('img-backoff');

        // Wait past the full backoff to let everything settle.
        await Future<void>.delayed(const Duration(milliseconds: 300));
        await sub.cancel();

        final failed = outcomes.whereType<PhotoUploadFailed>().where(
          (o) => o.id == 'img-backoff',
        );
        expect(failed, isEmpty);
      },
    );
  });
}
