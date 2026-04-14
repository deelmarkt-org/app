import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/app_logger.dart';
import 'package:unleash_proxy_client_flutter/unleash_proxy_client_flutter.dart';

import 'package:deelmarkt/core/services/env.dart';

part 'unleash_service.g.dart';

/// Known feature flag names — centralised to prevent typos.
abstract final class FeatureFlags {
  static const String snapToListEnabled = 'snap_to_list_enabled';
  static const String streamChatMigration = 'stream_chat_migration';
  static const String phase2PromotedListings = 'phase2_promoted_listings';

  /// P-53: Suspension gate — shows [SuspensionGateScreen] when user has an
  /// active ban or suspension. Default ON in all environments.
  /// Toggle in Unleash to bypass for emergency hotfixes.
  static const String p53SuspensionGate = 'p53_suspension_gate';
}

/// Initialise Unleash feature flags in `main()` before `runApp`.
///
/// Connects to the self-hosted Unleash Frontend API. On failure (e.g. server
/// not deployed yet), logs a warning and continues — all flags default to off.
Future<void> initUnleash() async {
  try {
    final client = UnleashClient(
      url: Uri.parse(Env.unleashUrl),
      clientKey: Env.unleashClientKey,
      appName: 'deelmarkt',
      refreshInterval: 15,
    );
    await client.start().timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        AppLogger.warning(
          'Connection timed out — using defaults',
          tag: 'unleash',
        );
      },
    );
    _unleashClient = client;
  } on Exception catch (e) {
    AppLogger.warning(
      'Failed to connect — all flags default to off',
      tag: 'unleash',
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
