# Changelog

## [Unreleased]

### Operations

- **docs(runbooks): close B-68 — add 4 remaining incident response runbooks** (Tier-1 retrospective P2, cross-owner co-pilot from pizmam during P0-bandwidth gap):
  - `RUNBOOK-redis-outage.md` (B-68 2/5) — Upstash Redis as idempotency + rate-limit + cache layer; 4 named failure classes (backend outage, credential drift, plan rate limit, network partition); fail-closed pattern preservation guidance; cross-references RUNBOOK-mollie-webhook-failure.md §4.2.
  - `RUNBOOK-supabase-rls-regression.md` (B-68 3/5) — RLS as data-access security boundary; 7 failure classes including over-permissive policy, §14 fixture corruption, SECURITY DEFINER misuse; FREEZE protocol for active cross-tenant exposure; explicit GDPR Art. 33 72h DPA notification path; legal hold for `audit_logs`.
  - `RUNBOOK-cert-pinning-rotation.md` (B-68 4/5) — Android `network_security_config.xml` pin rotation (current expiry 2027-06-01); 4 rotation classes from > 30-day planned to < 24h emergency; Track A (release) / Track B (Remote Config bypass, last resort) / Track C (force-update) parallel-track playbook; iOS TrustKit gap noted as B-37 TODO follow-up.
  - `RUNBOOK-app-store-rejection.md` (B-68 5/5) — Apple App Review + Play Console policy rejection response; 9 named rejection classes mapped to specific guidelines (Apple §2.1/§4.0/§5.1.1/§5.1.6/§2.3.7/§5.1; Play User Data / Permissions / Restricted Content); CLAUDE.md §13 hard-gate enforcement on `privacy_details.yaml` edits; cross-references RUNBOOK-appstore-reviewer.md §Recovery for §5.1 demo account class.
  - All 5 runbooks now share a consistent structure (severity classes, triage-first, named failure classes, verification checklist, communication matrix, post-incident retro, escalation contacts) — reviewable in any order. belengaz auto-assigned reviewer; reso GDPR co-review on RLS + App Store rejection runbooks.

### Testing

- **fix(screenshots): P-54 PR-A1 — fix rootBundle eviction keys + canary GREEN** — closes #203 test-isolation defect. `RootBundleAssetLoader` builds cache keys with hyphens (`nl-NL.json`); previous eviction code used underscores (`nl_NL.json`) leaving warm entries untouched and canary failing after 24 loop iterations. Eviction paths now derived dynamically from `kScreenshotLocales`. Adds second-iteration canary regression guard, `sqflite_common_ffi` dev dep, and `path_provider` mock in `initScreenshotEnvironment` so headless `CachedNetworkImage` renders no longer throw `MissingPluginException`. Bundles four prerequisite widget overflow fixes (`category_browse_screen`, `seller_info_row`, `action_section`, `amount_section`) without which the screenshot drivers throw `RenderFlex overflowed` exceptions and block the PR-A1 canary. See `docs/PLAN-P54-…`.

### Observability

- **feat(observability): close P-56 Phase B** — wire `image_gallery_page.dart` `image_load` trace (`StatelessWidget` → `ConsumerStatefulWidget` migration; `initState` start, `frameBuilder` / `errorBuilder` stop, `dispose` safety net, `didUpdateWidget` restart on `imageUrl` change); add `perf_trace_sample_rate` Remote Config flag (default `1.0`) for runtime kill switch without redeploy (ADR-027 §L1, fail-open by design). Promotes all 5 trace registry rows from `🟡 Defined` to `✅ Wired` in `docs/observability/trace-registry.md`.
- **feat(observability): introduce Firebase Performance facade + Sentry web fallback** — closes audit task `P-56` / preflight finding `H5`. New `lib/core/services/performance/` module with `PerformanceTracer` interface, mobile (Firebase) + web (Sentry) implementations, debug-mode `NoopPerformanceTracer`, GDPR-first attribute allowlist with PII-forbidding runtime guards, Riverpod `keepAlive` provider. Sentry mobile transactions disabled (`tracesSampleRate = kIsWeb ? 0.2 : 0.0`) to avoid double-instrumentation cost. Five trace names defined (`app_start`, `listing_load`, `search_query`, `payment_create`, `image_load`); call-site wiring follows in P-56 Phase B. Provisional p95 SLOs published in `docs/observability/perf-slos.md`. ADR-027 documents the architecture. See `docs/PLAN-P56-firebase-performance-traces.md`.

### Documentation

- **docs(screens): refresh `SCREENS-INVENTORY.md`** — closes audit task `P-57` / preflight finding `M3`. Status updated to reflect Sprint 9–10 ship state (28 Implemented + 2 placeholder-copy = 30/30; was incorrectly listing 5/30 implemented). Adds Status Vocabulary, Responsive Variant Matrix appendix, Cross-Link Index appendix, Maintainer + Next-review headers. See `docs/PLAN-P57-screens-inventory-refresh.md`.

### Build / Dependencies

- **build(deps): pin `intl` to `^0.20.2`** (was `any`) — closes audit task `P-58` / preflight finding `M2`. Reproducibility hardening for ACM/Omnibus exposure on currency/date glyph rendering. easy_localization 3.0.7 accepts the constraint; resolved version unchanged at 0.20.2. See `docs/PLAN-P58-pin-intl.md`.

### Tooling

- **chore(scripts): add `scripts/check_screens_inventory.dart`** — staling check for SCREENS-INVENTORY.md. Warns at 60 days, fails at 120 days. UTC-anchored to avoid DST off-by-one. 6 unit tests covering OK / WARN / ERROR / missing-header / boundary cases.

## [0.7.0] - 2026-03-16

### Added

- **CLAUDE.md** — development rules auto-loaded by AI agents (architecture, file limits, DRY, git workflow, testing, design system enforcement)
- **.pre-commit-config.yaml** — pre-commit hooks: dart format, flutter analyze, detect-secrets, branch protection (blocks direct push to main/dev); pre-push: flutter test
- **docs/design-system/** — split from 1626-line monolith into 4 focused files:
  - `tokens.md` (colours, typography, spacing, radius, elevation, dark mode)
  - `components.md` (buttons, cards, inputs, badges, states, navigation)
  - `patterns.md` (trust UI, escrow, KYC, chat, shipping, listing detail)
  - `accessibility.md` (WCAG 2.2 AA, contrast, touch targets, focus, motion)

### Changed

- Updated README with setup instructions (pre-commit hooks, secrets baseline, dev branch)
- Added git workflow documentation (main → dev → feature branches)

### Moved to Archives

- `DeelMarkt_Master_Design_System.md` → `docs/archives/` (replaced by split design-system/)
- `llm_workflow_playbook.md` → `docs/archives/` (integrated into CLAUDE.md)

## [0.6.0] - 2026-03-16

- Consolidated architecture docs (8 → 1) and compliance docs (3 → 1)
- Merged E07+E08, removed Phase 2+ epics from MVP scope

## [0.5.0] - 2026-03-16

- Tech stack optimisation: ~€350/mo → ~€25-35/mo
- Supabase as single backend; PostgreSQL FTS; Firebase Remote Config

## [0.4.0] - 2026-03-15

- Architecture docs and development epics (initial structure)

## [0.3.0] - 2026-03-15

- Antigravity AI Kit v3.1.1

## [0.2.0] - 2026-03-15

- Renamed to DeelMarkt; acquired deelmarkt.com + deelmarkt.eu

## [0.1.0] - 2026-03-14

- Initial project setup
