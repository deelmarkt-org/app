# ADR-025: `copyWith` Sentinel Pattern — Keep Hand-Rolled for Now

### Status

**Accepted** — 2026-04-17 · Author: pizmam · **Scope:** affects issue [#108](https://github.com/deelmarkt-org/app/issues/108) Task D1 · **Review in:** Sprint after E06 polish completes

### Context

`scripts/check_quality.dart --thorough` flags 10 "NESTED_TERNARY" violations in `lib/features/sell/domain/entities/listing_creation_state_copy_with.dart`. The flagged lines are the nullable-field sentinel pattern:

```dart
categoryL1Id: categoryL1Id != null ? categoryL1Id() : this.categoryL1Id,
```

This is a **single-level** ternary implementing the "keep current OR clear to null" distinction. It is not a user-experience bug — it is a Sonar pattern false-positive (audit §C4).

Two paths are available:
1. Migrate to `freezed` code-gen for proper `copyWith` with sentinel handling.
2. Keep the hand-rolled pattern and suppress the Sonar rule for this file.

### Decision

**Keep the hand-rolled sentinel pattern for this sprint.** Do not migrate to `freezed` now. Suppress the Sonar rule in `scripts/check_quality.dart` via an allowlist entry scoped to files matching `*_copy_with.dart` that contain the sentinel pattern (AST match: `X != null ? X() : this.X`).

**Review trigger:** open a new ADR issue to revisit after Sprint 9–10 E06 polish completes. If at that time we have ≥ 3 entities using the sentinel pattern, the migration cost is justified.

### Rationale

| Criterion | `freezed` migration | Keep sentinel |
|:----------|:--------------------|:--------------|
| Pre-launch stability | Medium risk (changes `listing_creation_state.dart`, touches VMs, tests) | Zero behavior change |
| Effort | 3–5 days (including full test-suite regression + code-gen setup in CI) | 30 min (allowlist entry) |
| Sprint-plan fit | Would displace P-42/P-43 follow-ups | None |
| Long-term code quality | ★★★★ — generated, consistent | ★★★ — hand-rolled but consistent with `ListingEntity.copyWith` |
| Build-runner footprint | Adds `freezed: ^2.x`, `json_annotation` generation to `build_runner` graph | None |
| Team familiarity | Team has not yet used code-gen entities | Existing pattern |

Sprint velocity + legal-launch imperative makes the 30-minute allowlist the correct choice for **this** sprint. The decision is explicitly time-boxed.

### Consequences

#### Positive
- Unblocks issue #108 Task D1 (which was otherwise 3–5 days and ADR-blocked).
- Zero regression risk in the listing creation flow during pre-launch.
- Preserves the optionality to migrate later once Sprint 9–10 ships.

#### Negative
- `ListingCreationState` remains hand-rolled; any new nullable field requires manual sentinel wiring (5 places per field).
- Developers unfamiliar with the sentinel may add a bug; mitigated by existing test coverage on `listing_creation_state_test.dart`.
- SonarCloud will continue reporting these as "quality issues" unless the remote SonarCloud config is also updated (belengaz task; filed as follow-up).

### Alternatives Considered

1. **Migrate to `freezed` now** — rejected: scope creep, risk during pre-launch.
2. **Leave violations in, don't suppress** — rejected: SonarCloud quality gate would block future PRs on this file; makes unrelated PRs fail.
3. **Use `built_value`** — rejected: heavier than `freezed`, no team familiarity, same displacement problem.

### Rollback

If the allowlist entry proves problematic (false-negatives on real nested ternaries elsewhere), narrow the match pattern. If `freezed` migration is later chosen, the sentinel is already semantically equivalent to `freezed`'s `dynamic ?? current` pattern — swap is mechanical.
