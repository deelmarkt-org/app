import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_error_mapper.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/data/services/models/image_upload_response.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_queue.dart';

/// **Seam test** — wires the real [ImageUploadErrorMapper] and
/// [PhotoUploadQueue] together via a stubbed [ImageUploadService] that
/// emits the mapper's output on the first attempt and succeeds thereafter.
///
/// Exercises the 429 retry *contract seam* end-to-end in the data/view-model
/// layer: `server body → mapper → typed retryAfter → queue backoff → retry
/// → success`. This is NOT a widget-pump integration test; the UI-layer
/// live-region flip is covered by [photo_grid_tile_states_test]. Keeping
/// this file as a seam test avoids a false "widget integration" signal
/// while still catching silent contract drift between mapper and queue.
/// Single-component unit tests live in `photo_upload_queue_test.dart` and
/// `image_upload_error_mapper_test.dart`.
class _MockSupabaseClient extends Mock implements SupabaseClient {}

class _MapperBacked429Service extends ImageUploadService {
  _MapperBacked429Service({required this.firstAttemptBody})
    : super(_MockSupabaseClient());

  final Map<String, dynamic> firstAttemptBody;
  int attempts = 0;

  static const _path = 'uid/int.jpg';
  static const _response = ImageUploadResponse(
    storagePath: _path,
    deliveryUrl: 'https://cdn/int.jpg',
    publicId: 'uid/int',
    width: 800,
    height: 600,
    bytes: 50000,
    format: 'jpg',
  );

  @override
  Future<String> reserveAndUpload(File localFile) async {
    attempts++;
    await Future<void>.delayed(Duration.zero);
    if (attempts == 1) {
      // Simulate the exact exception the real service would throw after
      // routing a 429 FunctionException through ImageUploadErrorMapper.
      throw ImageUploadErrorMapper.map(429, firstAttemptBody);
    }
    return _path;
  }

  @override
  Future<ImageUploadResponse> processUploaded(String storagePath) async {
    await Future<void>.delayed(Duration.zero);
    return _response;
  }

  @override
  Future<void> deleteStorageObject(String storagePath) async {}
}

void main() {
  group('Rate-limit seam (mapper ↔ queue)', () {
    test(
      '429 with retry_after_seconds=2 → queue honours hint, retries, succeeds',
      () async {
        final svc = _MapperBacked429Service(
          firstAttemptBody: const {'retry_after_seconds': 2},
        );
        final queue = PhotoUploadQueue(
          service: svc,
          maxConcurrent: 1,
          random: Random(7),
        );
        addTearDown(queue.dispose);

        final started = DateTime.now();
        final successFuture = queue.outcomes
            .firstWhere((o) => o is PhotoUploadSucceeded)
            .timeout(const Duration(seconds: 10));

        queue.enqueue(id: 'img-int', localPath: '/tmp/int.jpg');
        final succeeded = await successFuture;
        final elapsed = DateTime.now().difference(started);
        expect(succeeded, isA<PhotoUploadSucceeded>());
        expect(svc.attempts, 2, reason: 'queue must retry exactly once');
        expect(
          elapsed.inMilliseconds,
          greaterThanOrEqualTo(PhotoUploadQueue.rateLimitFloor.inMilliseconds),
          reason: 'retry must respect 2 s rate-limit floor',
        );
      },
    );

    test(
      'hostile 429 body (retry_after_seconds=86400) clamped by queue cap',
      () async {
        final svc = _MapperBacked429Service(
          firstAttemptBody: const {'retry_after_seconds': 86400},
        );
        // Sanity: mapper DOES carry the hint forward as a raw Duration —
        // clamping is the queue's responsibility.
        final sample = ImageUploadErrorMapper.map(429, const {
          'retry_after_seconds': 86400,
        });
        expect(sample, isA<ValidationException>());
        expect(
          (sample as ValidationException).retryAfter,
          const Duration(days: 1),
        );

        // And the queue's pure delay computation clamps to rateLimitCap.
        final delay = PhotoUploadQueue.computeDelay(
          attempt: 1,
          randomSeedMs: 0,
          lastException: sample,
        );
        expect(delay, PhotoUploadQueue.rateLimitCap);

        // Full end-to-end would take 30 s — prove the contract with the
        // pure-function assertion above rather than sleep the test suite.
        await svc.deleteStorageObject(_MapperBacked429Service._path);
      },
    );

    test(
      '429 without hint → queue falls back to 2 s floor (R-27 §3.6)',
      () async {
        final svc = _MapperBacked429Service(firstAttemptBody: const {});
        final queue = PhotoUploadQueue(
          service: svc,
          maxConcurrent: 1,
          maxAttempts: 2,
          random: Random(0),
        );
        addTearDown(queue.dispose);

        final outcomesFuture = queue.outcomes
            .firstWhere((o) => o is PhotoUploadSucceeded)
            .timeout(const Duration(seconds: 5));

        final started = DateTime.now();
        queue.enqueue(id: 'img-no-hint', localPath: '/tmp/nohint.jpg');
        await outcomesFuture;
        final elapsed = DateTime.now().difference(started);

        expect(svc.attempts, 2);
        expect(
          elapsed.inMilliseconds,
          greaterThanOrEqualTo(PhotoUploadQueue.rateLimitFloor.inMilliseconds),
        );
      },
    );
  });
}
