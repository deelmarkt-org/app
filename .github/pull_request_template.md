## Summary
<!-- 1-3 bullet points describing what this PR does -->

## Epic / Task
<!-- e.g. E07 / B-04 -->

## Type
- [ ] Feature
- [ ] Bug fix
- [ ] Refactor
- [ ] Chore (CI, deps, docs)

## Epic Acceptance Criteria Coverage
<!-- For each acceptance criterion in the relevant epic doc, state coverage status.
     Delete this section for chore/refactor PRs with no epic. -->

| Epic Criterion | Status | Notes |
|:---------------|:-------|:------|
| <!-- e.g. "Real-time messaging works on iOS and Android" --> | <!-- Covered / Partial / N/A --> | <!-- e.g. "Wired in ChatThreadScreen" --> |

## Schema Verification (Edge Functions / Migrations only)
<!-- If this PR adds or modifies Edge Functions or migrations, list every
     DB table + column referenced and confirm they exist in migrations.
     Delete this section if not applicable. -->

- [ ] All `.select()` column names verified against migration files
- [ ] All `.order()` / `.eq()` column names verified
- [ ] `bash scripts/check_edge_functions.sh --all` passes (or only pre-existing findings)

## Checklist
- [ ] `dart format .` passes
- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test` — all passing
- [ ] Coverage ≥70% (100% for payment paths)
- [ ] No hardcoded strings (all in l10n)
- [ ] No hardcoded colours (all from DeelmarktColors)
- [ ] No secrets in code
- [ ] Relevant epic acceptance criteria updated
- [ ] Sibling file conventions matched (deno.json, shared imports, naming)

## Screenshots / Screen recordings
<!-- If UI changes, attach before/after -->
