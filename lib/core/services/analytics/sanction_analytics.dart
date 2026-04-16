import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:deelmarkt/core/services/firebase_service.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

part 'sanction_analytics.g.dart';

/// Analytics wrapper for P-53 Suspension Gate + Appeal flow events.
///
/// Emits Firebase Analytics events and [AppLogger] breadcrumbs in parallel.
/// NEVER includes appeal body text or any PII — only structural metadata.
///
/// Event names use snake_case to match Firebase conventions.
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
class SanctionAnalytics {
  const SanctionAnalytics({required this.analytics});

  final FirebaseAnalytics analytics;

  static const _tag = 'sanction_analytics';
  static const _keySanctionId = 'sanction_id';

  /// Fired when the suspension gate screen is shown to the user.
  void suspensionGateShown({
    required String sanctionId,
    required SanctionType type,
  }) {
    final params = <String, Object>{
      _keySanctionId: sanctionId,
      'sanction_type': type.name,
    };
    analytics.logEvent(name: 'suspension_gate_shown', parameters: params);
    AppLogger.info(
      'suspension_gate_shown sanctionId=$sanctionId type=${type.name}',
      tag: _tag,
    );
  }

  /// Fired when the user opens the appeal form.
  void appealStarted({required String sanctionId}) {
    final params = <String, Object>{_keySanctionId: sanctionId};
    analytics.logEvent(name: 'appeal_started', parameters: params);
    AppLogger.info('appeal_started sanctionId=$sanctionId', tag: _tag);
  }

  /// Fired on successful appeal submission.
  ///
  /// [bodyLength] is the character count — never the content itself.
  void appealSubmitted({required String sanctionId, required int bodyLength}) {
    final params = <String, Object>{
      _keySanctionId: sanctionId,
      'body_length': bodyLength,
    };
    analytics.logEvent(name: 'appeal_submitted', parameters: params);
    AppLogger.info(
      'appeal_submitted sanctionId=$sanctionId bodyLength=$bodyLength',
      tag: _tag,
    );
  }

  /// Fired when the appeal submission fails.
  ///
  /// [errorCode] maps to [SanctionException.code] (e.g. "APPEAL_WINDOW_EXPIRED").
  void appealFailed({required String sanctionId, required String errorCode}) {
    final params = <String, Object>{
      _keySanctionId: sanctionId,
      'error_code': errorCode,
    };
    analytics.logEvent(name: 'appeal_failed', parameters: params);
    AppLogger.warning(
      'appeal_failed sanctionId=$sanctionId errorCode=$errorCode',
      tag: _tag,
    );
  }
}

/// Riverpod provider for [SanctionAnalytics].
///
/// Depends on [firebaseAnalyticsProvider] so it can be overridden in tests
/// with a fake [FirebaseAnalytics] instance via [ProviderScope.overrides].
@Riverpod(keepAlive: true)
SanctionAnalytics sanctionAnalytics(Ref ref) {
  return SanctionAnalytics(analytics: ref.watch(firebaseAnalyticsProvider));
}
