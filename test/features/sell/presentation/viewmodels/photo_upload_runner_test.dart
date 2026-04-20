import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_job.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_outcome.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_runner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockSupabase extends Mock implements SupabaseClient {}

class _FakeRunnerService extends ImageUploadService {
  _FakeRunnerService._() : super(_MockSupabase());

  static _FakeRunnerService ok() => _FakeRunnerService._();

  static _FakeRunnerService failing({required AppException error}) =>
      _FakeRunnerService._().._error = error;

  AppException? _error;
  int uploadCount = 0;
  int processCount = 0;
  int deleteCount = 0;

  /// When set, [reserveAndUpload] signals [_uploadStarted] then awaits
  /// [_releaseUpload] before returning. This lets a test interpose a
  /// `token.cancel()` while the upload is "in flight" and guarantees the
  /// runner executes `throwIfCancelled` between upload-complete and
  /// process-start — the exact precondition for `_deleteOrphan`.
  Completer<void>? _uploadStarted;
  Completer<void>? _releaseUpload;

  static const _response = ImageUploadResponse(
    storagePath: 'u/x.jpg',
    deliveryUrl: 'https://cdn/x.jpg',
    publicId: 'u/x',
    width: 10,
    height: 10,
    bytes: 1,
    format: 'jpg',
  );

  @override
  Future<String> reserveAndUpload(File localFile) async {
    uploadCount++;
    await Future<void>.delayed(Duration.zero);
    if (_error != null) throw _error!;
    if (_uploadStarted != null) {
      _uploadStarted!.complete();
      await _releaseUpload!.future;
    }
    return 'u/x.jpg';
  }

  @override
  Future<ImageUploadResponse> processUploaded(String storagePath) async {
    processCount++;
    await Future<void>.delayed(Duration.zero);
    return _response;
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {
    deleteCount++;
  }
}

PhotoUploadJob _job({CancellationToken? token}) => PhotoUploadJob(
  id: 'p1',
  localPath: '/tmp/x.jpg',
  token: token ?? CancellationToken(),
);

void main() {
  group('PhotoUploadRunner', () {
    test('emits Started then Succeeded on happy path', () async {
      final svc = _FakeRunnerService.ok();
      final outcomes = <PhotoUploadOutcome>[];
      final runner = PhotoUploadRunner(
        service: svc,
        maxAttempts: 3,
        random: Random(1),
        onOutcome: outcomes.add,
        onMarkRetrying: (_) {},
        onClearRetrying: (_) {},
      );

      await runner.run(_job());

      expect(outcomes, hasLength(2));
      expect(outcomes.first, isA<PhotoUploadStarted>());
      expect(outcomes.last, isA<PhotoUploadSucceeded>());
      expect(svc.uploadCount, 1);
      expect(svc.processCount, 1);
    });

    test(
      'emits Failed after exhausting maxAttempts on retryable failure',
      () async {
        final svc = _FakeRunnerService.failing(error: const NetworkException());
        final outcomes = <PhotoUploadOutcome>[];
        final marks = <String>[];
        final clears = <String>[];

        final runner = PhotoUploadRunner(
          service: svc,
          maxAttempts: 2,
          random: Random(7),
          onOutcome: outcomes.add,
          onMarkRetrying: marks.add,
          onClearRetrying: clears.add,
        );

        await runner.run(_job());

        expect(outcomes.first, isA<PhotoUploadStarted>());
        expect(outcomes.last, isA<PhotoUploadFailed>());
        expect(svc.uploadCount, 2);
        expect(marks, isNotEmpty);
        expect(clears, isNotEmpty);
      },
    );

    test('non-retryable failure emits Failed after one attempt', () async {
      final svc = _FakeRunnerService.failing(
        error: const ValidationException('error.image.blocked'),
      );
      final outcomes = <PhotoUploadOutcome>[];
      final runner = PhotoUploadRunner(
        service: svc,
        maxAttempts: 3,
        random: Random(1),
        onOutcome: outcomes.add,
        onMarkRetrying: (_) {},
        onClearRetrying: (_) {},
      );

      await runner.run(_job());
      expect(svc.uploadCount, 1);
      final failed = outcomes.whereType<PhotoUploadFailed>().single;
      expect(failed.isRetryable, isFalse);
    });

    test(
      'cancellation between upload and processing deletes orphan (deterministic)',
      () async {
        // Gate processUploaded on a Completer so cancellation lands after
        // reserveAndUpload finished (uploadCompleted=true) but before
        // processUploaded started (processingCompleted=false). This is the
        // exact precondition that must trigger `_deleteOrphan`.
        final svc =
            _FakeRunnerService.ok()
              .._uploadStarted = Completer<void>()
              .._releaseUpload = Completer<void>();
        final token = CancellationToken();
        final runner = PhotoUploadRunner(
          service: svc,
          maxAttempts: 1,
          random: Random(0),
          onOutcome: (_) {},
          onMarkRetrying: (_) {},
          onClearRetrying: (_) {},
        );

        final done = runner.run(_job(token: token));
        await svc._uploadStarted!.future;
        token.cancel();
        svc._releaseUpload!.complete();
        await done;

        expect(svc.uploadCount, 1);
        expect(svc.processCount, 0);
        expect(svc.deleteCount, 1);
      },
    );
  });
}
