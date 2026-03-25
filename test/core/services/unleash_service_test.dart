import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:unleash_proxy_client_flutter/unleash_proxy_client_flutter.dart';

import 'package:deelmarkt/core/services/unleash_service.dart';

void main() {
  group('UnleashService providers (no client)', () {
    test('unleashClientProvider returns null when not initialised', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(unleashClientProvider), isNull);
    });

    test('isFeatureEnabledProvider returns false when client is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(isFeatureEnabledProvider('test_flag')), isFalse);
    });

    test('isFeatureEnabledProvider returns false for all known flags', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(
        container.read(
          isFeatureEnabledProvider(FeatureFlags.snapToListEnabled),
        ),
        isFalse,
      );
      expect(
        container.read(
          isFeatureEnabledProvider(FeatureFlags.streamChatMigration),
        ),
        isFalse,
      );
      expect(
        container.read(
          isFeatureEnabledProvider(FeatureFlags.phase2PromotedListings),
        ),
        isFalse,
      );
    });

    test('different flag names produce different provider instances', () {
      final a = isFeatureEnabledProvider('flag_a');
      final b = isFeatureEnabledProvider('flag_b');
      final a2 = isFeatureEnabledProvider('flag_a');

      expect(a, isNot(equals(b)));
      expect(a, equals(a2));
    });

    test('unleashUpdatesProvider returns non-null when client is null', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Even without a client, the provider returns an Object.
      expect(container.read(unleashUpdatesProvider), isNotNull);
    });
  });

  group('UnleashService providers (with client)', () {
    TestWidgetsFlutterBinding.ensureInitialized();

    late UnleashClient client;

    setUp(() {
      // Mock SharedPreferences platform channel for UnleashClient.
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            (call) async {
              if (call.method == 'getAll') return <String, dynamic>{};
              if (call.method == 'setBool') return true;
              if (call.method == 'setString') return true;
              return null;
            },
          );

      client = UnleashClient(
        url: Uri.parse('https://test.example.com/api/frontend'),
        clientKey: 'test-key', // pragma: allowlist secret
        appName: 'deelmarkt-test',
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
            const MethodChannel('plugins.flutter.io/shared_preferences'),
            null,
          );
    });

    test(
      'isFeatureEnabled returns false for unknown flag with real client',
      () {
        final container = ProviderContainer(
          overrides: [unleashClientProvider.overrideWithValue(client)],
        );
        addTearDown(container.dispose);

        expect(
          container.read(isFeatureEnabledProvider('nonexistent_flag')),
          isFalse,
        );
      },
    );

    test('unleashUpdatesProvider subscribes to client events', () {
      final container = ProviderContainer(
        overrides: [unleashClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      // Reading the provider should not throw.
      final updates = container.read(unleashUpdatesProvider);
      expect(updates, isNotNull);
    });

    test('isFeatureEnabled watches unleashUpdates for reactivity', () {
      final container = ProviderContainer(
        overrides: [unleashClientProvider.overrideWithValue(client)],
      );
      addTearDown(container.dispose);

      // First read — should be false (no toggles loaded).
      expect(
        container.read(isFeatureEnabledProvider('snap_to_list_enabled')),
        isFalse,
      );

      // Emit an 'update' event — the provider should re-evaluate.
      client.emit('update');

      // Still false (no server data), but the code path is exercised.
      expect(
        container.read(isFeatureEnabledProvider('snap_to_list_enabled')),
        isFalse,
      );
    });
  });

  group('FeatureFlags constants', () {
    test('flag names are non-empty snake_case strings', () {
      final flags = [
        FeatureFlags.snapToListEnabled,
        FeatureFlags.streamChatMigration,
        FeatureFlags.phase2PromotedListings,
      ];

      for (final flag in flags) {
        expect(flag, isNotEmpty);
        expect(flag, matches(RegExp(r'^[a-z0-9_]+$')));
      }
    });

    test('flag name values match expected strings', () {
      expect(FeatureFlags.snapToListEnabled, 'snap_to_list_enabled');
      expect(FeatureFlags.streamChatMigration, 'stream_chat_migration');
      expect(FeatureFlags.phase2PromotedListings, 'phase2_promoted_listings');
    });
  });
}
