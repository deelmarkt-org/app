import 'dart:async';

/// Cooperative cancellation signal for long-running operations.
///
/// Dart has no native way to cancel an in-flight `Future`. Instead we pass
/// a [CancellationToken] into async functions and the callee polls
/// [isCancelled] at explicit checkpoints between `await` boundaries. On each
/// checkpoint, [throwIfCancelled] raises a [UploadCancelledException] which
/// the caller treats as a no-op.
///
/// Pure domain — no Flutter imports.
class CancellationToken {
  CancellationToken();

  bool _cancelled = false;
  final Completer<void> _cancelCompleter = Completer<void>();

  bool get isCancelled => _cancelled;

  /// Future that completes when [cancel] is invoked. Enables racing an
  /// awaited delay against cancellation (e.g. `Future.any([delay,
  /// token.whenCancelled])`) so a cancelled job does not hold a concurrency
  /// slot through the full backoff. Never errors; completes with `null`.
  Future<void> get whenCancelled => _cancelCompleter.future;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _cancelCompleter.complete();
  }

  /// Throw if cancelled. Call at every await checkpoint.
  void throwIfCancelled() {
    if (_cancelled) throw const UploadCancelledException();
  }
}

/// Thrown by [CancellationToken.throwIfCancelled] when an upload is cancelled.
///
/// Not an [AppException] subtype — this is purely an internal control-flow
/// signal that the queue catches and silently discards.
class UploadCancelledException implements Exception {
  const UploadCancelledException();
}
