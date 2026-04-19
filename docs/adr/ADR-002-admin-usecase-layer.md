# ADR-002 — Admin Domain Use Case Layer Restoration

**Status:** Accepted
**Date:** 2026-04-16
**Author:** pizmam (Frontend/Design)
**Reviewers:** reso (Backend), belengaz (Payments/DevOps)
**Implements:** Issue #119 (Phase 1.5 — post-merge-fixes)
**References:**
- `lib/features/admin/presentation/admin_dashboard_notifier.dart`
- `lib/features/admin/domain/usecases/get_admin_stats_usecase.dart` (existing)
- `lib/features/admin/domain/repositories/admin_repository.dart`
- CLAUDE.md §1.1 (Clean Architecture layers), §1.2 (Layer Dependency Rules)

---

## Context

`AdminDashboardNotifier` directly calls `adminRepositoryProvider` in both `build()`
and `_fetchData()`:

```dart
// build() — line 38
final repo = ref.watch(adminRepositoryProvider);
final (stats, activity) = await (repo.getStats(), repo.getRecentActivity()).wait;

// _fetchData() — line 47
final repo = ref.read(adminRepositoryProvider);
final (stats, activity) = await (repo.getStats(), repo.getRecentActivity()).wait;
```

This violates CLAUDE.md §1.2: **Presentation → Domain → Data**. The notifier (presentation
layer) must never import from the data layer directly. It must go through domain use cases.

A `GetAdminStatsUseCase` already exists at
`lib/features/admin/domain/usecases/get_admin_stats_usecase.dart` (15 lines) but is
not wired into any provider and not used by the notifier. No `GetAdminActivityUseCase`
exists yet.

**Why this matters beyond style:**
1. **Testability** — unit tests for the notifier must mock use cases, not repositories.
   Mocking repositories from tests violates the layer contract and couples tests to
   implementation details.
2. **Business rule encapsulation** — use cases are the correct home for rules like
   "limit activity to 10 items" or "sort by severity". Moving these rules into a
   repository call from the notifier spreads business logic into the wrong layer.
3. **Consistency** — every other feature's notifier (SellerHome, Profile, Messages)
   uses use cases. Admin being the exception creates a confusing dual-pattern.

---

## Decision

Restore the clean architecture layer for `AdminDashboardNotifier` by:

1. **Reusing** `GetAdminStatsUseCase` (already exists — do NOT recreate).
2. **Creating** `GetAdminActivityUseCase` mirroring the stats use case pattern.
3. **Creating** `lib/features/admin/presentation/admin_providers.dart` with
   `getAdminStatsUseCaseProvider` and `getAdminActivityUseCaseProvider`.
4. **Migrating** `AdminDashboardNotifier.build()` and `_fetchData()` to use cases.
5. **Removing** `adminRepositoryProvider` import from the notifier.

### New use case — GetAdminActivityUseCase

```dart
// lib/features/admin/domain/usecases/get_admin_activity_usecase.dart

import 'package:deelmarkt/features/admin/domain/entities/activity_item_entity.dart';
import 'package:deelmarkt/features/admin/domain/repositories/admin_repository.dart';

/// Retrieves recent admin activity items for the dashboard feed.
///
/// Reference: docs/screens/08-admin/01-admin-panel.md
class GetAdminActivityUseCase {
  const GetAdminActivityUseCase(this._repository);

  final AdminRepository _repository;

  /// Returns the [limit] most recent activity items, newest-first.
  Future<List<ActivityItemEntity>> call({int limit = 10}) =>
      _repository.getRecentActivity(limit: limit);
}
```

### New providers file

```dart
// lib/features/admin/presentation/admin_providers.dart
// (use case providers live in presentation because they wire domain to presentation;
//  this mirrors the pattern in other features, e.g. sell_providers.dart)

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:deelmarkt/core/services/repository_providers.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_stats_usecase.dart';
import 'package:deelmarkt/features/admin/domain/usecases/get_admin_activity_usecase.dart';

part 'admin_providers.g.dart';

@riverpod
GetAdminStatsUseCase getAdminStatsUseCase(Ref ref) =>
    GetAdminStatsUseCase(ref.watch(adminRepositoryProvider));

@riverpod
GetAdminActivityUseCase getAdminActivityUseCase(Ref ref) =>
    GetAdminActivityUseCase(ref.watch(adminRepositoryProvider));
```

### Migrated notifier

```dart
@riverpod
class AdminDashboardNotifier extends _$AdminDashboardNotifier {
  @override
  Future<AdminDashboardState> build() async {
    // Presentation → Domain: only use cases, never repository directly.
    final getStats    = ref.watch(getAdminStatsUseCaseProvider);
    final getActivity = ref.watch(getAdminActivityUseCaseProvider);
    return _fetchFor(getStats, getActivity);
  }

  Future<AdminDashboardState> _fetchFor(
    GetAdminStatsUseCase getStats,
    GetAdminActivityUseCase getActivity,
  ) async {
    final (stats, activity) = await (getStats(), getActivity()).wait;
    return AdminDashboardState(stats: stats, activity: activity);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    final getStats    = ref.read(getAdminStatsUseCaseProvider);
    final getActivity = ref.read(getAdminActivityUseCaseProvider);
    state = await AsyncValue.guard(() => _fetchFor(getStats, getActivity));
  }
}
```

The private `_fetchFor` helper:
- Eliminates code duplication between `build()` and `refresh()`.
- Lets `build()` use `ref.watch` (reactive) and `refresh()` use `ref.read` (snapshot),
  both calling the same fetch logic.

---

## Alternatives Considered

### Option A: Keep direct repo call, add thin wrapper in notifier

**Rejected.** The wrapper would just be an inlined use case — the layer violation
remains. Tests still can't mock at the right boundary.

### Option B: Provide use cases directly from AdminRepository provider

**Rejected.** Repository providers belong in `core/services/repository_providers.dart`.
Use case providers depend on the presentation context (e.g., feature-specific providers
that might be overridden in tests) — they belong in the feature's presentation layer.

### Option C: Create a combined `GetAdminDashboardUseCase` returning both stats + activity

**Deferred.** A combined use case would be cleaner for orchestration but adds a third
domain layer file for minimal gain at this stage. If the dashboard grows (system status
cards, real-time alerts), revisit this as part of that epic.

---

## Consequences

### Positive

- Layer contract restored: notifier imports only domain, not data.
- Notifier tests mock use cases (not repository) — correct test boundary.
- `GetAdminStatsUseCase` becomes used (reduces dead code, SonarCloud flag resolved).
- Pattern consistent with all other features.

### Negative

- `admin_providers.g.dart` must be regenerated (`flutter pub run build_runner build`).
- Two new files added (`get_admin_activity_usecase.dart`, `admin_providers.dart`).
- Providers file is in `presentation/` not `domain/` — intentional (see Option B above),
  but may seem surprising. Add a comment in the file explaining the decision.

### Risks

| Risk | Mitigation |
|:-----|:-----------|
| `build_runner` not run before CI | Pre-commit hook catches stale `.g.dart` files (CLAUDE.md §8) |
| `getAdminActivityUseCaseProvider` not overridden in existing tests | Check for `adminRepositoryProvider` overrides in test helpers; update to use case provider |

---

## Test Requirements

Notifier tests (moved from Phase 3.2 per M3 — must ship in same PR as refactor):

```
test/features/admin/presentation/admin_dashboard_notifier_test.dart
```

| Test | Scenario | Assert |
|:-----|:---------|:-------|
| Happy path | Both use cases return data | State = `AsyncData<AdminDashboardState>` with correct values |
| Stats error | `GetAdminStatsUseCase` throws | State = `AsyncError` |
| Activity error | `GetAdminActivityUseCase` throws | State = `AsyncError` |
| Refresh loading | `refresh()` called | State transitions: data → loading → data |
| Refresh error | `refresh()` + use case throws | State transitions: data → loading → error |

---

## Rollback

`git revert <Phase-1.5-sha>` — reverts to direct repo call.
SLA: 30 minutes.
See `docs/operations/rollback-playbook.md` §Phase-1.5.
