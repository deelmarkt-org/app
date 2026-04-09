# DeelMarkt — Development Rules

> These rules are loaded automatically by Claude Code on every session.
> They apply to ALL code changes in this repository. No exceptions.

---

## Project Identity

- **Product:** DeelMarkt — Trust-first Dutch P2P marketplace
- **Stack:** Flutter 3.x + Dart 3.x | Supabase | Mollie | Cloudflare | Cloudinary
- **Architecture:** Clean Architecture + MVVM + Riverpod 3 (feature-first)
- **Languages:** Dart (app), TypeScript (Edge Functions)

## Developer Roles

When a developer identifies themselves, use this to determine their tasks and file ownership.

| Handle | Role | Owns | Sprint Plan Tasks |
|:-------|:-----|:-----|:-----------------|
| **reso** | Backend | `lib/core/services/`, `supabase/`, Edge Functions, DB migrations | Tasks labelled `[R]` in `docs/SPRINT-PLAN.md` |
| **belengaz** | Payments/DevOps | `.github/workflows/`, `codemagic.yaml`, `lib/core/router/`, Mollie, shipping | Tasks labelled `[B]` in `docs/SPRINT-PLAN.md` |
| **pizmam** | Frontend/Design | `lib/widgets/`, `lib/core/design_system/`, `lib/core/l10n/`, screens, tests | Tasks labelled `[P]` in `docs/SPRINT-PLAN.md` |

**When a developer says "I'm reso" or "work on my next task as reso":**
1. Read `docs/SPRINT-PLAN.md`
2. Find tasks labelled `[R]` (or `[B]`/`[P]` for the other devs)
3. Find the first unchecked task in the current sprint
4. Read the relevant epic doc before starting
5. Create or switch to the correct branch (listed in sprint plan)
6. Only modify files within their ownership scope

**When a developer doesn't identify themselves:** Ask "Which developer are you? (reso / belengaz / pizmam)"

## Critical Files to Read Before Any Work

| When | Read |
|:-----|:-----|
| Any task | This file (CLAUDE.md) |
| Developer-specific tasks | `docs/SPRINT-PLAN.md` (find your `[R]`/`[B]`/`[P]` tasks) |
| Architecture questions | `docs/ARCHITECTURE.md` |
| Trust/security/legal questions | `docs/COMPLIANCE.md` |
| Feature implementation | The relevant epic in `docs/epics/` |
| UI implementation | `docs/design-system/tokens.md` + relevant pattern file |
| Starting a new session | Run `flutter analyze` and `flutter test` first |

---

## §1 — Architecture Rules

### 1.1 Clean Architecture Layers (never bypass)

```
lib/
├── core/                      # Shared infrastructure
│   ├── design_system/         # Tokens, theme, components
│   ├── l10n/                  # Localisation strings (NL/EN)
│   ├── router/                # GoRouter config
│   ├── services/              # Supabase client, Dio, shared services
│   └── utils/                 # Formatters, validators, extensions
│
├── features/                  # Feature modules (one per domain)
│   └── <feature>/
│       ├── data/              # Repository impls, DTOs, data sources
│       ├── domain/            # Entities, repository interfaces, use cases
│       └── presentation/      # Screens, widgets, ViewModels (Riverpod)
│
├── widgets/                   # Shared UI components (design system)
│
└── main.dart
```

### 1.2 Layer Dependency Rules

- **Presentation → Domain → Data** (never reverse)
- Domain layer is **pure Dart** — no Flutter imports, no Supabase imports
- Data layer implements Domain interfaces — Domain never knows about Supabase
- Presentation uses Riverpod providers to access Domain use cases
- **Never** import from one feature into another — use shared `core/` or `widgets/`

### 1.3 State Management — Riverpod 3

- Use `@riverpod` code generation for all providers
- ViewModels are `AsyncNotifier` or `Notifier` subclasses
- UI reads state via `ref.watch()`, never `ref.read()` in build methods
- Side effects via `ref.read(provider.notifier).method()`
- **No** `setState()`, **no** `ChangeNotifier`, **no** raw `StreamBuilder`

---

## §2 — File Rules

### 2.1 Maximum File Length

| File Type | Max Lines | Action if Exceeded |
|:----------|:----------|:-------------------|
| Screen/Page widget | 200 | Extract sub-widgets into same feature's `presentation/widgets/` |
| ViewModel (Notifier) | 150 | Split into multiple providers or extract use cases |
| Repository implementation | 200 | Split by entity or operation group |
| Use case | 50 | One use case = one public method |
| Model/Entity/DTO | 100 | If exceeded, the model is too large — decompose |
| Test file | 300 | Split into focused test groups |
| Utility/helper | 100 | Split by concern |

### 2.2 Naming Conventions

| Type | Convention | Example |
|:-----|:----------|:--------|
| Files | snake_case | `listing_detail_screen.dart` |
| Classes | PascalCase | `ListingDetailScreen` |
| Providers | camelCase with Provider suffix | `listingDetailProvider` |
| Private members | underscore prefix | `_handleSubmit()` |
| Constants | camelCase | `maxImageCount = 12` |
| Riverpod generated | `@riverpod` annotation | Auto-generates from function name |
| Test files | `*_test.dart` | `listing_detail_screen_test.dart` |
| Localisation keys | snake_case dot-separated | `listing_card.escrow_available` |

### 2.3 Import Rules

- **Relative imports** within a feature: `import '../domain/listing_entity.dart';`
- **Package imports** across features: `import 'package:deelmarkt/core/...';`
- **Never** import from `lib/features/X/` into `lib/features/Y/`
- Group imports: dart → flutter → packages → project (separated by blank lines)

---

## §3 — DRY Principles

### 3.1 Shared Components

Before creating ANY new widget, check:
1. Does it exist in `lib/widgets/`? → Use it
2. Does a similar one exist? → Extend it with parameters
3. Is it feature-specific? → Put in `features/<feature>/presentation/widgets/`
4. Will 2+ features use it? → Put in `lib/widgets/`

### 3.2 Shared Logic

- Business rules → `core/utils/` or domain use cases
- API calls → Repository pattern (never call Supabase from UI)
- Validation → `core/utils/validators.dart`
- Formatting (price, date, distance) → `core/utils/formatters.dart`
- Constants → `core/constants.dart` (never magic numbers in code)

### 3.3 No Duplication Allowed

- **Strings:** All UI text in `core/l10n/*.json` — never hardcoded
- **Colors:** All from `DeelmarktColors` — never `Color(0xFF...)` in widgets
- **Spacing:** All from `Spacing` constants — never raw `16.0` in padding
- **Typography:** All from `DeelmarktTypography` — never inline `TextStyle`
- **Radius:** All from `DeelmarktRadius` — never raw `BorderRadius.circular(12)`

---

## §4 — Design System Rules

### 4.1 Mandatory References

The design system is in `docs/design-system/`:
- **tokens.md** — colours, typography, spacing, radius, elevation, dark mode
- **components.md** — buttons, cards, inputs, badges, states, navigation
- **patterns.md** — trust UI, escrow flow, KYC prompts, chat, shipping, listings
- **accessibility.md** — WCAG 2.2 AA, contrast, touch targets, focus, reduced motion

### 4.2 Before Building Any Screen

1. Look up the screen in [`docs/screens/SCREEN-MAP.md`](docs/screens/SCREEN-MAP.md) — find the spec + designs
2. Read the screen spec markdown (layout, components, states, l10n, accessibility)
3. Read the design PNGs for all relevant variants (light/dark, mobile/desktop, states)
4. Read the relevant pattern in `docs/design-system/patterns.md`
5. Check which components from `docs/design-system/components.md` apply
6. Verify colour/spacing tokens from `docs/design-system/tokens.md`
7. Confirm accessibility requirements from `docs/design-system/accessibility.md`

### 4.3 Design System Violations That Block PR

- Hardcoded colour values instead of `DeelmarktColors.*`
- Hardcoded text instead of localisation keys
- Touch targets < 44×44px
- Missing loading/empty/error states
- Missing `Semantics` labels on interactive widgets

---

## §5 — Git Workflow

### 5.1 Branch Strategy

```
main          ← production-ready, protected, never push directly
  └── dev     ← integration branch, PRs from feature branches
       ├── feature/E01-listing-crud
       ├── feature/E02-auth-kyc
       ├── fix/payment-double-charge
       └── chore/update-dependencies
```

### 5.2 Branch Rules

- **Never push to `main` directly** — pre-commit hook blocks this
- **Never push to `dev` directly** — always via PR from feature branch
- Branch naming: `feature/`, `fix/`, `chore/`, `docs/` prefix
- One epic = one or more feature branches
- Delete branch after merge

### 5.3 Commit Messages

Format: `type(scope): description`

| Type | Usage |
|:-----|:------|
| `feat` | New feature |
| `fix` | Bug fix |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Build, CI, dependencies |
| `style` | Formatting, no logic change |

Example: `feat(listings): add favourite toggle with optimistic UI`

---

## §6 — Testing Rules

### 6.1 Coverage Requirements

- **Minimum 70%** widget + unit test coverage (CI blocks below)
- **100% coverage** on payment paths (E03) — never lower
- Every screen must test: loading state, error state, empty state, data state
- Every form must test: validation rules, submit success, submit failure

### 6.2 Test Structure

```
test/
├── features/
│   └── <feature>/
│       ├── data/          # Repository tests (mock Supabase)
│       ├── domain/        # Use case / business logic tests
│       └── presentation/  # Widget tests + ViewModel tests
├── widgets/               # Shared component tests
└── core/                  # Utility/formatter tests
```

### 6.3 What to Test

| Layer | Test | Mock |
|:------|:-----|:-----|
| Business rules | Pure functions: validation, scoring, tier calculation | Nothing |
| Use cases | Input/output, edge cases | Repository interface |
| ViewModels | State transitions, error handling | Use cases |
| Widgets | Rendering, interaction, async states | Providers (ProviderScope override) |
| Repository | API call mapping, error translation | Supabase client |

---

## §7 — Pre-Implementation Checklist

Before writing ANY implementation code, complete these steps:

```
[ ] Read the epic doc for the feature being implemented
[ ] Read relevant design system docs (patterns + components)
[ ] List every interactive element (buttons, fields, toggles)
[ ] List every async state (loading, error, empty, data)
[ ] Trace every data path: UI → ViewModel → Use Case → Repository → Supabase
[ ] List every permission/KYC gate
[ ] Confirm all Riverpod providers exist (or create stubs first)
[ ] Run flutter analyze — zero warnings
```

### 7.1 Mandatory Pre-Implementation Verification (AI Agent)

> **This is not optional.** The AI agent MUST output a verification block
> in its response BEFORE writing any implementation code. Skipping this
> section led to 2 critical runtime bugs and 3 missing features in past PRs.

**Before writing ANY new Edge Function, migration, or Supabase query:**

1. **Schema verification** — For each DB table/column referenced in the task:
   - Read the migration file that defines it
   - List the exact column names you will use (copy-paste from the migration, don't guess)
   - If joining tables, confirm the FK column names on both sides
2. **Sibling convention check** — Before creating a new file in an existing directory:
   - List sibling files and their structure (e.g. `deno.json`, shared imports, naming)
   - Match the convention exactly
3. **Epic acceptance criteria audit** — For each acceptance criterion in the epic:
   - State whether this task covers it (fully / partially / not applicable)
   - If partially: note what's missing and whether this PR or a follow-up addresses it
4. **Existing UI/logic scan** — Search the codebase for any widget, DTO, or entity that
   already references the field/feature being built. List them. Confirm they will still
   work after your change (or that you are updating them).

**Output this as a checklist in your response.** The developer can then approve
or flag issues before implementation begins. Format:

```
## Pre-Implementation Verification

### Schema (tables/columns I will query)
- conversations.listing_id → FK to listings.id ✓ (migration 20260407...)
- messages.created_at → TIMESTAMPTZ ✓ (migration 20260407..., line 75)

### Sibling conventions
- All Edge Functions have deno.json ✓
- Cron functions use _shared/auth.ts verifyServiceRole ✓

### Epic acceptance criteria (E04-messaging.md)
- [x] Seller response time displayed on profile → already wired in ProfileStatsRow
- [ ] Seller response time displayed in conversation header → needs ChatHeader update

### Existing references to this feature
- ProfileStatsRow uses responseTimeMinutes (raw "30m" format)
- SellerInfoRow uses responseTimeMinutes (l10n bucket format)
- → inconsistency to resolve
```

**For Dart-only tasks** (no Edge Functions or migrations), the schema verification
step can be skipped but the epic audit and existing-reference scan still apply.

**For UI tasks** (any task touching `presentation/` screens or widgets):

5. **Screen spec + design reference** — Before writing any screen or widget:
   - Look up the screen in [`docs/screens/SCREEN-MAP.md`](docs/screens/SCREEN-MAP.md)
   - Read the full spec markdown file (layout, components, states, l10n keys, accessibility)
   - Read the design PNG files for the relevant variants (light/dark, mobile/desktop, states)
   - Add a `/// Reference: docs/screens/...` doc comment to every new screen/widget file
   - List which design variants you checked in your verification block

Format for UI tasks:

```
### Design reference
- Spec: docs/screens/06-chat/02-chat-thread.md ✓ (read layout §1-4, l10n §7)
- Designs checked:
  - chat_thread_mobile_light ✓ (primary layout reference)
  - chat_thread_mobile_dark ✓ (dark mode tokens)
  - chat_thread_desktop_expanded ✓ (responsive breakpoint)
- All l10n keys from spec present in en-US.json + nl-NL.json ✓
```

---

## §8 — Quality Gates (enforced by pre-commit hooks)

### On Every Commit

- `dart format --set-exit-if-changed .` — formatting check
- `flutter analyze --no-pub` — static analysis (zero warnings)
- `detect-secrets` — no hardcoded secrets
- No commits to `main` or `dev` directly
- `bash scripts/check_edge_functions.sh` — Edge Function structure + schema cross-reference (on `.ts`/`.sql` files)
- `deno lint` + `deno fmt --check` — TypeScript linting (gracefully skips if deno not installed)

### On Every Push

- `flutter analyze --no-pub --fatal-infos` — strict analyze (catches generated-file regressions)
- `dart run scripts/check_new_code_coverage.dart` — ≥80% coverage on changed files
- Full test suite runs in CI — not locally on push

### Workflow

```bash
# 1. Format before staging
dart format .

# 2. Stage and commit — hooks run automatically
git add <files>
git commit -m "feat(scope): description"

# 3. Push — test hooks run
git push origin feature/...
```

**Never use `--no-verify`.** Fix the issue instead.

---

## §9 — Supabase Rules

- All tables MUST have RLS policies — no exceptions
- All API keys in Supabase Vault — never in env vars or source code
- Edge Functions use Zod for input validation
- Webhook handlers MUST be idempotent (Upstash Redis NX pattern)
- Database schema changes require a migration file
- **Migrations MUST be applied** after creating/modifying `.sql` files — run `bash scripts/check_deployments.sh --deploy`
- **Edge Functions MUST be deployed** after creating/modifying — run `bash scripts/check_deployments.sh --deploy`
- Before marking a task as done, verify deployment: `bash scripts/check_deployments.sh`

---

## §10 — Accessibility (Legal Requirement)

The European Accessibility Act is enforceable. These are not optional:

- All interactive elements: ≥ 44×44px touch targets
- All text: ≥ 4.5:1 contrast ratio (3:1 for large text)
- All interactive widgets: `Semantics()` labels in NL + EN
- All animations: respect `MediaQuery.disableAnimations`
- All forms: redundant entry prevention (auto-fill, saved data)
- Focus order follows visual order
- Visible focus indicators on all focusable elements

---

## §11 — Session Workflow

### Starting a Session

1. Read this file (CLAUDE.md)
2. Run `flutter analyze` — establish baseline
3. Run `flutter test` — establish baseline
4. Read the epic for whatever you're implementing
5. Read relevant design system docs

### During Implementation

1. Follow §7 + §7.1 pre-implementation checklists before each task
2. Run `flutter analyze` after each file change
3. Run `dart run scripts/check_quality.dart --all` to catch CLAUDE.md violations early
4. Run `bash scripts/check_edge_functions.sh --all` when working on Edge Functions
5. Keep files under line limits (§2.1)
6. Use design system tokens, never raw values (§3.3)
7. Use `core/domain/entities/` barrel re-exports for cross-feature entity imports
8. Use `core/domain/repositories/` barrel re-exports for cross-feature repository imports
9. All interactive widgets MUST have `Semantics()` labels
10. All UI text MUST use `.tr()` l10n keys — no hardcoded strings
11. No `setState()`, `FutureBuilder`, or `StreamBuilder` in presentation layer — use Riverpod

### Before Ending

1. Run `flutter analyze` — zero warnings
2. Run `dart run scripts/check_quality.dart` — zero violations on your files
3. Run `bash scripts/check_edge_functions.sh --all` — zero new violations (if you touched Edge Functions)
4. Run `bash scripts/check_deployments.sh` — zero pending migrations or undeployed functions
5. Run `flutter test` — all passing
6. Commit with proper message format
7. Update epic acceptance criteria checkboxes if applicable

### Quality Gate Scripts

| Script | When | What |
|:-------|:-----|:-----|
| `dart run scripts/check_quality.dart` | Pre-commit (auto) | File length, cross-imports, l10n, Semantics, setState, FutureBuilder, **missing test file** |
| `dart run scripts/check_quality.dart --thorough` | Pre-commit (auto) | + duplicate strings, nested ternaries, long methods |
| `dart run scripts/check_quality.dart --all` | Manual | Check entire codebase |
| `dart run scripts/check_new_code_coverage.dart` | Pre-push (auto) | ≥80% coverage on new code (mirrors SonarCloud) |
| `bash scripts/check_edge_functions.sh` | Pre-commit (auto) | Edge Function structure + schema cross-reference (staged .ts/.sql) |
| `bash scripts/check_edge_functions.sh --all` | Manual | Check all Edge Functions |
| `bash scripts/check_deployments.sh` | Before ending session | Detects pending migrations + undeployed Edge Functions |
| `bash scripts/check_deployments.sh --deploy` | After creating migration/function | Auto-applies pending migrations + deploys functions |

### Setup for New or Existing Developers

```bash
# macOS/Linux — new developer (full setup):
bash scripts/setup.sh

# macOS/Linux — existing developer (just update hooks after pulling):
bash scripts/setup_hooks.sh

# Windows — new developer (full setup):
.\scripts\setup.ps1

# Windows — existing developer (just update hooks after pulling):
.\scripts\setup_hooks.ps1
```

---

## §12 — Machine-Readable Quality Gates

> Parsed by `scripts/check_quality.dart`. Edit here to update rules.

<!-- QUALITY_RULES_START
file_length:
  screen: 200
  viewmodel: 150
  repository: 200
  usecase: 60
  model: 200
  test: 300
  utility: 100
  default: 200

setState_allowlist:
  - lib/features/listing_detail/presentation/widgets/detail_image_gallery.dart
  - lib/features/listing_detail/presentation/widgets/detail_info_section.dart
  - lib/features/auth/presentation/widgets/registration_form.dart
  - lib/features/auth/presentation/widgets/otp_verification_view.dart
  - lib/features/search/presentation/widgets/filter_bottom_sheet.dart
  - lib/features/profile/presentation/widgets/address_form_modal.dart
  - lib/features/transaction/presentation/screens/mollie_checkout_screen.dart
  - lib/features/shipping/presentation/screens/parcel_shop_selector_screen.dart
  - lib/features/dev/**
  - lib/widgets/inputs/deel_search_input.dart
  - lib/features/profile/presentation/widgets/delete_account_dialog.dart
  - lib/widgets/media/image_gallery.dart
  - lib/widgets/media/image_gallery_fullscreen.dart
  - lib/widgets/media/image_gallery_zoomable_page.dart

file_length_exempt:
  - lib/core/design_system/theme.dart
  - lib/core/router/app_router.dart
  - **/data/supabase/**
  - **/data/mock/*_data.dart
  - lib/widgets/buttons/deel_button.dart
  - lib/widgets/cards/deel_card.dart
  - lib/widgets/inputs/dutch_address_input.dart
  - lib/features/home/presentation/widgets/home_data_view.dart

cross_feature_import_exempt:
  - lib/core/router/app_router.dart
  - lib/core/services/repository_providers.dart
QUALITY_RULES_END -->
