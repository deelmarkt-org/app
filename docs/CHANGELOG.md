# Changelog

## [Unreleased]

### Security

- **chore(security): add root `SECURITY.md` disclosure policy** — closes Tier-1 retrospective `B-67`. Covers GitHub Security Advisories (primary) + `security@deelmarkt.com` (secondary), conservative SLAs (5d ack / 10d triage / 14d critical fix / 90d coordinated disclosure), explicit out-of-scope list (DoS, social-eng, third-party deps, content moderation), good-faith safe-harbor language aligned with OWASP Vulnerability Disclosure Cheat Sheet, and EU regulatory hooks (GDPR Art.33 72h notification, NIS2 Art.21 alignment, DSA Art.16 boundary routing content-moderation issues away from `security@`). README links to the policy. Cross-owner co-pilot work; belengaz auto-assigned reviewer.

### Operations

- **docs(runbooks): add `RUNBOOK-mollie-webhook-failure.md`** — closes 1 of 5 runbooks under Tier-1 retrospective `B-68`. Triage-first response procedure for the Mollie webhook on the money path: confirm-vs-Mollie-status-page, blast-radius capture queries, 7 named failure classes (HMAC mismatch, Redis down, DLQ replay, 404 unknown id, service-role JWT, function timeout, unknown payment status) with class-specific mitigation, post-mitigation verification checklist, communication matrix (engineering → leadership → customers → Mollie → DPA), 5-business-day post-incident retrospective protocol. Cross-owner co-pilot work; belengaz auto-assigned reviewer.

### Refactoring

- **refactor(supabase): close B-64 — decompose 2 oversized Supabase repositories** (Tier-1 retrospective P2, cross-owner co-pilot from pizmam during P0-bandwidth gap):
  - `lib/features/home/data/supabase/supabase_listing_repository.dart` — 231 → 196 LOC (under §2.1 200-LOC cap with 4-line margin). Extracted distance-search flow (`getNearby` 53-LOC RPC + enrichment) into `lib/features/home/data/supabase/supabase_listing_nearby_helper.dart` (NEW, 91 LOC). Repository delegates via `_nearbyHelper.fetch(...)`; public `ListingRepository` interface unchanged. Mirrors P-54 pattern (PR #237/#238/#240) for behavior-equivalent decomposition.
  - `lib/features/messages/data/supabase/supabase_message_repository.dart` — 207 → 160 LOC. Extracted Realtime subscription orchestration (`watchMessages` + `_emitSnapshot` + `_subscribeChanges`, 63 LOC) into `lib/features/messages/data/supabase/supabase_message_realtime_subscription.dart` (NEW, 108 LOC). Repository creates the subscription helper in its constructor and delegates `watchMessages` to a one-line passthrough. Snapshot loader is dependency-injected to keep the helper free of repository internals.
  - All 4 files under §2.1 200-LOC cap. Pure refactor — no behavior change. Existing tests pass unchanged. Closes B-64 from Tier-1 retrospective.

### Tooling

- **chore(ci): close B-59 + B-60 — Edge Function structure check + license compliance** (Tier-1 retrospective P2, cross-owner co-pilot from pizmam during P0-bandwidth gap):
  - **B-59:** Add `bash scripts/check_edge_functions.sh --all` to the `quality` job in `.github/workflows/ci.yml`. The script already runs as a pre-commit hook on staged `.ts`/`.sql` files; this CI step catches drift introduced when someone bypasses the pre-commit hook (forbidden via `--no-verify` but technically possible). Promotes the pre-commit discipline to a CI gate.
  - **B-60:** Replace the heuristic `grep "gpl\|agpl"` license check with `scripts/check_dependencies_pana.dart` — a per-dependency SPDX scanner that walks each hosted package's LICENSE file in pub-cache, distinguishes GPL (blocked) from LGPL (allowed) via SPDX-prefix tokenisation, cross-references `LICENSES.allowlist` (NEW, currently empty placeholder) for documented exceptions, and emits `build/deps-manifest.json` (project-local schema; SPDX 2.3 upgrade tracked as `B-70`) as a 90-day CI artifact for App Review §5.1.6 third-party SDK disclosure. Conservative classifier covers MIT, Apache-2.0, BSD-2/3, ISC, MPL-2.0, Unlicense, CC0 + the disallowed family (AGPL, GPL, LGPL, SSPL, CC-BY-NC). Old heuristic + GPL-name `for pkg in gpl agpl` grep removed (replaced, not duplicated).

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
