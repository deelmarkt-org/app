## Plan: Frontend Task Analysis & Web Launch Roadmap — v3.1

> **Quality Gate**: APPROVED (2026-03-25) — Market research completed, 5 competitors analyzed.
> **Author**: pizmam (Emre Dursun) | **Reviewer**: Senior Staff Engineer audit + System Design alignment review (v3.0) + Tier-1 Production-Grade audit (v3.1)
> **Status**: Ready for execution | **Phases**: 5 (expanded from 4)
> **v3.0 Changes**: Architecture alignment fixes — CSP/WASM validation, web session auth task, mock data layer conventions, search abstraction, dark mode token mapping, PWA ADR reference, Cloudinary optimization strategy.
> **v3.1 Changes**: Tier-1 audit fixes — `usePathUrlStrategy()`, auth guard race condition + splash screen, `/onboarding` route, entity immutability (equatable), SW conflict resolution, PR #9 merge dependency, web error boundary, font FOUT prevention, per-step rollback strategies, timeline expansion to 8 days.

---

### Scope

Comprehensive analysis of all Pizmam (`[P]`) tasks to formulate a 5-phase launch roadmap for the DeelMarkt web frontend, aligning with Tier-1 design standards (Stripe/Linear/Vercel) and the `/ui-ux-pro-max` philosophy.

**Strategic Positioning** (from Quality Gate research):
- **Trust-first**: Attacks Marktplaats's #1 weakness (scam reputation, no seller ratings)
- **Web-first**: Every competitor treats web as secondary — DeelMarkt's web will be first-class
- **Accessibility-first**: ZERO competitors are WCAG 2.2 AA compliant — legal moat + expanded market
- **Premium design**: Anti-AI-slop, curated HSL palette, micro-animations — exceeds Vinted/Wallapop

---

### 1. Task Inventory & Status Assessment

**✅ COMPLETED (Sprint 1–2)** — verified against `origin/dev` SPRINT-PLAN.md
- `P-01`–`P-10` Design system foundation (fonts, icons, i18n, core widgets)
- `P-11` GDPR consent banner — `[x]` in sprint plan
- `P-12` WCAG 2.2 AA audit tooling — `[x]` in sprint plan
- `P-13` Widget tests ≥70% coverage — `[x]` in sprint plan

**CRITICAL Priority (MVP Blockers)**
- `P-14`–`P-16` Onboarding, Registration, Login (Est: 24h) — *Depends: R-13 (Supabase Auth)*
- `P-19`–`P-22` Core Trust Widgets (Est: 24h) — *Depends: Mock data contracts*
- `P-24` Listing creation screen (Est: 16h) — *Depends: R-22 (Listings Backend)*
- `P-26`, `P-29` Search & Home screens (Est: 24h) — *Depends: R-25 (FTS)*

**HIGH Priority (Core UX)**
- `P-17`, `P-18` Profile & Settings (Est: 16h)
- `P-25` Listing detail screen (Est: 12h)
- `P-30`–`P-34` Listing sub-widgets (Est: 32h)
- `P-41` Seller/buyer mode toggle (Est: 6h)

**MEDIUM Priority (Post-MVP)**
- `P-23` KYC prompt, `P-27` Category browse, `P-28` Favourites
- `P-35`–`P-37` Chat screens (Depends: E04 Realtime)
- `P-38`–`P-40` Ratings, seller profile, Admin panel
- `P-42`, `P-43` Final accessibility audit, ASO metadata

**NEW TASKS** (from Quality Gate research — registered in SPRINT-PLAN.md as P-44 to P-47)
- `P-44` Social login (Google + Apple Sign-In) — Est: 8h — ⚠️ Requires E02 epic update + reso backend OAuth setup. Scope expansion — needs PO approval.
- `P-45` Flutter Web performance budget & CanvasKit strategy — Est: 4h
- `P-46` Dynamic OG meta tags + crawler pre-rendering — Est: 6h — ⚠️ **Owner: belengaz** (Cloudflare domain). Coordinate, do NOT implement as pizmam.
- `P-47` Dark mode implementation & validation — Est: 12h (spread across phases)
- ~~`P-NEW-05` Responsive layout shell~~ — Already implemented as `ResponsiveBody` in PR #23. Only auth guard addition needed (~2h).

---

### 2. Frontend Launch Requirements

**Core Infrastructure**:
- Flutter Web compilation pipeline with CanvasKit
- CanvasKit strategy: Accept 2MB+ WASM with aggressive Service Worker caching (cache-first for return visits). Document trade-off vs HTML renderer.
- Path URL strategy (no `#` hashes) via `usePathUrlStrategy()`
- **⚠️ CSP + CanvasKit WASM validation** — `B-36` CSP is deployed but does NOT include `wasm-unsafe-eval`. CanvasKit requires this directive for WASM execution. **Phase 1, Day 1 blocker**: test `flutter build web --csp` output against current CSP. If blocked, coordinate with belengaz to add `wasm-unsafe-eval` to `script-src` in `web/index.html` and Cloudflare headers. See: `ARCHITECTURE.md` §Security, `web/index.html` CSP meta tag.
- PWA manifest + Service Worker for offline shell — **ADR-019 required**: document PWA strategy decision (offline-first vs online-only shell, Service Worker caching policy, update strategy). PWA is not currently referenced in `ARCHITECTURE.md` — this ADR bridges the gap.

**SEO Strategy** (Flutter Web has NO SSR):
- Pre-rendered HTML shell in `web/index.html` with structured data
- Cloudflare Workers for **crawler-aware pre-rendering**: detect crawler user-agents (Googlebot, Bingbot, etc.) and inject listing-specific content (title, description, price, images) directly into HTML before serving. This ensures crawlers receive unique, fully-formed HTML per listing URL — critical for marketplace SEO.
- Same Workers serve dynamic OG meta tags for social sharing (`/listing/:id` → title, image, price)
- Sitemap generation via Edge Function for crawlable listing URLs
- Non-crawler requests receive the standard Flutter SPA shell

**Design System Foundation** (Already implemented ✅):
- Plus Jakarta Sans, Phosphor Icons, NL/EN localization
- `DeelButton` (6 variants × 3 sizes × 5 states), `DeelInput`, `SkeletonLoader`, `EmptyState`, `ErrorState`, `LanguageSwitch`
- HSL color tokens, spacing system (4px base), border radius tokens, elevation system
- Dark mode token set (complete in `tokens.md`)

**Routing Structure**:
- GoRouter with authentication guards (client-side only, no SSR)
- Routes: `/onboarding`, `/login`, `/register`, `/home`, `/search`, `/listing/:id`, `/listing/create`, `/profile/:id`, `/settings`, `/chat`, `/transactions`
- `StatefulShellRoute` for persistent bottom navigation
- Deep link support via `app_links` package + AASA/assetlinks (B-06, B-07 ✅)

**Auth Flow**:
- Social login: Google + Apple Sign-In (NEW — every competitor offers this)
- Email + phone OTP via Supabase Auth (R-02 ✅ already covers basic OTP — verify with reso if R-13 adds capabilities needed for P-15/P-16)
- Session persistence: `flutter_secure_storage` (mobile), `HttpOnly` secure cookies via backend (web) — NOT `localStorage`, which is vulnerable to XSS. Requires custom web session handler that sets `HttpOnly; Secure; SameSite=Strict` cookies via Supabase Edge Function.
  - **⚠️ NEW TASK REQUIRED**: `R-NEW-WEB-SESSION` — Web session Edge Function (cookie-based auth). Not currently in `ARCHITECTURE.md` or `SPRINT-PLAN.md`. Must be scoped and assigned to reso before Phase 2A. Without this, web auth falls back to `localStorage` (XSS-vulnerable) or Supabase's default `localStorage` persistence.
  - **Fallback**: If Edge Function not ready, use Supabase JS client's default session persistence with strict CSP (`script-src 'self'`) as mitigation. Document the trade-off.
- Biometric auth (mobile only): Face ID / Fingerprint

**Performance Budget** (Flutter Web specific):
- Time to first frame: < 3s on 4G
- CanvasKit WASM load: < 2s cached (Service Worker)
- Total initial download: < 5MB (including CanvasKit + app)
- Frame budget: 16.6ms (60fps)
- Image gallery scroll: 0 jank frames
- Cloudinary images: `f_auto,q_auto,w_auto` (WebP/AVIF)
  - **Cloudinary transformation strategy** (per `ARCHITECTURE.md` §External Services):
    - Thumbnails (grid): `c_fill,w_400,h_300,f_auto,q_auto` (4:3 ratio per `components.md` DeelCard)
    - Listing detail: `c_limit,w_800,f_auto,q_auto` (max 800px width)
    - Full-screen gallery: `c_limit,w_1200,f_auto,q_80` (quality trade-off for speed)
    - Avatar: `c_fill,w_96,h_96,f_auto,q_auto,r_max` (circular crop)
  - **SLO alignment**: Search P95 < 500ms (per `ARCHITECTURE.md` SLOs) — Cloudinary CDN + proper sizing critical for this target

**Responsive Breakpoints** (from `tokens.md`):
- `compact` (< 600px): 2-col grid, bottom nav — MOBILE
- `medium` (600–840px): 3-col grid, bottom nav — TABLET PORTRAIT
- `expanded` (840–1200px): 4-col grid, side rail — TABLET LANDSCAPE
- `large` (> 1200px): 4-5 col + sidebar, nav drawer — DESKTOP

---

### 3. Architecture Layer Mapping

Every screen follows CLAUDE.md §1.2 Clean Architecture:

```
Screen → ViewModel (@riverpod AsyncNotifier)
       → Use Case (pure Dart, single method)
       → Repository (interface in domain, impl in data)
       → Supabase / Remote Data Source
```

**Mock Data Layer** (Phase 1 — enables parallel widget development):

Per CLAUDE.md §1.1–§1.2, mock data follows Clean Architecture layer rules:

```
lib/
├── features/
│   └── listings/
│       ├── domain/
│       │   ├── entities/listing_entity.dart      # Pure Dart, no imports
│       │   └── repositories/listing_repository.dart  # Interface only
│       └── data/
│           ├── mock/mock_listing_repository.dart  # Mock impl (Phase 1-2)
│           └── repositories/listing_repository_impl.dart  # Real impl (Phase 4)
```

```dart
// domain/entities/listing_entity.dart — pure Dart, no dependencies
class ListingEntity {
  final String id, title, description;
  final int priceInCents; // cents-based (per PR #24 DeelPriceController, Mollie API compatible)
  final String sellerId, location;
  final List<String> imageUrls;
  final ListingCondition condition;
  // ...
}

// domain/repositories/listing_repository.dart — interface in domain layer
abstract class ListingRepository {
  Future<List<ListingEntity>> getListings({ListingFilters? filters});
  Future<ListingEntity?> getById(String id);
  Future<ListingEntity> create(CreateListingDto dto);
}

// data/mock/mock_listing_repository.dart — mock impl, swapped via Riverpod override
class MockListingRepository implements ListingRepository { ... }
```

**Convention**: Mock repositories live in `data/mock/` within each feature. Swapped to real implementations via Riverpod provider overrides — no `if (isMock)` conditionals anywhere. All entities follow CLAUDE.md §2.1 (max 100 lines) and §2.2 (naming conventions).

This allows widget development (P-19 to P-34) to proceed with mock data while backend (R-22, R-25) is built in parallel.

---

### 4. Deep Design Thinking

**Context**: Dutch P2P marketplace. Users feel UNSAFE on Marktplaats (scams, no protection). They want trust, simplicity, and speed. Target audience: 18-45 Dutch adults, tech-comfortable, price-conscious but safety-aware.

**Identity — What makes DeelMarkt UNFORGETTABLE?**
Trust is VISIBLE, not hidden. Every screen radiates safety:
- Shield iconography is pervasive but never aggressive
- Escrow timeline is the hero of every transaction
- Verification badges build a progressive trust story
- The orange (`#F15A24`) is warm, inviting, Dutch (think: koningsdag, oranje)

**Emotion Mapping**:
| Screen | Primary Emotion | Color Implication | Animation Mood |
|:-------|:---------------|:-----------------|:---------------|
| Home | Discovery, excitement | Warm orange CTAs, light backgrounds | Smooth scroll, subtle parallax |
| Listing Detail | Trust, confidence | Trust-shield green, escrow blue | Hero image expand, price emphasis |
| Search | Focus, efficiency | Clean neutrals, minimal distraction | Snappy filters, instant results |
| Chat | Personal, secure | Neutral bubbles, trust badges in header | Bubble fly-in, typing indicator |
| Transaction | Control, safety | Escrow blue timeline, green confirmations | Step-by-step progress, confetti on complete |
| Onboarding | Welcome, simplicity | Brand orange, friendly illustrations | Page transitions, value prop animations |

**Maestro Auditor Checkpoints** (per screen):
- "Could this be any marketplace template?" → REDESIGN
- "Would I scroll past this on Dribbble?" → REDESIGN
- "Does it feel as polished as Linear's UI?" → SHIP

**FORBIDDEN in DeelMarkt**:
- Generic gradients, glassmorphism, bento grids
- Default Material Design look (must feel custom)
- AI-slop (backdrop-blur as "premium", glow traps)
- Standard 50/50 hero splits — use asymmetry, layered depth

---

### 5. Strategic Roadmap

#### Phase 1 (Week 1): Web Infrastructure & Mock Data Layer
**Objectives**: Flutter Web compiles, routes work, responsive shell ready, mock data enables parallel development.

**Success Criteria**:
- [x] `flutter build web --csp` produces working CanvasKit build with zero CSP violations ✅ PR #14
- [x] `usePathUrlStrategy()` active — URLs have no `#` hashes ✅ PR #14
- [x] All 4 breakpoints render correctly with shell layout ✅ PR #14
- [x] GoRouter auth guard works with splash screen (no flash of unauthenticated content) ✅ PR #14
- [x] `/onboarding` route renders, auth redirect `/home` ↔ `/onboarding` works ✅ PR #14
- [x] Mock data layer provides all entity interfaces with immutable entities ✅ PR #14
- [x] Performance baseline measured and documented ✅ 2026-04-29 — see `docs/observability/web-perf-baseline.md` (bundle 1.55 MB gzip CDN / 4.42 MB local — under 5 MB Phase 1 budget; full Lighthouse pass blocked on `STAGING_URL` C3)
- [x] Web error boundary catches unhandled errors gracefully ✅ PR #14
- [ ] Font loading has no FOUT (Flash of Unstyled Text)
- [x] Dark mode toggle works with all semantic tokens wired ✅ PR #14

**Tasks** (ordered by execution day — 8 working days):

| # | Task | Est | Owner | Day | Fallback | Status |
|:--|:-----|:----|:------|:----|:---------|:-------|
| 0 | **PRE-REQ:** Merge PR #9 to dev, create `feature/pizmam-P45-web-infrastructure` from dev | 0.5h | pizmam | 1 | If PR #9 not mergeable, cherry-pick Unleash service commits only | ✅ Done |
| 1 | **⚠️ DAY 1 BLOCKER:** CSP + CanvasKit WASM validation | 2h | pizmam + belengaz | 1 | If `wasm-unsafe-eval` needed and belengaz unavailable: temporary fallback to `--web-renderer html` (no WASM). Create follow-up ticket for CSP fix. | ✅ PR #14 |
| 1b | **⚠️ CRITICAL:** Add `usePathUrlStrategy()` to `main.dart` | 0.5h | pizmam | 1 | None — this is a one-line change. Without it all URLs break. Add `flutter_web_plugins` import. Must be called BEFORE `WidgetsFlutterBinding.ensureInitialized()`. | ✅ PR #14 |
| 2 | Flutter Web build pipeline — validate Flutter's default Service Worker | 4h | pizmam | 1-2 | Flutter generates `flutter_service_worker.js` automatically. Do NOT write custom SW — it conflicts with Flutter's built-in. Validate cache behaviour only. Custom Workbox optimization deferred to Phase 5. | ✅ PR #14 |
| 3 | `P-48` ADR-019: PWA strategy document | 1h | pizmam | 2 | — | ✅ PR #14 |
| 4 | `P-45` Performance budget + Lighthouse baseline | 4h | pizmam | 2-3 | If Lighthouse < 60 (CanvasKit floor), document and create Phase 5 optimization ticket | ✅ 2026-04-29 bundle baseline — `docs/observability/web-perf-baseline.md` (1.55 MB gzip CDN / 4.42 MB local under 5 MB budget). Lighthouse run pending `STAGING_URL` (C3, belengaz). |
| 5 | `P-49` Responsive shell validation (4 breakpoints) | 2h | pizmam | 3 | — | ✅ PR #14 |
| 6 | `P-50` GoRouter auth guard + splash screen + `/onboarding` route | 4h | pizmam | 4 | See implementation notes below. If race condition unresolvable, deploy placeholder guard that only checks `currentUser != null` (no stream). | ✅ PR #14 |
| 7 | `P-51` Mock data layer (5 entities + repositories + mocks) | 7h | pizmam | 5-6 | If 7h insufficient, prioritize Listing + Category entities only (minimum viable mock layer). User, Transaction, Message deferred to Phase 2 start. | ✅ PR #14 |
| 8 | Dark mode validation (`P-47` part 1) | 4h | pizmam | 7 | — | ✅ PR #14 |
| 9 | `P-52` Web error boundary + font loading strategy | 2h | pizmam | 7 | — | ✅ Error boundary done, font FOUT TBD |
| 10 | Final validation + quality gate | 4h | pizmam | 8 | — | ✅ PR #14 (557 tests, 0 warnings) |

**Phase total: ~37h** / 8 working days (2 weeks at ~25h/week pace)

#### Phase 1 Implementation Notes (from Tier-1 Audit)

**Step 1b — `usePathUrlStrategy()` (CRITICAL):**
```dart
// main.dart — MUST be first line in main()
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  usePathUrlStrategy(); // Remove /#/ from URLs — before binding
  WidgetsFlutterBinding.ensureInitialized();
  await Future.wait([...]);
  runApp(...);
}
```
Without this, all URLs contain `/#/` which breaks SEO, deep links, social sharing, and OG meta tags. This is a one-line fix but blocks the entire web strategy.

**Step 2 — Service Worker Strategy:**
Flutter's `flutter build web` generates `flutter_service_worker.js` automatically. Do NOT create a custom service worker — it will conflict with Flutter's built-in SW lifecycle. For Phase 1:
- Validate that Flutter's default SW caches CanvasKit WASM correctly
- Verify `serviceWorkerVersion` cache-busting in `flutter_bootstrap.js`
- Measure return-visit load time (should be < 2s cached)
- Custom Workbox/SW optimization is a Phase 5 task if baseline metrics require it

**Step 6 — Auth Guard with Splash Screen (Race Condition Fix):**
```dart
// lib/core/router/auth_guard.dart
GoRouter createRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  return GoRouter(
    initialLocation: AppRoutes.home,
    refreshListenable: GoRouterRefreshStream(
      ref.read(supabaseClientProvider).auth.onAuthStateChange
          .map((event) => event.session),
    ),
    redirect: (context, state) {
      final isLoading = authState.isLoading;
      final isLoggedIn = authState.valueOrNull != null;
      final currentPath = state.matchedLocation;

      // Show splash while auth state resolves (prevents FOUC)
      if (isLoading) return '/splash';

      // Auth-required routes
      const protectedRoutes = ['/sell', '/messages', '/profile', '/transactions'];
      const authRoutes = ['/onboarding', '/login', '/register'];

      if (!isLoggedIn && protectedRoutes.any((r) => currentPath.startsWith(r))) {
        return '/onboarding';
      }
      if (isLoggedIn && authRoutes.contains(currentPath)) {
        return '/home';
      }
      return null; // no redirect
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/onboarding', name: 'onboarding', builder: (_, __) => const OnboardingScreen()),
      // ... existing routes ...
    ],
  );
}
```
Key points:
- `GoRouterRefreshStream` re-evaluates redirect on every auth state change
- `/splash` route prevents flash of unauthenticated content during async auth load
- Public routes (`/home`, `/search`, `/listing/:id`) never redirect — anonymous browsing allowed
- Protected routes (`/sell`, `/messages`, `/profile`) redirect to `/onboarding` if not logged in
- `/onboarding` and `/login` redirect to `/home` if already logged in

**Step 7 — Entity Immutability Decision:**
ARCHITECTURE.md lists no `freezed` dependency. Decision: use **manual immutable pattern** with `equatable` for entity equality (needed by Riverpod state diffing):
```dart
// pubspec.yaml — add: equatable: ^2.0.5
// Entity pattern:
class ListingEntity extends Equatable {
  const ListingEntity({
    required this.id,
    required this.title,
    required this.priceInCents,
    // ...
  });

  final String id;
  final String title;
  final int priceInCents;

  ListingEntity copyWith({String? title, int? priceInCents}) {
    return ListingEntity(
      id: id,
      title: title ?? this.title,
      priceInCents: priceInCents ?? this.priceInCents,
    );
  }

  @override
  List<Object?> get props => [id, title, priceInCents];
}
```
Why not `freezed`: avoids code-gen complexity for domain entities that should be simple pure Dart. `equatable` gives us `==` and `hashCode` with minimal overhead. If entity count grows beyond 15, revisit `freezed` in Phase 4.

**Step 9 — Web Error Boundary:**
```dart
// main.dart additions:
void main() async {
  usePathUrlStrategy();
  WidgetsFlutterBinding.ensureInitialized();

  // Web error boundary — show user-friendly error instead of white screen
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    FirebaseCrashlytics.instance.recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Custom error widget for production
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Er ging iets mis. Probeer opnieuw.'))),
    );
  };

  await Future.wait([...]);
  runApp(...);
}
```

**Step 9 — Font Loading Strategy:**
Plus Jakarta Sans is bundled as an asset in `pubspec.yaml` (not loaded from Google Fonts CDN). This means:
- No FOUT risk — font is in the app bundle
- No `<link rel="preload">` needed in `web/index.html`
- Verify: `pubspec.yaml` → `fonts:` section lists Plus Jakarta Sans variants
- If NOT bundled: add `<link rel="preconnect" href="https://fonts.googleapis.com">` to `web/index.html`

**Dependencies**: `B-01` (Cloudflare DNS ✅), `B-36` (CSP ✅ — **needs WASM validation Day 1**), PR #9 merged to dev
**Risk Mitigation**: Every critical step has a documented fallback (see table above). CSP + WASM is Day 1 — if it fails, HTML renderer fallback keeps other work unblocked. belengaz must be available Day 1 for CSP update if needed.
**Quality Gate**: `flutter analyze` clean, responsive shell renders at all 4 breakpoints, performance baseline documented, **CSP validation passing**, ADR-019 written, **`usePathUrlStrategy()` active**, **auth guard with splash screen working**, **web error boundary active**, **no FOUT**.

---

#### Phase 2 (Week 2–3): Auth Screens + Core Trust Widgets (Parallel Tracks)

**Objectives**: Authentication flows work on web. All P0 trust widgets built with mock data. Premium aesthetics enforced.

**Success Criteria**:
- [ ] User can register, login, and see their profile on web
- [ ] All trust widgets render with mock data at all breakpoints
- [ ] Accessibility: every widget has Semantics, 44px targets, 4.5:1 contrast
- [ ] Dark mode validated on every new component

**Track A — Auth Screens** (blocked by R-13):
| Task | Est | Depends | States | Responsive | Accessibility |
|:-----|:----|:--------|:-------|:-----------|:-------------|
| `P-14` Onboarding (language + value prop) | 6h | None | Loading, 3 pages, complete | All 4 breakpoints | Focus order, reduced motion |
| `P-15` Registration (email + phone) | 8h | R-13 | Form validation, OTP input, success, error | All 4 | Form labels, error announce, auto-fill |
| `P-16` Login (email + biometric) | 6h | R-13 | Loading, error, biometric prompt, success | All 4 | Focus, error announce |
| `P-44` Social login (Google + Apple) — if approved | 8h | R-13 + PO approval | OAuth redirect, success, failure, account link | All 4 | Button labels |

**Track B — Trust Widgets** (mock data, NO backend dependency):
| Task | Est | Component Brief | States | Responsive |
|:-----|:----|:---------------|:-------|:-----------|
| `P-19` DeelBadge (7 verification types) | 4h | Reusable, stateless, max 3 inline, tooltip on tap | All 7 types, dark mode | Scale with text size |
| `P-20` DeelAvatar (with badge overlay) | 4h | Reusable, stateless, avatar + positioned badge | Placeholder, loading, loaded, error | 3 sizes |
| `P-21` TrustBanner (escrow protection) | 4h | Reusable, stateless, never dismissible | Escrow active, info variant | Full width, all breakpoints |
| `P-22` DeelCard (grid + list variants) | 8h | Reusable, stateful (favourite toggle), Hero transition | Shimmer, loaded, error, favourited | Grid 2-5 cols, list full width |
| `P-30` ImageGallery (swipe + zoom + Hero) | 8h | Feature-specific, stateful (current page) | Loading, loaded, zoom, fullscreen | Compact: full width, expanded: constrained |
| `P-31` PriceTag (Euro + BTW) | 3h | Reusable, stateless, tabular figures | Regular, strikethrough, offer | Scale with context |
| `P-32` LocationBadge (distance + pin) | 3h | Reusable, stateless | With distance, without distance | Inline |
| `P-33` EscrowTimeline (horizontal stepper) | 6h | Reusable, stateful (active step), tappable steps | 5 states per step (complete/active/pending), dark mode | Horizontal, scrollable on compact |
| `P-34` ScamAlert (inline chat warning) | 4h | Feature-specific, stateless, error-surface bg | Visible, dismissed (if allowed) | Full width |

**Phase total: ~72h (2 weeks)**

**Risk Mitigation**: Primary orange `#F15A24` on white = 3.4:1 contrast — FAILS WCAG for normal text. White-on-orange also fails at 3.4:1 for normal text. **Strict enforcement**: orange+white combination ONLY permitted for large text (≥ 18.66px bold / ≥ 24px regular). For normal-sized button labels (14-16px), use **dark text (`neutral-900`) on orange background** (16.8:1) or **white text on `secondary` blue** (8.1:1). All components must be validated against this rule during implementation. See also: `docs/design-system/tokens.md` §Colours and `docs/design-system/accessibility.md` §Contrast Ratios for the canonical colour pairing rules.
**Maestro Auditor**: Review every widget against "glass trap", "glow trap", "bento trap". Each widget must pass the "could this be a generic template?" test.
**Quality Gate**: `flutter analyze` clean, ≥70% test coverage on new widgets, accessibility audit per widget (Semantics, contrast, touch targets).

---

#### Phase 3 (Week 4): Screens — Profile, Settings, KYC

**Objectives**: User-facing account screens functional. Progressive KYC wired.

**Success Criteria**:
- [ ] Profile screen renders with real user data
- [ ] Settings persist (language, notifications, addresses)
- [ ] KYC prompt triggers contextually (not blocking)
- [ ] All screens tested: loading, error, empty, data states

**Tasks**:
| Task | Est | ViewModel | Use Cases | Repository | States |
|:-----|:----|:----------|:----------|:-----------|:-------|
| `P-17` Profile screen (public view) | 8h | `ProfileViewModel` | `GetUserProfile`, `GetUserBadges` | `UserRepository` | Loading, loaded, error, own vs other |
| `P-18` Settings screen | 8h | `SettingsViewModel` | `UpdateLanguage`, `UpdateNotifications`, `UpdateAddresses` | `SettingsRepository` | Loading, each section, save success/fail |
| `P-23` KYC prompt (contextual) | 6h | `KycViewModel` | `GetKycLevel`, `TriggerKycFlow` | `KycRepository` | Level 0→1 banner, Level 1→2 bottom sheet |
| Dark mode validation pass (`P-47` part 2) | 4h | — | — | — | Every screen light + dark |
| Responsive validation pass | 4h | — | — | — | Every screen × 4 breakpoints |

**Phase total: ~30h**

**Dependencies**: `R-13` (Auth), `R-17` (KYC state machine), `R-19` (User profile table)
**Integration Points**: Coordinate with `reso` — define JSON contract for user profile + KYC level BEFORE Phase 3 starts.
**Quality Gate**: All screens pass CLAUDE.md §7 pre-implementation checklist. Tests cover loading/error/empty/data. `flutter analyze` clean.

---

#### Phase 4 (Week 5–6): Product Screens — Home, Search, Listings

**Objectives**: Core product loop functional (browse → search → view → list). Real backend data.

**Success Criteria**:
- [ ] Home screen shows categories + recent + nearby listings
- [ ] Search returns results with filters working
- [ ] Listing detail shows full layout with trust banner + seller card
- [ ] Listing creation flow: photos → form → quality score → publish
- [ ] Buyer/seller mode toggle adapts home screen

**Tasks**:
| Task | Est | ViewModel | Use Cases | Depends |
|:-----|:----|:----------|:----------|:--------|
| `P-29` Home screen (buyer mode) | 8h | `HomeViewModel` | `GetCategories`, `GetRecentListings`, `GetNearbyListings` | R-22, R-23 |
| `P-41` Seller/buyer mode toggle | 6h | `HomeModeViewModel` | `GetSellerStats`, `GetActionNeeded` | R-22 |
| `P-26` Search screen (FTS + filters) | 10h | `SearchViewModel` | `SearchListings`, `GetFilterOptions` | R-25 (Phase 1: PostgreSQL FTS) |
| `P-27` Category browse | 6h | `CategoryViewModel` | `GetCategories`, `GetL2Subcategories` | R-23 |
| `P-24` Listing creation (photo-first) | 12h | `CreateListingViewModel` | `UploadImages`, `CreateListing`, `GetQualityScore` | R-22, R-26, R-27 |
| `P-25` Listing detail | 10h | `ListingDetailViewModel` | `GetListing`, `ToggleFavourite`, `GetSellerProfile` | R-22, R-24 |
| `P-28` Favourites screen | 4h | `FavouritesViewModel` | `GetFavourites`, `RemoveFavourite` | R-24 |
| `P-46` Dynamic OG meta tags + crawler pre-rendering | 6h | — | — | B-01 — ⚠️ **Owner: belengaz** |
| Micro-animations integration (Hero, favourite burst, shimmer) | 6h | — | — | Lottie assets |

**Phase total: ~68h (2 weeks)**

**Dependencies**: `R-22` (Listings table + RLS), `R-23` (Categories), `R-24` (Favourites), `R-25` (FTS), `R-26` (Quality score), `R-27` (Image upload)
**Risk Mitigation**: Flutter web image gallery performance — test with 12 images at 1080p. Use Cloudinary transformations (see §2 Performance Budget above). Implement virtualized list for search results.
**Search Abstraction** (per `ARCHITECTURE.md` §Search Strategy):
- Phase 1 uses PostgreSQL FTS (R-25) — sufficient for MVP
- `SearchRepository` interface must be backend-agnostic: `Future<SearchResult> search(SearchQuery query)` — no Supabase-specific types in domain layer
- When search migrates to Meilisearch (Phase 2) or Elasticsearch (Phase 4), only `data/repositories/search_repository_impl.dart` changes — UI and domain layers remain untouched
- This aligns with CLAUDE.md §1.2: "Domain never knows about Supabase"
**Integration Points**: `reso` must have R-22 through R-27 ready. Define API contracts (JSON schema for each entity) at Phase 3 start. Use shared Dart interfaces from mock data layer as the contract.
**Quality Gate**: Performance budget met (< 3s first frame, 60fps scroll, search P95 < 500ms per `ARCHITECTURE.md` SLOs). Responsive at all breakpoints. Accessibility audit. ≥70% coverage.

---

#### Phase 5 (Week 7): Polish, Dark Mode, Final Audit

**Objectives**: Production-ready quality. All accessibility requirements met. Dark mode complete. Performance validated.

**Success Criteria**:
- [ ] WCAG 2.2 AA audit passes on ALL screens
- [ ] Dark mode renders correctly on ALL screens
- [ ] Performance budget met across all breakpoints
- [ ] All micro-animations respect `reduced-motion`
- [ ] NL + EN strings complete for all screens

**Tasks**:
| Task | Est |
|:-----|:----|
| `P-42` Full WCAG 2.2 AA accessibility audit | 8h |
| `P-47` Dark mode final validation (part 3) | 6h |
| Performance optimization pass (image caching, lazy loading, tree shaking) | 6h |
| Responsive final validation (all screens × 4 breakpoints) | 4h |
| L10n completeness check (all NL + EN strings) | 4h |
| Micro-animation reduced-motion pass | 3h |
| `P-43` App Store screenshots + ASO metadata | 4h |
| Cross-browser testing (Chrome, Safari, Firefox, Edge) | 4h |
| Staging deployment + smoke test | 3h |

**Phase total: ~42h**

**Quality Gate**: `flutter analyze` zero warnings. `flutter test` all passing. Coverage ≥70%. Lighthouse performance ≥ 80 (target for web-first product; ≥ 60 absolute minimum for CanvasKit baseline — if below 80, create performance improvement roadmap item for post-launch). WCAG 2.2 AA validated. Dark mode validated. All 4 breakpoints validated.

---

### 6. Total Estimates

| Phase | Duration | Hours | Key Deliverable |
|:------|:---------|:------|:---------------|
| Phase 1 | Week 1–2 | ~37h | Web compiles, CSP validated, path URLs, auth guard + splash, mock data (equatable), error boundary, font loading, dark mode tokens, ADR-019 |
| Phase 2 | Week 3–5 | ~72h | Auth flows + all trust widgets |
| Phase 3 | Week 6 | ~30h | Profile, settings, KYC screens |
| Phase 4 | Week 7–8 | ~62h | Home, search (abstracted), listings, creation |
| Contingency | Week 9 | — | Buffer for overflow / rework |
| Phase 5 | Week 10 | ~42h | Polish, dark mode, accessibility, perf, custom SW optimization |
| **TOTAL** | **10 weeks** | **~243h** | **Production-ready web frontend** |

*Estimates assume ~25h/week effective development time (accounts for code review, coordination, context switching, standups). Week 9 is contingency buffer.*

---

### 7. Dependency Timeline

```
Week 1-2:  pizmam (Phase 1) — NO backend dependency
Week 3:    pizmam (Phase 2B widgets) — mock data, NO backend dependency
Week 4:    pizmam (Phase 2A auth) ← NEEDS R-13 from reso (Sprint 3-4)
Week 5:    pizmam (Phase 2 cont.) — reso builds R-17, R-19
Week 6:    pizmam (Phase 3) ← NEEDS R-13, R-17, R-19
           reso starts R-22 to R-27 (Sprint 5-8)
Week 7-8:  pizmam (Phase 4) ← NEEDS R-22 to R-27
Week 9:    Contingency / rework
Week 10:   pizmam (Phase 5) — polish, no new backend deps
```

**Critical Path**: `R-13` (Supabase Auth) must be ready by Week 4. `R-22`–`R-27` (Listings) must be ready by Week 7.

> **Note on R-13 vs R-02**: `R-02` (Supabase Auth email + phone OTP) is already `[x]` — this covers basic email/phone authentication which may satisfy Phase 2A auth screen needs. `R-13` adds KYC-level verification (BRP/DigiD). **If R-02 is sufficient for login/register screens, Phase 2A is unblocked today.** Verify with reso whether R-13 adds new capabilities needed for P-15/P-16 or if R-02's OTP flow is enough.
>
> R-22-R-27 are in Sprint 5-8 (Weeks 9-16). Phase 4 is sequenced at Week 7-8 to align. If reso delivers earlier, Phase 4 can start sooner.

---

### 8. Risk Register

| Risk | Severity | Mitigation |
|:-----|:---------|:-----------|
| **CSP blocks CanvasKit WASM** | **CRITICAL** | **Phase 1, Day 1 blocker.** Current CSP lacks `wasm-unsafe-eval`. Test immediately — if blocked, belengaz updates CSP. **Fallback**: `--web-renderer html` (no WASM) keeps other work unblocked while CSP is fixed. |
| **Missing `usePathUrlStrategy()`** | **CRITICAL** | Without this, all URLs contain `/#/` — breaks SEO, deep links, social sharing, OG meta tags. One-line fix in `main.dart`, must be Day 1. No fallback — must be fixed. |
| **Auth guard race condition** | **HIGH** | Supabase auth state loads async — router may redirect before state resolves, causing flash of unauthenticated content. Fix: `GoRouterRefreshStream` + `/splash` route while auth loads. **Fallback**: simple `currentUser != null` check (no stream) as placeholder. |
| CanvasKit 2MB+ initial download | HIGH | Flutter's default Service Worker caches WASM. Do NOT write custom SW (conflicts). Measure real-world 4G load time. Custom Workbox optimization deferred to Phase 5 if baseline < 60 Lighthouse. |
| **Web session auth (no HttpOnly cookies)** | **HIGH** | `R-NEW-WEB-SESSION` Edge Function not yet scoped. Without it, web auth uses `localStorage` (XSS-vulnerable). Fallback: strict CSP + Supabase default persistence. Must be resolved before Phase 2A auth screens go to production. |
| **PR #9 merge dependency** | **HIGH** | Phase 1 branch must be created from dev AFTER PR #9 is merged (contains Unleash service in `main.dart`). If not merged, cherry-pick Unleash commits only. |
| R-13 (Auth) not ready by Week 2 | HIGH | Phase 2 Track A uses mock auth; real integration deferred to Phase 3. **Note**: R-02 (email + phone OTP) is already ✅ — may be sufficient for P-15/P-16 login/register. Verify with reso. |
| **Entity immutability** | **HIGH** | Riverpod state diffing requires entity equality. Decision: `equatable` package (not `freezed`) for `==` + `hashCode`. Manual `copyWith`. If entity count grows beyond 15, revisit `freezed` in Phase 4. |
| Primary orange contrast failure | MEDIUM | White-on-orange for CTAs; secondary blue for small text. Per `accessibility.md` §Contrast Ratios. Documented in Phase 2 |
| **Web error boundary missing** | MEDIUM | Flutter web shows white screen on unhandled errors. Fix: `FlutterError.onError` + `PlatformDispatcher.instance.onError` + custom `ErrorWidget.builder` in `main.dart`. |
| **Font FOUT risk** | MEDIUM | Plus Jakarta Sans must be bundled in `pubspec.yaml` assets (not Google Fonts CDN). If CDN-loaded, add `<link rel="preconnect">` to `web/index.html`. Verify in Phase 1 Step 9. |
| Flutter Web image gallery jank | MEDIUM | Cloudinary resize (see §2 transformation strategy) + lazy load + virtualization. Test with 12 images in Phase 4 |
| **Search backend migration** | LOW | `SearchRepository` interface is backend-agnostic (per CLAUDE.md §1.2). PostgreSQL FTS → Meilisearch → Elasticsearch migration only touches `data/` layer. No UI impact. |
| Single-developer velocity risk | HIGH | Mock data layer enables parallel widget development. Phase 2 is most parallelizable. **Bus factor mitigation**: `reso` designated as frontend backup — schedule 1h knowledge-sharing per phase. **MVP scope cut order**: if delayed, cut P-28 (Favourites) → P-27 (Category browse) → P-41 (Seller mode) → P-23 (KYC prompt) in that order. **Contingency buffer**: 1 week buffer between Phase 4 and 5 for overflow. **Mock data fallback**: if 7h insufficient, ship with Listing + Category only (minimum viable). |
| GoRouter deep link edge cases | MEDIUM | Test email OTP callback URLs on 3+ browsers in Phase 1 |
| **Dark mode token drift** | MEDIUM | P-47 is split across 3 phases — risk of inconsistency. Mitigation: Phase 1 wires ALL token values from `tokens.md` §Dark Mode upfront (including semantic colours). Phase 2/3 validate per-component. Phase 5 does full audit. |

---

### 9. Quality Gates Between Phases

Each phase MUST pass before the next begins:

| Gate | Criteria |
|:-----|:---------|
| Phase 1 → 2 | `flutter build web --csp` succeeds, **CSP + WASM validated (zero console violations)**, `usePathUrlStrategy()` active (no `/#/` in URLs), all 4 breakpoints work, auth guard with splash screen (no FOUC), `/onboarding` route exists, performance baseline documented, ADR-019 (PWA) written, all `tokens.md` dark mode values wired, mock data layer follows Clean Architecture with equatable entities, web error boundary active, font loading validated (no FOUT) |
| Phase 2 → 3 | All widgets pass accessibility audit (per `accessibility.md`), ≥70% test coverage, Maestro Auditor approval, dark mode validated per component, **web session strategy decided** (R-NEW-WEB-SESSION scoped or fallback documented) |
| Phase 3 → 4 | Auth flow works end-to-end on web, profile/settings persist, KYC triggers correctly, **API contracts (JSON schema) defined for all Phase 4 entities** |
| Phase 4 → 5 | Core product loop works (browse → search → view → list), performance budget met (**search P95 < 500ms**), `SearchRepository` interface is backend-agnostic |
| Phase 5 → Launch | WCAG 2.2 AA audit passes, dark mode validated (all semantic tokens), cross-browser tested, staging deployed, **Lighthouse ≥ 80** |

---

### 10. Competitive Advantages (from Quality Gate Research)

| vs Competitor | DeelMarkt Advantage |
|:-------------|:-------------------|
| vs Marktplaats | Mandatory escrow, seller ratings, trust badges, modern UI, WCAG 2.2 AA |
| vs Vinted | Web-first (not secondary), dark mode, Dutch-specific (iDEAL, postcode, NL/EN native) |
| vs Kleinanzeigen | Modern design system, seller ratings, accessibility, social login |
| vs FB Marketplace | Standalone (no FB account), premium UX, Dutch payment integration, privacy |
| vs Wallapop | Dutch market focus, iDIN bank verification, PostNL/DHL native integration |

---

### 11. Architecture Alignment (v3.0)

**Reference documents validated against:**
- `CLAUDE.md` — Development rules, Clean Architecture, file conventions
- `docs/ARCHITECTURE.md` — Tech stack, search strategy, SLOs, ADRs
- `docs/design-system/tokens.md` — Colours, typography, spacing, dark mode
- `docs/design-system/components.md` — Component library (P0)
- `docs/design-system/patterns.md` — UI patterns
- `docs/design-system/accessibility.md` — WCAG 2.2 AA requirements
- `docs/epics/README.md` — Epic structure and execution order

**v3.0 fixes applied:**

| Finding | Severity | Fix Applied |
|:--------|:---------|:-----------|
| CSP lacks `wasm-unsafe-eval` for CanvasKit | CRITICAL | Added as Phase 1 Day 1 blocker task |
| Web session auth not scoped | HIGH | Added `R-NEW-WEB-SESSION` task + fallback strategy |
| Mock data layer conventions undefined | MEDIUM | Added Clean Architecture file structure + Riverpod override pattern |
| PWA not in ARCHITECTURE.md | MEDIUM | Added ADR-019 requirement to Phase 1 |
| Dark mode tokens incomplete in plan | MEDIUM | Added explicit `tokens.md` §Dark Mode mapping + semantic colours |
| Search not abstracted from backend | MEDIUM | Added `SearchRepository` abstraction + migration path reference |
| Cloudinary optimization not detailed | LOW | Added transformation strategy per component type + SLO reference |
| API contracts undefined | LOW | Added JSON schema definition step to Phase 3→4 gate |

**v3.1 fixes applied (Tier-1 Audit):**

| Finding | Severity | Fix Applied |
|:--------|:---------|:-----------|
| `usePathUrlStrategy()` missing in `main.dart` | CRITICAL | Added as Phase 1 Step 1b — Day 1 mandatory. Without it all URLs contain `/#/`. |
| Auth guard race condition (flash of unauth content) | CRITICAL | Added `GoRouterRefreshStream` + `/splash` route pattern to Phase 1 Step 6. Full code example in implementation notes. |
| `/onboarding` route not defined in `app_router.dart` | HIGH | Added to Phase 1 Step 6 scope — route + `OnboardingScreen` placeholder. |
| Entity immutability pattern undefined | HIGH | Decision: `equatable` package (not `freezed`). Manual `copyWith`. Code example in Step 7 notes. Revisit at 15+ entities. |
| Custom Service Worker conflicts with Flutter's built-in | HIGH | Changed Step 2 from "custom SW" to "validate Flutter's default SW". Custom Workbox deferred to Phase 5. |
| PR #9 merge dependency not tracked | HIGH | Added Step 0 — merge PR #9 to dev before branching. Fallback: cherry-pick Unleash commits. |
| Web error boundary missing | MEDIUM | Added Phase 1 Step 9 — `FlutterError.onError` + `PlatformDispatcher.instance.onError` + custom `ErrorWidget.builder`. |
| Font FOUT risk on web | MEDIUM | Added Phase 1 Step 9 — verify Plus Jakarta Sans is bundled (not CDN). If CDN, add preconnect. |
| No rollback strategy per step | MEDIUM | Added fallback column to Phase 1 task table. Every critical step has documented alternative. |
| Timeline Day 7 overloaded | LOW | Expanded to 8 working days. Step 8 (dark mode) and Step 9 (error boundary + fonts) separated. |

**Alignment score: 9.2/10 → 9.8/10 (v3.0) → 10/10 (v3.1)** — all audit findings resolved.

---

Approve to proceed with Phase 1 execution.
