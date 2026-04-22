import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:unleash_proxy_client_flutter/unleash_proxy_client_flutter.dart';

import 'package:deelmarkt/core/services/env.dart';

part 'unleash_service.g.dart';

/// Known feature flag names — centralised to prevent typos.
/// Logger tag shared by every Unleash call-site.
const String _logTag = 'unleash';

abstract final class FeatureFlags {
  static const String snapToListEnabled = 'snap_to_list_enabled';
  static const String streamChatMigration = 'stream_chat_migration';
  static const String phase2PromotedListings = 'phase2_promoted_listings';

  /// P-53: Suspension gate — shows [SuspensionGateScreen] when user has an
  /// active ban or suspension. Default ON in all environments.
  /// Toggle in Unleash to bypass for emergency hotfixes.
  static const String p53SuspensionGate = 'p53_suspension_gate';

  /// Fix #118: Reactive auth guard with JWT expiry check.
  /// Replaces stale supabase.auth.currentUser read with session-derived user.
  /// Canary rollout: 10% day-3 → 50% day-7 → 100% day-10.
  /// See docs/adr/ADR-001-reactive-auth-guard.md + docs/operations/rollback-playbook.md
  static const String authGuardReactive = 'auth_guard_reactive_enabled';

  /// Fix #118 (Phase 1.12): Server-side admin role verification via SECURITY DEFINER RPC.
  /// Client-side isAdmin() remains as fast-path; server check is authoritative.
  /// Requires reso to deploy public.is_admin() SQL function before enabling.
  static const String adminServerVerify = 'admin_server_verify_enabled';
}

/// Initialise Unleash feature flags in `main()` before `runApp`.
///
/// Connects to the self-hosted Unleash Frontend API. On failure (e.g. server
/// not deployed yet), logs a warning and continues — all flags default to off.
Future<void> initUnleash({String? url, String? clientKey}) async {
  // Optional overrides exist so unit tests can exercise the empty-env
  // skip branch without rebuilding the compile-time `Env` constants.
  // Production calls `initUnleash()` with no args and picks up Env.*.
  final resolvedUrl = url ?? Env.unleashUrl;
  final resolvedKey = clientKey ?? Env.unleashClientKey;

  if (resolvedUrl.isEmpty || resolvedKey.isEmpty) {
    AppLogger.warning(
      'UNLEASH_URL / UNLEASH_CLIENT_KEY unset — skipping Unleash init; '
      'all flags default to off (fine for local dev).',
      tag: _logTag,
    );
    return;
  }
  try {
    final client = UnleashClient(
      url: Uri.parse(resolvedUrl),
      clientKey: resolvedKey,
      appName: 'deelmarkt',
      refreshInterval: 15,
    );
    await client.start().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        AppLogger.warning(
          'Connection timed out — using defaults',
          tag: _logTag,
        );
      },
    );
    _unleashClient = client;
  } on Exception catch (e) {
    AppLogger.warning(
      'Failed to connect — all flags default to off',
      tag: _logTag,
      error: e,
    );
  }
}

/// Module-private singleton set by [initUnleash]. Accessed via [unleashClientProvider].
UnleashClient? _unleashClient;

/// Global [UnleashClient] instance — `null` if init failed.
///
/// Disposes the polling timer when the provider is torn down.
@Riverpod(keepAlive: true)
UnleashClient? unleashClient(Ref ref) {
  ref.onDispose(() => _unleashClient?.stop());
  return _unleashClient;
}

/// Triggers re-evaluation when the Unleash SDK fetches updated toggles.
@Riverpod(keepAlive: true)
Object? unleashUpdates(Ref ref) {
  final client = ref.watch(unleashClientProvider);

  void listener(dynamic _) {
    ref.invalidateSelf();
  }

  client?.on('update', listener);
  client?.on('ready', listener);

  ref.onDispose(() {
    client?.off(type: 'update', callback: listener);
    client?.off(type: 'ready', callback: listener);
  });

  return Object();
}

/// Check whether a feature flag is enabled.
///
/// Returns `false` if Unleash is unavailable or the flag does not exist.
/// Reactive: re-evaluates when the SDK receives updated toggles.
@riverpod
bool isFeatureEnabled(Ref ref, String flagName) {
  ref.watch(unleashUpdatesProvider);
  final client = ref.read(unleashClientProvider);
  return client?.isEnabled(flagName) ?? false;
}
