import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:deelmarkt/core/domain/entities/scam_flag_statement.dart';
import 'package:deelmarkt/core/domain/entities/scam_reason.dart';
import 'package:deelmarkt/core/services/supabase_service.dart';
import 'package:deelmarkt/features/profile/presentation/viewmodels/scam_flag_statement_provider.dart';

/// Fake client whose `.rpc(...)` returns a [_FakeBuilder] that resolves
/// to [rpcResult] when awaited. Mocktail doesn't compose well with the
/// `Thenable`-style chain that PostgrestFilterBuilder uses; a plain Fake
/// is the path of least resistance.
class _FakeSupabaseClient extends Fake implements SupabaseClient {
  _FakeSupabaseClient(this.rpcResult);
  final Object? rpcResult;
  String? lastRpcName;
  Map<String, dynamic>? lastRpcParams;

  @override
  PostgrestFilterBuilder<T> rpc<T>(
    String fn, {
    Map<String, dynamic>? params,
    dynamic get,
  }) {
    lastRpcName = fn;
    lastRpcParams = params;
    return _FakeBuilder<T>(rpcResult as T);
  }
}

class _FakeBuilder<T> extends Fake implements PostgrestFilterBuilder<T> {
  _FakeBuilder(this._value);
  final T _value;

  @override
  Future<R> then<R>(FutureOr<R> Function(T) onValue, {Function? onError}) {
    return Future.value(_value).then(onValue, onError: onError);
  }
}

void main() {
  group('scamFlagStatementProvider', () {
    Future<ScamFlagStatement?> read(_FakeSupabaseClient client) async {
      final container = ProviderContainer(
        overrides: [supabaseClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);
      return container.read(scamFlagStatementProvider('user-1').future);
    }

    test('returns null when the RPC returns null (no active flag)', () async {
      final client = _FakeSupabaseClient(null);
      expect(await read(client), isNull);
    });

    test('parses a valid RPC payload via the DTO', () async {
      final payload = <String, dynamic>{
        'rule_id': 'link_pattern_v3',
        'reasons': ['external_payment_link', 'urgency_pressure'],
        'score': 0.823,
        'model_version': 'scam-classifier-v1.4.0',
        'policy_version': 'policy-2026-04',
        'flagged_at': '2026-04-30T12:00:00Z',
        'content_ref': 'message/abc-123',
        'content_display_label': 'iPhone 14 Pro 256GB',
      };
      final client = _FakeSupabaseClient(payload);
      final result = await read(client);

      expect(result, isNotNull);
      expect(result!.ruleId, 'link_pattern_v3');
      expect(result.reasons, [
        ScamReason.externalPaymentLink,
        ScamReason.urgencyPressure,
      ]);
      expect(result.score, closeTo(0.823, 1e-9));
    });

    test('invokes the RPC with the userId in params', () async {
      final client = _FakeSupabaseClient(null);
      await read(client);

      expect(client.lastRpcName, 'get_active_scam_flag');
      expect(client.lastRpcParams, {'p_user_id': 'user-1'});
    });
  });
}
