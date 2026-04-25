# Changelog

## [Unreleased]

### Build / Dependencies

- **build(deps): pin `intl` to `^0.20.2`** (was `any`) — closes audit task `P-58` / preflight finding `M2`. Reproducibility hardening for ACM/Omnibus exposure on currency/date glyph rendering. easy_localization 3.0.7 accepts the constraint; resolved version unchanged at 0.20.2. See `docs/PLAN-P58-pin-intl.md`.

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
