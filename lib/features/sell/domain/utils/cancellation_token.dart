import 'package:deelmarkt/features/sell/domain/exceptions/image_upload_exceptions.dart';

/// Cooperative cancellation signal for long-running operations.
///
/// Dart has no native way to cancel an in-flight `Future`. Instead we pass
/// a [CancellationToken] into async functions and the callee polls
/// [isCancelled] at explicit checkpoints (CP-1..CP-5 in the plan) between
/// `await` boundaries. On each checkpoint, [throwIfCancelled] raises an
/// [ImageUploadCancelledException] which the caller treats as a no-op.
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
    if (_cancelled) {
      throw const ImageUploadCancelledException();
    }
  }
}
