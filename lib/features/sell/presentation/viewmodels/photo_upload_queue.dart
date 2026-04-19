import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:deelmarkt/core/exceptions/app_exception.dart';
import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_outcome.dart';

export 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_outcome.dart';

/// Bounded-concurrency upload queue; emits [PhotoUploadOutcome] events on [outcomes].
class PhotoUploadQueue {
  static const _logTag = 'photo-upload-queue';

  PhotoUploadQueue({
    required ImageUploadService service,
    this.maxConcurrent = 3,
    this.maxAttempts = 3,
    Random? random,
  }) : _service = service,
       _random = random ?? Random();

  final ImageUploadService _service;
  final int maxConcurrent;
  final int maxAttempts;
  final Random _random;

  final _outcomes = StreamController<PhotoUploadOutcome>.broadcast();
  final _tokens = <String, CancellationToken>{};
  final _waiting = <_Job>[];
  int _running = 0;
  bool _disposed = false;

  /// Stream of upload progress events. Subscribe before enqueueing.
  Stream<PhotoUploadOutcome> get outcomes => _outcomes.stream;

  int get inFlight => _running;

  /// Enqueue an upload. Idempotent — if [id] is already tracked, no-op.
  void enqueue({required String id, required String localPath}) {
    if (_disposed) return;
    if (_tokens.containsKey(id)) return;
    final token = CancellationToken();
    _tokens[id] = token;
    _waiting.add(_Job(id: id, localPath: localPath, token: token));
    _pump();
  }

  /// Cancel an in-flight or queued upload (e.g. user removed the photo).
  void cancel(String id) {
    final token = _tokens.remove(id);
    token?.cancel();
    _waiting.removeWhere((j) => j.id == id);
  }

  /// Cancel all uploads. Called when the wizard is disposed.
  void cancelAll() {
    for (final t in _tokens.values) {
      t.cancel();
    }
    _tokens.clear();
    _waiting.clear();
  }

  Future<void> dispose() async {
    _disposed = true;
    cancelAll();
    await _outcomes.close();
  }

  // ── internals ──

  void _pump() {
    while (_running < maxConcurrent && _waiting.isNotEmpty) {
      final job = _waiting.removeAt(0);
      if (job.token.isCancelled) continue;
      _running++;
      // Fire-and-forget — _runJob handles its own errors and pumps on done.
      unawaited(_runJob(job));
    }
  }

  Future<void> _runJob(_Job job) async {
    _emit(PhotoUploadStarted(job.id));
    try {
      var attempt = 0;
      while (true) {
        attempt++;
        try {
          // CP-1: before upload — if cancelled here, nothing was stored.
          job.token.throwIfCancelled();
          final storagePath = await _service.reserveAndUpload(
            File(job.localPath),
          );
          job
            ..storagePath = storagePath
            ..uploadCompleted =
                true; // State B: orphan cleanup required on cancel
          // CP-2: after storage upload — if cancelled here, we must delete the orphan.
          job.token.throwIfCancelled();
          final response = await _service.processUploaded(storagePath);
          job.processingCompleted = true; // State C: no cleanup needed

          // CP-3: after processing — if cancelled here, response is discarded but
          // file is already in Cloudinary. No orphan in Supabase Storage.
          job.token.throwIfCancelled();
          _emit(PhotoUploadSucceeded(job.id, response));
          return;
        } on UploadCancelledException {
          // Orphan cleanup: delete from Storage only if upload completed but
          // processing did not (State B). See state machine comment above.
          if (job.uploadCompleted && !job.processingCompleted) {
            await _deleteOrphan(job.storagePath);
          }
          return; // silent drop — user removed the photo
        } on AppException catch (e) {
          final failed = PhotoUploadFailed(job.id, e);
          if (!failed.isRetryable || attempt >= maxAttempts) {
            // Guard: don't emit failure for photos removed during upload.
            if (job.token.isCancelled) return;
            _emit(failed);
            return;
          }
          // Reset state for retry attempt — upload will re-reserve a new path.
          job
            ..storagePath = null
            ..uploadCompleted = false
            ..processingCompleted = false;
          try {
            await _backoff(attempt, job.token);
          } on UploadCancelledException {
            return; // cancelled during backoff — same treatment as mid-upload cancel
          }
          if (job.token.isCancelled) return;
        }
      }
    } finally {
      _tokens.remove(job.id);
      _running--;
      _pump();
    }
  }

  Future<void> _deleteOrphan(String? path) async {
    if (path == null) return;
    try {
      await _service.deleteStorageObject(path);
    } on Exception catch (e) {
      AppLogger.warning(
        'Orphan cleanup failed — object may linger in Storage',
        error: e,
        tag: _logTag,
      );
    }
  }

  Future<void> _backoff(int attempt, CancellationToken token) async {
    // Exponential backoff with full jitter: base * 2^(n-1) + jitter
    const baseMs = 500;
    const capMs = 8000;
    final exp = baseMs * (1 << (attempt - 1));
    final ceil = exp.clamp(baseMs, capMs);
    final delayMs = _random.nextInt(ceil);
    await Future<void>.delayed(Duration(milliseconds: delayMs));
    token.throwIfCancelled(); // CP-3: after backoff delay
  }

  void _emit(PhotoUploadOutcome outcome) {
    if (_outcomes.isClosed) return;
    _outcomes.add(outcome);
  }
}

/// Mutable job descriptor; tracks upload state machine for orphan cleanup.
class _Job {
  _Job({required this.id, required this.localPath, required this.token});

  final String id;
  final String localPath;
  final CancellationToken token;

  String? storagePath;

  /// True after [ImageUploadService.reserveAndUpload] returns successfully.
  bool uploadCompleted = false;

  /// True after [ImageUploadService.processUploaded] returns successfully.
  bool processingCompleted = false;
}
