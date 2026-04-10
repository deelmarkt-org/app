import 'dart:async';
import 'dart:math';

import 'package:deelmarkt/features/sell/domain/entities/uploaded_image.dart';
import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';
import 'package:deelmarkt/features/sell/domain/repositories/image_upload_repository.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';

/// Result of a single upload attempt as observed by the queue.
sealed class PhotoUploadOutcome {
  const PhotoUploadOutcome(this.id);
  final String id;
}

class PhotoUploadStarted extends PhotoUploadOutcome {
  const PhotoUploadStarted(super.id);
}

class PhotoUploadSucceeded extends PhotoUploadOutcome {
  const PhotoUploadSucceeded(super.id, this.image);
  final UploadedImage image;
}

class PhotoUploadFailed extends PhotoUploadOutcome {
  const PhotoUploadFailed(super.id, this.exception);
  final ImageUploadException exception;
}

/// Bounded-concurrency queue that uploads picked images via
/// [ImageUploadRepository] with capped retries and exponential backoff.
///
/// Concurrency is fixed at [maxConcurrent] (default 3, see plan §3.4).
/// The queue does NOT touch state directly — it emits [PhotoUploadOutcome]
/// events on a stream so the ViewModel can apply id-based state patches.
class PhotoUploadQueue {
  PhotoUploadQueue({
    required ImageUploadRepository repository,
    this.maxConcurrent = 3,
    this.maxAttempts = 3,
    Random? random,
  }) : _repository = repository,
       _random = random ?? Random();

  final ImageUploadRepository _repository;
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
          final result = await _repository.upload(
            id: job.id,
            localPath: job.localPath,
            token: job.token,
          );
          if (job.token.isCancelled) return;
          _emit(PhotoUploadSucceeded(job.id, result));
          return;
        } on ImageUploadCancelledException {
          return; // silent drop
        } on ImageUploadException catch (e) {
          if (!e.isRetryable || attempt >= maxAttempts) {
            // Guard: don't emit failure for photos removed during upload.
            if (job.token.isCancelled) return;
            _emit(PhotoUploadFailed(job.id, e));
            return;
          }
          await _backoff(attempt, job.token);
          if (job.token.isCancelled) return;
        }
      }
    } finally {
      _tokens.remove(job.id);
      _running--;
      _pump();
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
    token.throwIfCancelled();
  }

  void _emit(PhotoUploadOutcome outcome) {
    if (_outcomes.isClosed) return;
    _outcomes.add(outcome);
  }
}

class _Job {
  _Job({required this.id, required this.localPath, required this.token});
  final String id;
  final String localPath;
  final CancellationToken token;
}
