import 'dart:io';
import 'dart:math';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_job.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_outcome.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_retry_logger.dart'
    as retry_log;
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_retry_policy.dart';

/// Per-job state machine for [PhotoUploadQueue]. Handles the attempt
/// loop, retry scheduling, and orphan cleanup. Extracted from the queue
/// so queue-level scheduling concerns stay focused. See ADR-026.
class PhotoUploadRunner {
  PhotoUploadRunner({
    required ImageUploadService service,
    required this.maxAttempts,
    required Random random,
    required this.onOutcome,
    required this.onMarkRetrying,
    required this.onClearRetrying,
  }) : _service = service,
       _random = random;

  final ImageUploadService _service;
  final int maxAttempts;
  final Random _random;
  final void Function(PhotoUploadOutcome) onOutcome;
  final void Function(String) onMarkRetrying;
  final void Function(String) onClearRetrying;

  Future<void> run(PhotoUploadJob job) async {
    onOutcome(PhotoUploadStarted(job.id));
    // Monotonic clock — immune to NTP sync, DST, and user clock changes.
    // Matches industry practice (Stripe, GitHub SDKs). See ADR-026.
    final clock = Stopwatch()..start();
    var attempt = 0;
    while (true) {
      attempt++;
      if (!await _runAttempt(job, attempt, clock)) return;
    }
  }

  Future<bool> _runAttempt(
    PhotoUploadJob job,
    int attempt,
    Stopwatch clock,
  ) async {
    try {
      job.token.throwIfCancelled();
      final storagePath = await _service.reserveAndUpload(File(job.localPath));
      job
        ..storagePath = storagePath
        ..uploadCompleted = true;
      job.token.throwIfCancelled();
      final response = await _service.processUploaded(storagePath);
      job.processingCompleted = true;
      job.token.throwIfCancelled();
      onOutcome(PhotoUploadSucceeded(job.id, response));
      return false;
    } on UploadCancelledException {
      if (job.uploadCompleted && !job.processingCompleted) {
        await _deleteOrphan(job.storagePath);
      }
      return false;
    } on AppException catch (e) {
      return _scheduleRetry(job, attempt, e, clock);
    }
  }

  Future<bool> _scheduleRetry(
    PhotoUploadJob job,
    int attempt,
    AppException e,
    Stopwatch clock,
  ) async {
    final failed = PhotoUploadFailed(job.id, e);
    if (!failed.isRetryable || attempt >= maxAttempts) {
      if (!job.token.isCancelled) onOutcome(failed);
      return false;
    }
    job
      ..storagePath = null
      ..uploadCompleted = false
      ..processingCompleted = false;

    final delay = PhotoUploadRetryPolicy.computeDelay(
      attempt: attempt,
      randomSeedMs: _random.nextInt(1 << 30),
      lastException: e,
    );

    if (clock.elapsed + delay > PhotoUploadRetryPolicy.totalDeadline) {
      if (!job.token.isCancelled) onOutcome(failed);
      retry_log.logRetryBudgetExhausted(
        photoId: job.id,
        attempt: attempt,
        maxAttempts: maxAttempts,
        totalDeadline: PhotoUploadRetryPolicy.totalDeadline,
        exception: e,
      );
      return false;
    }

    onMarkRetrying(job.id);
    retry_log.logRetry(
      photoId: job.id,
      attempt: attempt,
      maxAttempts: maxAttempts,
      delay: delay,
      exception: e,
    );
    // Race the backoff against cancellation so a cancelled job releases
    // its concurrency slot immediately instead of holding it for up to
    // `rateLimitCap` (30 s). See ADR-026 §M-2.
    await Future.any<void>([
      Future<void>.delayed(delay),
      job.token.whenCancelled,
    ]);
    if (job.token.isCancelled) {
      onClearRetrying(job.id);
      return false;
    }
    onClearRetrying(job.id);
    return true;
  }

  Future<void> _deleteOrphan(String? path) async {
    if (path == null) return;
    try {
      await _service.deleteStorageObject(path);
    } on Exception catch (e) {
      AppLogger.warning(
        'Orphan cleanup failed — object may linger in Storage',
        error: e,
        tag: 'photo-upload-queue',
      );
    }
  }
}
