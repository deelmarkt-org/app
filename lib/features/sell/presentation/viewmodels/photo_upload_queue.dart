import 'dart:async';
import 'dart:math';

import 'package:deelmarkt/features/sell/data/services/image_upload_service.dart';
import 'package:deelmarkt/features/sell/domain/utils/cancellation_token.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_job.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_outcome.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_retry_policy.dart';
import 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_runner.dart';

export 'package:deelmarkt/features/sell/presentation/viewmodels/photo_upload_outcome.dart';

/// Bounded-concurrency upload queue; emits [PhotoUploadOutcome] events on
/// [outcomes]. Per-job state machine lives in [PhotoUploadRunner] and
/// retry timing in [PhotoUploadRetryPolicy]. See ADR-026.
class PhotoUploadQueue {
  PhotoUploadQueue({
    required ImageUploadService service,
    this.maxConcurrent = 3,
    this.maxAttempts = 3,
    Random? random,
  }) : _service = service,
       _random = random ?? Random();

  // Tuning constants re-exported for tests and consumers.
  static const rateLimitFloor = PhotoUploadRetryPolicy.rateLimitFloor;
  static const rateLimitCap = PhotoUploadRetryPolicy.rateLimitCap;
  static const totalDeadline = PhotoUploadRetryPolicy.totalDeadline;
  static const computeDelay = PhotoUploadRetryPolicy.computeDelay;

  final ImageUploadService _service;
  final int maxConcurrent;
  final int maxAttempts;
  final Random _random;

  late final PhotoUploadRunner _runner = PhotoUploadRunner(
    service: _service,
    maxAttempts: maxAttempts,
    random: _random,
    onOutcome: _emit,
    onMarkRetrying: _markRetrying,
    onClearRetrying: _clearRetrying,
  );

  final _outcomes = StreamController<PhotoUploadOutcome>.broadcast();
  final _retrying = <String>{};
  final _retryingController = StreamController<Set<String>>.broadcast();
  final _tokens = <String, CancellationToken>{};
  final _waiting = <PhotoUploadJob>[];
  int _running = 0;
  bool _disposed = false;

  Stream<PhotoUploadOutcome> get outcomes => _outcomes.stream;
  Stream<Set<String>> get retryingIds => _retryingController.stream;
  Set<String> get currentRetryingIds => Set.unmodifiable(_retrying);
  int get inFlight => _running;

  void enqueue({required String id, required String localPath}) {
    if (_disposed || _tokens.containsKey(id)) return;
    final token = CancellationToken();
    _tokens[id] = token;
    _waiting.add(PhotoUploadJob(id: id, localPath: localPath, token: token));
    _pump();
  }

  void cancel(String id) {
    _tokens.remove(id)?.cancel();
    _waiting.removeWhere((j) => j.id == id);
    _clearRetrying(id);
  }

  void cancelAll() {
    for (final t in _tokens.values) {
      t.cancel();
    }
    _tokens.clear();
    _waiting.clear();
    if (_retrying.isNotEmpty) {
      _retrying.clear();
      _emitRetrying();
    }
  }

  Future<void> dispose() async {
    _disposed = true;
    cancelAll();
    await _outcomes.close();
    await _retryingController.close();
  }

  void _pump() {
    while (_running < maxConcurrent && _waiting.isNotEmpty) {
      final job = _waiting.removeAt(0);
      if (job.token.isCancelled) continue;
      _running++;
      unawaited(_runJob(job));
    }
  }

  Future<void> _runJob(PhotoUploadJob job) async {
    try {
      await _runner.run(job);
    } finally {
      _clearRetrying(job.id);
      _tokens.remove(job.id);
      _running--;
      _pump();
    }
  }

  void _markRetrying(String id) {
    if (_retrying.add(id)) _emitRetrying();
  }

  void _clearRetrying(String id) {
    if (_retrying.remove(id)) _emitRetrying();
  }

  void _emitRetrying() {
    if (_retryingController.isClosed) return;
    _retryingController.add(Set.unmodifiable(_retrying.toSet()));
  }

  void _emit(PhotoUploadOutcome outcome) {
    if (!_outcomes.isClosed) _outcomes.add(outcome);
  }
}
