## Plan: Frontend Task Analysis & Web Launch Roadmap — v2.0

> **Quality Gate**: APPROVED (2026-03-25) — Market research completed, 5 competitors analyzed.
> **Author**: pizmam (Emre Dursun) | **Reviewer**: Senior Staff Engineer audit
> **Status**: Ready for execution | **Phases**: 5 (expanded from 4)

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

**✅ COMPLETED (Sprint 1–2)**
- `P-01`–`P-10` Design system foundation (fonts, icons, i18n, core widgets)

**⚠️ OPEN — Previously assumed complete, still unchecked in SPRINT-PLAN.md**
- `P-11` GDPR consent banner — `[ ]` in sprint plan, added to Phase 1
- `P-12` WCAG 2.2 AA audit tooling — `[ ]` in sprint plan, added to Phase 1
- `P-13` Widget tests ≥70% coverage — `[ ]` in sprint plan, added to Phase 1

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

**PROPOSED NEW TASKS** (from Quality Gate research — require team approval + SPRINT-PLAN.md registration)
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
- CSP headers configured for CanvasKit (`wasm-unsafe-eval` for WASM) — ⚠️ `B-36` still `[ ]` in sprint plan. **Blocker**: coordinate with belengaz to complete B-36 before Phase 1 web build testing.
- PWA manifest + Service Worker for offline shell

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
- Email + phone OTP via Supabase Auth
- Session persistence: `flutter_secure_storage` (mobile), `HttpOnly` secure cookies via backend (web) — NOT `localStorage`, which is vulnerable to XSS. Requires custom web session handler that sets `HttpOnly; Secure; SameSite=Strict` cookies via Supabase Edge Function.
- Biometric auth (mobile only): Face ID / Fingerprint

**Performance Budget** (Flutter Web specific):
- Time to first frame: < 3s on 4G
- CanvasKit WASM load: < 2s cached (Service Worker)
- Total initial download: < 5MB (including CanvasKit + app)
- Frame budget: 16.6ms (60fps)
- Image gallery scroll: 0 jank frames
- Cloudinary images: `f_auto,q_auto,w_auto` (WebP/AVIF)

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

// data/mock/ — mock implementations of repository interfaces
class MockListingRepository implements ListingRepository { ... }
```

This allows widget development (P-19 to P-34) to proceed with mock data while backend (R-22, R-25) is built in parallel.

---

### 4. Deep Design Thinking (per frontend-specialist agent)

> **Note**: The "Maestro Auditor", "Emotion Mapping", and "FORBIDDEN" rules below are proposals from the frontend-specialist agent. They should be formally added to `docs/design-system/` if the team approves them. Until then, they serve as guidelines for pizmam's implementation.

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
- [ ] `flutter build web` produces working CanvasKit build
- [ ] All 4 breakpoints render correctly with shell layout
- [ ] GoRouter path URL strategy works (no `#` hashes)
- [ ] Mock data layer provides all entity interfaces
- [ ] Performance baseline measured and documented

**Tasks**:
| Task | Est | Owner | States to Test |
|:-----|:----|:------|:---------------|
| Flutter Web build pipeline + CanvasKit caching strategy | 6h | pizmam | Build success, Service Worker caching, WASM load time |
| `P-NEW-02` Performance budget definition + baseline measurement | 4h | pizmam | First frame time, bundle size, Lighthouse audit |
| Responsive shell validation (ResponsiveBody already in PR #23) | 2h | pizmam | Verify compact/medium/expanded/large, bottom nav ↔ side rail on web |
| GoRouter auth guards addition (router already in `app_router.dart`) | 2h | pizmam | Auth redirect works, back/forward work, 404 fallback |
| `P-11` GDPR consent banner | 4h | pizmam | Shown on first launch, preference saved, blocking overlay on web |
| `P-12` WCAG 2.2 AA audit tooling pipeline in CI | 4h | pizmam | Contrast + touch target checks in test pipeline |
| `P-13` Widget tests for existing shared components | 8h | pizmam | ≥70% coverage on `lib/widgets/` |
| Mock data contracts (Dart interfaces + mock implementations) | 6h | pizmam | All entities: Listing, User, Transaction, Message, Category |
| PWA manifest + web/index.html meta tags | 2h | pizmam | Installable PWA, correct OG defaults |
| Dark mode ThemeData wiring (`P-NEW-04` part 1) | 4h | pizmam | Light/dark switch, all token colors map correctly |

**Phase total: ~46h (includes P-11, P-12, P-13 carried over)**

**Dependencies**: `B-01` (Cloudflare DNS ✅), `B-36` (CSP — ⚠️ still open, coordinate with belengaz)
**Risk Mitigation**: CanvasKit WASM + CSP conflict — test immediately. If `wasm-unsafe-eval` is blocked, coordinate with belengaz to update CSP.
**Quality Gate**: `flutter analyze` clean, responsive shell renders at all 4 breakpoints, performance baseline documented.

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

**Risk Mitigation**: Primary orange `#F15A24` on white = 3.4:1 contrast — FAILS WCAG for normal text. White-on-orange also fails at 3.4:1 for normal text. **Strict enforcement**: orange+white combination ONLY permitted for large text (≥ 18.66px bold / ≥ 24px regular). For normal-sized button labels (14-16px), use **dark text (`neutral-900`) on orange background** (16.8:1) or **white text on `secondary` blue** (8.1:1). All components must be validated against this rule during implementation.
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
| Dark mode validation pass (`P-NEW-04` part 2) | 4h | — | — | — | Every screen light + dark |
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
| `P-26` Search screen (FTS + filters) | 10h | `SearchViewModel` | `SearchListings`, `GetFilterOptions` | R-25 |
| `P-27` Category browse | 6h | `CategoryViewModel` | `GetCategories`, `GetL2Subcategories` | R-23 |
| `P-24` Listing creation (photo-first) | 12h | `CreateListingViewModel` | `UploadImages`, `CreateListing`, `GetQualityScore` | R-22, R-26, R-27 |
| `P-25` Listing detail | 10h | `ListingDetailViewModel` | `GetListing`, `ToggleFavourite`, `GetSellerProfile` | R-22, R-24 |
| `P-28` Favourites screen | 4h | `FavouritesViewModel` | `GetFavourites`, `RemoveFavourite` | R-24 |
| `P-46` Dynamic OG meta tags + crawler pre-rendering | 6h | — | — | B-01 — ⚠️ **Owner: belengaz** |
| Micro-animations integration (Hero, favourite burst, shimmer) | 6h | — | — | Lottie assets |

**Phase total: ~68h (2 weeks)**

**Dependencies**: `R-22` (Listings table + RLS), `R-23` (Categories), `R-24` (Favourites), `R-25` (FTS), `R-26` (Quality score), `R-27` (Image upload)
**Risk Mitigation**: Flutter web image gallery performance — test with 12 images at 1080p. Use Cloudinary `f_auto,q_auto,w_800` for web thumbnails. Implement virtualized list for search results.
**Integration Points**: `reso` must have R-22 through R-27 ready. Define API contracts at Phase 3 start.
**Quality Gate**: Performance budget met (< 3s first frame, 60fps scroll). Responsive at all breakpoints. Accessibility audit. ≥70% coverage.

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
| `P-NEW-04` Dark mode final validation (part 3) | 6h |
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
| Phase 1 | Week 1–2 | ~46h | Web compiles, responsive shell, mock data, P-11/P-12/P-13 |
| Phase 2 | Week 3–5 | ~72h | Auth flows + all trust widgets |
| Phase 3 | Week 6 | ~30h | Profile, settings, KYC screens |
| Phase 4 | Week 7–8 | ~62h | Home, search, listings, creation |
| Contingency | Week 9 | — | Buffer for overflow / rework |
| Phase 5 | Week 10 | ~42h | Polish, dark mode, accessibility, perf |
| **TOTAL** | **10 weeks** | **~252h** | **Production-ready web frontend** |

*Estimates assume ~25h/week effective development time (accounts for code review, coordination, context switching, standups). Week 9 is contingency buffer.*

---

### 7. Dependency Timeline

```
Week 1-2:  pizmam (Phase 1) — NO backend dependency. B-36 (CSP) needed from belengaz.
Week 3:    pizmam (Phase 2B widgets) — mock data, NO backend dependency
Week 4:    pizmam (Phase 2A auth) ← NEEDS R-13 from reso (Sprint 3-4)
Week 5:    pizmam (Phase 2 cont.) — reso builds R-17, R-19
Week 6:    pizmam (Phase 3) ← NEEDS R-13, R-17, R-19
           reso starts R-22 to R-27 (Sprint 5-8)
Week 7-8:  pizmam (Phase 4) ← NEEDS R-22 to R-27
Week 9:    Contingency / rework
Week 10:   pizmam (Phase 5) — polish, no new backend deps
```

**Critical Path**: `B-36` (CSP) must be ready by Week 1. `R-13` (Supabase Auth) must be ready by Week 4. `R-22`–`R-27` (Listings) must be ready by Week 7.

> **Note**: This timeline is aligned with SPRINT-PLAN.md sequencing: R-13 is in Sprint 3-4 (Weeks 5-8), R-22-R-27 in Sprint 5-8 (Weeks 9-16). Phase 2A auth screens are sequenced AFTER R-13 is expected from reso's sprint. If reso delivers R-13 earlier, Phase 2A can start sooner.

---

### 8. Risk Register

| Risk | Severity | Mitigation |
|:-----|:---------|:-----------|
| CanvasKit 2MB+ initial download | HIGH | Service Worker cache-first strategy; measure real-world 4G load time in Phase 1 |
| R-13 (Auth) not ready by Week 2 | HIGH | Phase 2 Track A uses mock auth; real integration deferred to Phase 3 |
| Primary orange contrast failure | MEDIUM | White-on-orange for CTAs; secondary blue for small text. Documented in Phase 2 |
| Flutter Web image gallery jank | MEDIUM | Cloudinary resize + lazy load + virtualization. Test with 12 images in Phase 4 |
| Single-developer velocity risk | HIGH | Mock data layer enables parallel widget development. Phase 2 is most parallelizable. **Bus factor mitigation**: `reso` designated as frontend backup — schedule 1h knowledge-sharing per phase. **MVP scope cut order**: if delayed, cut P-28 (Favourites) → P-27 (Category browse) → P-41 (Seller mode) → P-23 (KYC prompt) in that order. **Contingency buffer**: 1 week buffer between Phase 4 and 5 for overflow |
| GoRouter deep link edge cases | MEDIUM | Test email OTP callback URLs on 3+ browsers in Phase 1 |

---

### 9. Quality Gates Between Phases

Each phase MUST pass before the next begins:

| Gate | Criteria |
|:-----|:---------|
| Phase 1 → 2 | `flutter build web` succeeds, all 4 breakpoints work, performance baseline documented |
| Phase 2 → 3 | All widgets pass accessibility audit, ≥70% test coverage, Maestro Auditor approval |
| Phase 3 → 4 | Auth flow works end-to-end on web, profile/settings persist, KYC triggers correctly |
| Phase 4 → 5 | Core product loop works (browse → search → view → list), performance budget met |
| Phase 5 → Launch | WCAG 2.2 AA audit passes, dark mode validated, cross-browser tested, staging deployed |

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

Approve to proceed with Phase 1 execution.
