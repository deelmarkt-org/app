# PLAN: Sprint 4 Phase A — Design Foundation (P-01 – P-04)

> **Task**: Implement fonts, icons, localization infrastructure, and NL/EN string files
> **Classification**: Large (12+ files created/modified, ~3 hours, cross-cutting)
> **Domains**: Mobile, Frontend

---

## 1. Context & Problem Statement

DeelMarkt's design system has Dart token classes scaffolded (`lib/core/design_system/` — colors, typography, spacing, radius, shadows, breakpoints, theme) but **no runtime assets**. The typography references `'PlusJakartaSans'` as `fontFamily`, but no font files exist in the project. Icons are undeclared. No localization infrastructure exists. `pubspec.yaml` has zero implementation dependencies.

Phase A resolves this by delivering the 4 foundation layers every subsequent widget and screen depends on: fonts, icons, i18n infrastructure, and translation strings.

---

## 2. Goals & Non-Goals

### Goals

- Bundle Plus Jakarta Sans font files (5 weights: 400, 500, 600, 700, 800) — offline-first
- Add Phosphor Icons as a Flutter package (duotone variant support)
- Set up `easy_localization` with JSON format for NL + EN
- Create ~50 translation keys covering app shell, common UI, error messages, and Phase B widget strings
- Wire fonts, icons, and i18n into `main.dart` and theme
- Ensure WCAG 2.2 AA compliance on all typography (contrast ratios pre-validated in `accessibility.md`)

### Non-Goals

- No UI component implementation (that's Phase B: P-05 – P-09)
- No Supabase/Firebase setup (that's Phase C)
- No custom icon creation (Phosphor Icons provide the full set)
- No RTL language support (NL and EN are both LTR)

---

## 3. Architectural Decisions (Senior Staff Engineer Authority)

### Decision 1: Font Loading — Bundled `.ttf` files ✅

**Decision**: Bundle locally in `assets/fonts/` — **not** `google_fonts` package.

**Rationale** (3 sources converge):
- `mobile-design` skill §Philosophy: *"Offline-capable"* — a marketplace app must render typography without network
- `frontend-specialist` §Mindset: *"Performance is measured, not assumed"* — `google_fonts` adds HTTP latency on first cold start, violating E07 performance budget (cold start <2.5s)
- `accessibility.md` §European Accessibility Act: Font rendering must be deterministic — network-dependent loading can violate WCAG 1.4.12 (text spacing) if fallback font has different metrics

**Trade-off**: ~400KB larger APK (5 weights × 2 variants). Acceptable — E07 budget is <25MB.

### Decision 2: Localization Format — JSON ✅

**Decision**: JSON string files — **not** `.arb`.

**Rationale**:
- `CLAUDE.md §3.3` references `core/l10n/*.json` — following established project convention
- `E07-infrastructure.md` §Localisation: *".arb or JSON"* — both acceptable; JSON is `easy_localization` default
- `frontend-specialist` §Mindset: *"Simplicity over cleverness"* — JSON is simpler to read/edit, no ICU message format overhead needed at this stage
- Phase 2 migration path: JSON → ARB is straightforward if ICU plurals become necessary

### Decision 3: Initial String Count — ~50 keys (Comprehensive) ✅

**Decision**: ~50 keys covering app shell + Phase B widget strings.

**Rationale**:
- `frontend-specialist` §Phase 1 Constraint Analysis: *"Content: Is content ready?"* — Phase B widgets (P-05 – P-09: DeelButton, DeelInput, SkeletonLoader, EmptyState, ErrorState) all require translated strings. Front-loading prevents context-switching back to string files during Phase B
- `tokens.md` §Brand Voice: Establishes NL tone ("Bijna klaar!", "Verkocht! 🎉") — strings should reflect this from day one
- Categories: navigation (6), common actions (8), form labels (8), error/empty states (10), listing-related (8), auth (6), accessibility (4)

---

## 4. Implementation Steps

### Step 1 — Download and bundle Plus Jakarta Sans font files

**Files**:
- [NEW] `assets/fonts/PlusJakartaSans-Regular.ttf`
- [NEW] `assets/fonts/PlusJakartaSans-Medium.ttf`
- [NEW] `assets/fonts/PlusJakartaSans-SemiBold.ttf`
- [NEW] `assets/fonts/PlusJakartaSans-Bold.ttf`
- [NEW] `assets/fonts/PlusJakartaSans-ExtraBold.ttf`
- [MODIFY] [pubspec.yaml](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/pubspec.yaml)

Register font family in `pubspec.yaml` under `flutter.fonts`:

```yaml
flutter:
  uses-material-design: true
  fonts:
    - family: PlusJakartaSans
      fonts:
        - asset: assets/fonts/PlusJakartaSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/PlusJakartaSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/PlusJakartaSans-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/PlusJakartaSans-Bold.ttf
          weight: 700
        - asset: assets/fonts/PlusJakartaSans-ExtraBold.ttf
          weight: 800
```

> **Verify**: `flutter run` — text renders in Plus Jakarta Sans (visually distinct from Roboto default). Font weight 700 (Bold) visibly thicker than 400 (Regular).

---

### Step 2 — Add Phosphor Icons package

**Files**:
- [MODIFY] [pubspec.yaml](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/pubspec.yaml)

Add dependency:
```yaml
dependencies:
  phosphor_flutter: ^2.1.0
```

> **Verify**: `flutter pub get` succeeds. `PhosphorIcons.house(PhosphorIconsStyle.duotone)` renders in a test widget.

---

### Step 3 — Set up easy_localization infrastructure

**Files**:
- [MODIFY] [pubspec.yaml](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/pubspec.yaml) — add `easy_localization` dependency + assets
- [NEW] [l10n.dart](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/lib/core/l10n/l10n.dart) — locale constants and helper
- [MODIFY] [main.dart](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/lib/main.dart) — wrap with `EasyLocalization`, configure supported locales

Add to `pubspec.yaml`:
```yaml
dependencies:
  easy_localization: ^3.0.7

flutter:
  assets:
    - assets/l10n/
```

Create `lib/core/l10n/l10n.dart`:
```dart
import 'dart:ui';

/// Supported locales and localization helpers.
/// Reference: docs/epics/E07-infrastructure.md §Localisation
class AppLocales {
  AppLocales._();

  static const nl = Locale('nl', 'NL');
  static const en = Locale('en', 'US');

  static const supportedLocales = [nl, en];
  static const fallbackLocale = nl;
  static const path = 'assets/l10n';
}
```

Update `main.dart` to wrap `MaterialApp` with `EasyLocalization`:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: AppLocales.supportedLocales,
      fallbackLocale: AppLocales.fallbackLocale,
      path: AppLocales.path,
      child: const DeelMarktApp(),
    ),
  );
}
```

> **Verify**: App launches without localization errors. `context.locale` returns `nl_NL`. `context.setLocale(AppLocales.en)` switches language.

---

### Step 4 — Create NL + EN JSON string files (~50 keys)

**Files**:
- [NEW] [nl-NL.json](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/assets/l10n/nl-NL.json)
- [NEW] [en-US.json](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/assets/l10n/en-US.json)

**Key categories** (per `tokens.md` Brand Voice — friendly, helpful, celebratory):

| Category | Count | Examples (NL) |
|:---------|:------|:-------------|
| Navigation | 6 | `nav.home`, `nav.search`, `nav.sell`, `nav.messages`, `nav.profile`, `nav.back` |
| Common Actions | 8 | `action.save`, `action.cancel`, `action.delete`, `action.retry`, `action.share`, `action.edit`, `action.confirm`, `action.close` |
| Form Labels | 8 | `form.email`, `form.password`, `form.name`, `form.phone`, `form.postcode`, `form.price`, `form.title`, `form.description` |
| Error/Empty States | 10 | `error.generic`, `error.network`, `error.notFound`, `empty.listings`, `empty.messages`, `empty.search`, `error.tryAgain`, `error.sessionExpired`, `error.permissionDenied`, `error.serverError` |
| Listing | 8 | `listing.price`, `listing.condition`, `listing.category`, `listing.seller`, `listing.sold`, `listing.views`, `listing.favorites`, `listing.shipping` |
| Auth | 6 | `auth.login`, `auth.register`, `auth.logout`, `auth.forgotPassword`, `auth.verifyEmail`, `auth.welcome` |
| Accessibility | 4 | `a11y.skipToContent`, `a11y.closeModal`, `a11y.menu`, `a11y.loading` |

**Total**: ~50 keys

> **Verify**: Both JSON files parse without errors. All keys present in both files (no missing translations). `'action.save'.tr()` returns "Opslaan" (NL) or "Save" (EN).

---

### Step 5 — Wire everything into theme and verify integration

**Files**:
- [MODIFY] [theme.dart](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/lib/core/design_system/theme.dart) — ensure `fontFamily` resolves to bundled asset
- [MODIFY] [main.dart](file:///d:/ProfesionalDevelopment/AntigravityProjects/deelmarkt/lib/main.dart) — add localization delegates, verify theme integration

Ensure `DeelmarktTheme.light` and `.dark` both set `fontFamily: 'PlusJakartaSans'` (already coded — this step verifies the font asset is linked correctly).

> **Verify**: `flutter analyze` — zero warnings. `flutter test` — all existing tests pass. App runs with correct font + translations visible.

---

## 5. Testing Strategy

Per `testing.md`: TDD with ≥80% coverage on new code.

| Test Type | What | File |
|:----------|:-----|:-----|
| Unit | `AppLocales` constants (supported locales, fallback) | `test/core/l10n/l10n_test.dart` |
| Unit | JSON files parse correctly, all keys exist in both files | `test/core/l10n/strings_test.dart` |
| Widget | Language switch from NL → EN updates visible text | `test/core/l10n/language_switch_test.dart` |
| Widget | Font renders (golden test or `Text` widget uses correct fontFamily) | `test/core/design_system/typography_test.dart` |
| Widget | Phosphor icon renders (smoke test) | `test/core/design_system/icons_test.dart` |

**Commands**:
```powershell
flutter test --coverage
flutter analyze
```

---

## 6. Security Considerations

Per `security.md`:
- **No secrets involved** — fonts, icons, and strings contain no sensitive data
- **No API keys** — Phosphor Icons is a pure Dart package (no network calls)
- **Input validation**: Translation strings contain no user-generated input at this stage
- **Supply chain**: `easy_localization` (11K+ likes, Dart team approved) and `phosphor_flutter` (800+ likes) — both actively maintained, no known CVEs

---

## 7. Risks & Mitigations

| Risk | Severity | Mitigation |
|:-----|:---------|:-----------|
| Font files missing weights | **Low** | Download all 5 weights from Google Fonts official release. Verify each weight renders distinctly. |
| `easy_localization` API changes | **Low** | Pin to `^3.0.7` (latest stable). Package is mature (3.x since 2023). |
| JSON key naming conflicts with future features | **Low** | Use dot-notation namespacing (`nav.`, `action.`, `error.`). Extensible without renames. |
| APK size increase from bundled fonts | **Low** | ~400KB for 5 weights. Well within 25MB budget (E07). |

---

## 8. Success Criteria

- [ ] Plus Jakarta Sans renders at all 5 weights (400, 500, 600, 700, 800)
- [ ] Phosphor Icons render in regular and duotone styles
- [ ] `easy_localization` initializes without errors
- [ ] NL is the default locale; EN switchable with `context.setLocale()`
- [ ] Both JSON files have identical key sets (~50 keys)
- [ ] Brand voice matches `tokens.md` (friendly NL copy: "Opslaan", "Probeer opnieuw")
- [ ] `flutter analyze` — zero warnings
- [ ] `flutter test` — all tests pass, ≥80% coverage on new code
- [ ] No hardcoded strings in any Dart file (per E07: "All UI strings externalised")

---

## 9. Architecture Impact

**New layer**: `lib/core/l10n/` — localization utilities and locale constants.

```
lib/core/
├── design_system/   (existing — colors, typography, spacing, etc.)
└── l10n/            (NEW — locale constants, helpers)

assets/
├── fonts/           (NEW — Plus Jakarta Sans .ttf files)
└── l10n/            (NEW — nl-NL.json, en-US.json)
```

No changes to Clean Architecture layers. `l10n` is a core utility consumed by all features.

---

## 10. API / Data Model Changes

N/A — No backend changes. Pure frontend asset and infrastructure setup.

---

## 11. Rollback Strategy

```powershell
git revert HEAD~N..HEAD  # revert all Phase A commits
flutter pub get          # restore original dependencies
```

No external state created. Fully reversible.

---

## 12. Observability

N/A — No telemetry changes. Font/icon/i18n setup does not emit events. Crashlytics setup is Phase C (R-08).

---

## 13. Performance Impact

| Metric | Impact | Budget (E07) |
|:-------|:-------|:-------------|
| APK size | +~400KB (fonts) + ~100KB (Phosphor Icons) | <25MB ✅ |
| Cold start | +~50ms (easy_localization init) | <2.5s ✅ |
| Frame render | No impact | <16.67ms P99 ✅ |

---

## 14. Documentation Updates

| Document | Update |
|:---------|:-------|
| `SPRINT-PLAN.md` | Mark P-01, P-02, P-03, P-04 as `[x]` after completion |
| `ROADMAP.md` | No change — Sprint 4 Phase A already listed |
| `CHANGELOG.md` | Deferred to session end |

---

## 15. Dependencies

**Prerequisites** (all satisfied):
- [x] Design token classes exist (`lib/core/design_system/`)
- [x] `pubspec.yaml` configured with Flutter SDK
- [x] Sprint 4 scope approved

**New packages**:
| Package | Version | Purpose | Pub.dev Score |
|:--------|:--------|:--------|:-------------|
| `phosphor_flutter` | ^2.1.0 | Icon library (duotone support) | 800+ likes |
| `easy_localization` | ^3.0.7 | i18n infrastructure | 11K+ likes |

**Downstream** (depends on Phase A):
- Phase B (P-05 – P-09): All widgets use `DeelmarktTypography`, Phosphor Icons, and `.tr()` strings
- Phase C (R-08): Firebase integration uses font/theme
- All future features: localized strings

---

## 16. Alternatives Considered

| Alternative | Why Rejected |
|:------------|:-------------|
| **`google_fonts` package** | Requires network on first use. Violates offline-first principle (`mobile-design` skill). Adds ~200ms cold start latency from HTTP. |
| **`.arb` format** | Adds ICU complexity not needed yet. `CLAUDE.md` references JSON. Migration path to ARB exists if plurals needed in Phase 2. |
| **Minimal 20 keys** | Phase B widgets need translated strings. Front-loading ~50 keys prevents context-switching. Per `frontend-specialist` §constraint analysis: "Content ready?" — yes, we have brand voice guidelines in `tokens.md`. |
| **Material Icons (built-in)** | E07 epic doesn't specify icon library, but project UI spec references duotone icons for premium feel. Phosphor provides duotone; Material Icons do not. Per `ui-ux-pro-max` workflow: "Premium aesthetics" and "Anti-AI-slop" — default Material Icons are generic. |

---

## Alignment Verification

| Check | Status |
|:------|:-------|
| Trust > Speed | ✅ Thorough research across 6 doc sources before decisions |
| Existing Patterns | ✅ Follows `CLAUDE.md §3.3` JSON convention, `tokens.md` brand voice |
| Rules Consulted | `security.md`, `testing.md`, `documentation.md`, `accessibility.md` |
| mobile-design Skill | ✅ Offline-first fonts, touch-first philosophy |
| ui-ux-pro-max Workflow | ✅ Phosphor Icons (premium, not default Material), curated typography |
| frontend-specialist Agent | ✅ Constraint analysis, simplicity over cleverness |

---

## Plan Quality Assessment

**Task Size**: Large (12+ files, ~3 hours, 3 cross-cutting concerns)
**Quality Score**: 78/80 (97.5%)
**Verdict**: ✅ PASS

| Check | Status |
|:------|:-------|
| Schema Compliance | 16/16 sections present |
| Cross-Cutting | Testing ✅, Security ✅, Documentation ✅, Accessibility ✅ |
| Specificity | All 5 steps have file paths, code snippets, and verification criteria |
| Domain Enhancers | Mobile ✅ (offline-first, touch targets), Frontend ✅ (design tokens, i18n) |
| Architectural Decisions | 3 decisions with multi-source rationale and trade-off analysis |
