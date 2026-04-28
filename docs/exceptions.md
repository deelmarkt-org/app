# CLAUDE.md Rule Exceptions

Searchable record of deviations from CLAUDE.md rules and their justifications.
Per [PR #244 review feedback](https://github.com/deelmarkt-org/app/pull/244#pullrequestreview-4188422121),
deviations live here rather than as inline comments — so they are searchable
and don't count against file line budgets.

If you add a `// ignore:` annotation or an entry in the machine-readable
`file_length_exempt` / `setState_allowlist` blocks in CLAUDE.md §12, add a
matching row here.

---

## File length deviations

### Active exemptions (CLAUDE.md §12 `file_length_exempt`)

| File | Lines | Limit | Reason | Tracked in |
|:-----|------:|------:|:-------|:-----------|
| `lib/features/transaction/presentation/screens/mollie_checkout_screen.dart` | 248 | 200 | P-54 PR-A deferred — payment-path refactor needs characterisation tests + Unleash flag before splitting | [#245](https://github.com/deelmarkt-org/app/issues/245) |
| `lib/features/messages/presentation/screens/chat_thread_screen.dart` | 228 | 200 | P-54 PR-B deferred — postponed from PR #244 to keep `dev → main` integration focused | [#246](https://github.com/deelmarkt-org/app/issues/246) |

### Documented deviations (within enforced gate)

| File | Lines | §2.1 limit | §12 enforced | Reason |
|:-----|------:|-----------:|-------------:|:-------|
| `lib/features/transaction/domain/usecases/create_payment_usecase.dart` | 59 | 50 | 60 | Domain purity confirmed (no Flutter/Supabase imports). Imports + `performance_tracer` wiring (GH #221) push usable body just over the §2.1 nominal target; quality gate at 60 holds. Single public `execute()` method preserved |

> The §2.1 (human-readable) and §12 (machine-enforced) limits diverge for
> use cases (50 vs 60). The §12 value is the gate the pre-commit hook uses;
> §2.1 is the aspirational target. Future cleanup: reconcile the two.

---

## How to add a new exemption

1. Open a tracking issue with acceptance criteria for removing the exemption.
2. Add the file to the right block in `CLAUDE.md` §12 with an inline comment
   referencing the issue number.
3. Add a row to the appropriate table above.
4. The exemption is conditional on the tracking issue staying open — close
   the row + remove from §12 when the underlying refactor lands.
