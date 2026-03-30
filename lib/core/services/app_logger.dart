import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

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
/// PII masking: Never log email addresses, phone numbers, BSN, or IBAN.
/// Use [AppLogger.maskPii] to sanitise strings before logging if unsure.
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
  ///
  /// Replaces: email addresses, Dutch phone numbers (+31...),
  /// IBAN (NL...), BSN (9-digit sequences in BSN context).
  static String maskPii(String input) {
    var masked = input;
    // Email
    masked = masked.replaceAll(
      RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+'),
      '***@***.***',
    );
    // Dutch phone (+31 or 06)
    masked = masked.replaceAll(RegExp(r'(\+31|0031|06)\d{8,9}'), '+31*****');
    // IBAN
    masked = masked.replaceAll(
      RegExp(r'[A-Z]{2}\d{2}[A-Z]{4}\d{10}'),
      'NL**BANK**********',
    );
    // BSN (Dutch citizen service number): 9 digits, often preceded by
    // "BSN" or "bsn" label. Only mask when preceded by BSN context to
    // avoid false positives with other 9-digit sequences.
    masked = masked.replaceAll(
      RegExp(r'[Bb][Ss][Nn][:\s]*\d{9}'),
      'BSN: *********',
    );
    return masked;
  }

  /// Route to Crashlytics in release builds.
  /// Import is conditional to avoid pulling Firebase into tests.
  static void _reportToCrashlytics(String message, Object? error, String tag) {
    // Crashlytics integration: record as non-fatal.
    // This avoids importing firebase_crashlytics here — callers can
    // wire this up in main.dart via FlutterError.onError or a global
    // error handler. For now, use debugPrint as a fallback in release
    // to ensure errors are not silently swallowed.
    //
    // TODO(reso): Wire to FirebaseCrashlytics.instance.recordError()
    // once firebase_service.dart exposes a non-fatal recording method.
    debugPrint('[$tag] $message${error != null ? ' | $error' : ''}');
  }
}
