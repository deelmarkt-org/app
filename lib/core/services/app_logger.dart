import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

import 'package:deelmarkt/core/utils/pii_masking.dart';

/// Structured application logger for DeelMarkt.
///
/// Tier-1 Audit M-02: Replaces `debugPrint()` with severity-aware logging.
///
/// In debug mode: outputs to console via `developer.log()`.
/// In release mode: routes warning/error to Crashlytics as non-fatal events.
///
/// Usage:
/// ```dart
/// AppLogger.info('Payment created', tag: 'payments');
/// AppLogger.warning('Retry attempt 2/5', tag: 'webhook');
/// AppLogger.error('Escrow release failed', error: e, tag: 'escrow');
/// ```
///
/// PII masking: Use [maskPii] to sanitise strings before logging.
abstract final class AppLogger {
  static const _name = 'DeelMarkt';

  /// Log informational message (debug only — stripped in release).
  static void info(String message, {String tag = ''}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag.isEmpty ? _name : '$_name/$tag',
        level: 800, // INFO
      );
    }
  }

  /// Log warning — visible in debug, reported to Crashlytics in release.
  static void warning(String message, {String tag = '', Object? error}) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag.isEmpty ? _name : '$_name/$tag',
        level: 900, // WARNING
        error: error,
      );
    } else {
      _reportToCrashlytics('WARNING: $message', error, tag);
    }
  }

  /// Log error — visible in debug, reported to Crashlytics in release.
  static void error(
    String message, {
    String tag = '',
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (kDebugMode) {
      developer.log(
        message,
        name: tag.isEmpty ? _name : '$_name/$tag',
        level: 1000, // SEVERE
        error: error,
        stackTrace: stackTrace,
      );
    } else {
      _reportToCrashlytics('ERROR: $message', error, tag);
    }
  }

  /// Mask common PII patterns before logging.
  /// Delegates to [PiiMasker.mask].
  static String maskPii(String input) => PiiMasker.mask(input);

  /// Route to Crashlytics in release builds.
  static void _reportToCrashlytics(String message, Object? error, String tag) {
    // Crashlytics integration tracked in GitHub issue — wire to
    // FirebaseCrashlytics.instance.recordError() once available.
    debugPrint('[$tag] $message${error != null ? ' | $error' : ''}');
  }
}
