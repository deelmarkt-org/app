import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/core/services/unleash_service.dart';
import 'package:deelmarkt/features/profile/domain/entities/sanction_entity.dart';

part 'active_sanction_provider.g.dart';

/// Provides the current user's active [SanctionEntity] (suspension or ban),
/// or `null` if the user is not suspended / not authenticated.
///
/// Suspended behind the [FeatureFlags.p53SuspensionGate] Unleash toggle.
/// When the flag is disabled the gate is bypassed and `null` is returned
/// so the app stays fully accessible (e.g. emergency rollback).
///
/// On any [SanctionException] or transport error the provider surfaces an
/// [AsyncError] — callers must handle it and show an appropriate fallback.
///
/// Reference: docs/epics/E06-trust-moderation.md §Account Suspension & Recovery
/// Reference: docs/screens/SCREEN-MAP.md (P-53 Suspension Gate)
@riverpod
class ActiveSanction extends _$ActiveSanction {
  @override
  Future<SanctionEntity?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;

    // Feature-flag guard: if the flag is off the gate is bypassed entirely.
    final enabled = ref.watch(
      isFeatureEnabledProvider(FeatureFlags.p53SuspensionGate),
    );
    if (!enabled) return null;

    final repo = ref.read(sanctionRepositoryProvider);
    return repo.getActiveSanction(user.id);
  }

  /// Force-refreshes the sanction state (e.g. after a successful appeal).
  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }
}
