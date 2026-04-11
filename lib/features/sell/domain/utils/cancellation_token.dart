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

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
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
