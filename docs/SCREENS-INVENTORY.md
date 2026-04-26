# DeelMarkt — Screen Inventory & Design Plan

> Complete inventory of all app screens with implementation status.
> Use this as the reference for generating designs for each screen.

**Last updated:** 2026-04-25
**Maintainer:** pizmam (`@emredursun`)
**Next review:** 2026-06-24 (60 days)
**Staling check:** `scripts/check_screens_inventory.dart` (warns at 60 d, fails at 120 d)

---

## Summary

| Status                          | Count |
|---------------------------------|-------|
| Implemented                     | 28    |
| Implemented (placeholder copy)  | 2     |
| In Progress                     | 0     |
| Blocked                         | 0     |
| Not started                     | 0     |
| **Total screens**               | **30** |
| Shared widgets (non-screen)     | 17    |
| Implemented widgets             | 17    |

> 🎉 **Sprint 9–10 complete.** All 30 planned MVP screens shipped or in placeholder-copy state. Remaining work: launch-week polish (`ALL-04` seed listings, `ALL-05` store metadata) and audit follow-ups (P-54..P-58, R-39..R-45, B-56..B-69) — see `docs/audits/2026-04-25-tier1-retrospective.md`.

---

## Status Vocabulary

| Value | Meaning |
|-------|---------|
| **Implemented** | Screen file present, real Supabase wiring done, real copy + l10n keys, responsive variants ship-ready, golden test coverage exists. |
| **Implemented (placeholder copy)** | All wiring done; copy still uses provisional / `_TBD` strings or test data. Legal review pending. |
| **In Progress** | Active feature branch open; not yet merged to `dev`. |
| **Blocked** | Implementation halted on a named external dependency (account, third-party API, ADR sign-off). The blocker name is required. |
| **Not started** | No screen file, no branch, no spec md beyond this row. |

---

## 1. Auth / Onboarding

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 1 | **Onboarding** | P-14 | ✅ Implemented (PR #28) | `lib/features/onboarding/presentation/screens/onboarding_screen.dart` |
| 2 | **Registration** | P-15 | ✅ Implemented (PR #40) | `lib/features/auth/presentation/screens/register_screen.dart` |
| 3 | **Login** | P-16 | ✅ Implemented (PR #43) | `lib/features/auth/presentation/screens/login_screen.dart` |
| 4 | **KYC Prompt** | P-23 | ✅ Implemented (PR #45) — bottom sheet, not a route | `lib/features/auth/presentation/widgets/kyc_prompt_sheet.dart` |
| 5 | **Social Login** | P-44 | ✅ Implemented (PR #159) — native iOS ASAuth + Android google_sign_in + web redirect | `lib/features/auth/presentation/widgets/social_login_buttons.dart` |

**Design notes:**
- Trust-first: show escrow protection messaging prominently
- Dutch-first: NL as default, EN toggle visible
- Biometric: Face ID / fingerprint prompt on login
- Dependencies: R-13 (Supabase Auth), R-17 (KYC state machine)

---

## 2. Home / Browse

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 6 | **Home (Buyer mode)** | P-29 / B-50 | ✅ Implemented — golden coverage: light/dark × phone/tablet/desktop | `lib/features/home/presentation/screens/home_screen.dart` |
| 7 | **Home (Seller mode)** | P-41 | ✅ Implemented (PR #107) — toggle in unified screen | `lib/features/home/presentation/screens/home_screen.dart` |
| 8 | **Search** | P-26 / B-52 | ✅ Implemented (PR #210) — desktop filter sidebar + FTS | `lib/features/search/presentation/screens/search_screen.dart` |
| 9 | **Category Browse** | P-27 | ✅ Implemented (PR #65, #209 desktop) | `lib/features/home/presentation/screens/category_browse_screen.dart` |

**Design notes:**
- Home is the primary landing screen — must feel premium, not cluttered
- Search: instant results, Dutch language FTS ("fietsen" matches "fiets")
- Category icons should match the marketplace aesthetic
- Responsive: compact (1-2 col grid), expanded (3-5 col grid)
- Dependencies: R-22 (Listings), R-23 (Categories), R-25 (FTS)

---

## 3. Listings

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 10 | **Listing Detail** | P-25 / B-51 | ✅ Implemented — gallery + trust banner + seller card + CTA, deep linked | `lib/features/listing_detail/presentation/listing_detail_screen.dart` |
| 11 | **Listing Creation** | P-24 | ✅ Implemented — photo-first: camera → form → score → publish | `lib/features/sell/presentation/screens/listing_creation_screen.dart` |
| 12 | **Favourites** | P-28 | ✅ Implemented (PR #65) | `lib/features/home/presentation/screens/favourites_screen.dart` |

**Design notes:**
- Listing detail: Hero image gallery with swipe + pinch-zoom
- Trust banner: "Protected by DeelMarkt Escrow" — always visible, never dismissible
- Seller card: avatar + badges + response time + rating
- Quality score: red/amber/green bar encouraging better photos/description
- Creation flow: photo-first (camera opens immediately), then form fields
- Dependencies: R-22, R-24 (Favourites), R-26 (Quality score), R-27 (Image upload)

---

## 4. Payments / Transaction

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 13 | **Payment Summary** | E03 | ✅ Implemented — embedded section in transaction flow | `lib/features/transaction/presentation/screens/transaction_detail_screen.dart` |
| 14 | **Mollie Checkout** | B-14 | ✅ Implemented — WebView for iDEAL via Mollie | `lib/features/transaction/presentation/screens/mollie_checkout_screen.dart` ⚠️ §2.1 budget breach (248 LOC) — see `P-54` |
| 15 | **Transaction Detail** | B-24 | ✅ Implemented — escrow timeline + amounts + action buttons | `lib/features/transaction/presentation/screens/transaction_detail_screen.dart` |

**Design notes:**
- Payment summary: clear breakdown (item + EUR 1.50 platform fee + shipping)
- Escrow timeline: horizontal stepper (paid → shipped → delivered → confirmed → released)
- Action buttons: "Confirm Delivery" (success), "Open Dispute" (destructive)
- Trust: "Your money is safe" messaging throughout
- Dependencies: B-13–B-24 (all done)

---

## 5. Shipping

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 16 | **Shipping QR** | B-29 | ✅ Implemented | `lib/features/shipping/presentation/screens/shipping_qr_screen.dart` |
| 17 | **Tracking Timeline** | B-30 | ✅ Implemented | `lib/features/shipping/presentation/screens/tracking_screen.dart` |
| 18 | **ParcelShop Selector** | B-31 | ✅ Implemented (master-detail, map placeholder) | `lib/features/shipping/presentation/screens/parcel_shop_selector_screen.dart` ⚠️ no widget test — see `B-XX` follow-up |

**Design notes:**
- QR screen: large QR code, carrier badge, "Ship by" deadline, "Find service point" CTA
- Tracking: real-time updates, carrier logo, estimated delivery
- ParcelShop: compact (full-width list), expanded (master-detail with map placeholder)
- All 3 screens use ResponsiveBody wrapper (max 600px centered on tablet/desktop)
- Dependencies: B-25–B-28 (all done)

---

## 6. Chat / Messages

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 19 | **Conversation List** | P-35 | ✅ Implemented (PR #71) | `lib/features/messages/presentation/screens/conversation_list_screen.dart` |
| 20 | **Chat Thread** | P-36 | ✅ Implemented (PR #71) | `lib/features/messages/presentation/screens/chat_thread_screen.dart` ⚠️ §2.1 budget breach (228 LOC) — see `P-54` |
| 21 | **Scam Alert** | P-37 | ✅ Implemented (PR #75) — inline component, not a route | `lib/features/messages/presentation/widgets/scam_alert_banner.dart` |

**Design notes:**
- Conversation list: WhatsApp-style with listing context
- Chat thread: message bubbles (buyer blue, seller grey), embedded listing card
- Structured offers: "Make an Offer" button → offer message with accept/decline
- Scam alert: red warning banner, non-dismissible on high-confidence flags
- Real-time: Supabase Realtime for live messages
- Dependencies: R-31 (Messages table + Realtime), R-32 (Offers), R-35 (Scam detection)

---

## 7. Profile / Settings

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 22 | **Own Profile** | P-17 | ✅ Implemented | `lib/features/profile/presentation/screens/own_profile_screen.dart` |
| 23 | **Seller Profile (public)** | P-39 | ✅ Implemented (PR #75) | `lib/features/profile/presentation/screens/public_profile_screen.dart` |
| 24 | **Settings** | P-18 | ⚠️ Implemented (placeholder copy) — avatar upload blocked on `#148` (R-42 in audit) | `lib/features/profile/presentation/screens/settings_screen.dart` |
| 25 | **Rating/Review** | P-38 | ✅ Implemented (PR #75) — blind reveal | `lib/features/profile/presentation/screens/review_screen.dart` |

**Design notes:**
- Profile: trust badges prominently displayed (email verified, phone, iDIN, etc.)
- Seller profile: average rating (hidden if < 3 reviews), reviews chronological
- Settings: grouped sections, each with save confirmation
- Rating: 1-5 stars + optional text, blind (both parties submit before reveal)
- Dependencies: R-19 (User profile), R-36 (Reviews), R-20 (GDPR deletion)

**Bonus screens (not in original 30 scope):**
- **Suspension Gate** — `suspension_gate_screen.dart` (P-53, PR #152–153)
- **Appeal** — `appeal_screen.dart` (P-53, PR #152–153) ⚠️ §2.1 budget breach (205 LOC) — see `P-54`

---

## 8. Admin / Moderation

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 26 | **Admin Panel** | P-40 | ⚠️ Implemented (placeholder copy) — Phase A done; `is_admin()` is client-side stub (R-40 / preflight `C1`) — admin panel must be **feature-flagged off** in production builds until Phase B lands | `lib/features/admin/presentation/screens/admin_dashboard_screen.dart`, `admin_shell_screen.dart` |

**Design notes:**
- Web/desktop only (Retool or custom Flutter web)
- Queues: flagged listings, reported users, open disputes, DSA notices
- SLA dashboard: 24-hour response time tracking for DSA
- Dependencies: R-35 (Scam detection), R-37 (Dispute resolution), R-38 (DSA)

---

## 9. Web-only / Cross-platform (Phase 2)

These were added in Sprint 9–10 to support `P-45..P-52` web targets:

| # | Screen | Task | Status | File |
|---|--------|------|--------|------|
| 27 | **Splash + Auth Guard** | P-50 | ✅ Implemented (PR #14) — GoRouter splash | `lib/core/router/app_router.dart` |
| 28 | **Web error boundary** | P-52 | ✅ Implemented (PR #14) | `lib/core/services/web_error_boundary.dart` |
| 29 | **Messages Responsive Shell** | P-49 | ✅ Implemented (PR #194) — 4-breakpoint, 840px nav switch | `lib/features/messages/presentation/screens/messages_responsive_shell.dart` |
| 30 | **Adaptive Listing Grid host** | P-49 (PR #213) | ✅ Implemented — container-aware via SliverLayoutBuilder | `lib/widgets/cards/adaptive_listing_grid.dart` |

---

## Shared Widgets (used across screens)

| Widget | Task | Status | File |
|--------|------|--------|------|
| DeelBadge (7 verification types) | P-19 | ✅ Implemented | `lib/widgets/badges/deel_badge.dart` |
| DeelAvatar (with badge overlay) | P-20 | ✅ Implemented | `lib/widgets/badges/deel_avatar.dart` |
| TrustBanner (escrow protection) | P-21 | ✅ Implemented | `lib/widgets/trust/escrow_trust_banner.dart` |
| DeelCard (grid + list variants) | P-22 | ✅ Implemented | `lib/widgets/cards/deel_card.dart` |
| ImageGallery (swipe + zoom) | P-30 | ✅ Implemented | `lib/widgets/media/image_gallery_page.dart` |
| PriceTag (Euro + BTW) | P-31 | ✅ Implemented (PR #99) | `lib/widgets/price/price_tag.dart` |
| LocationBadge (distance + pin) | P-32 | ✅ Implemented (PR #101) | `lib/widgets/location/location_badge.dart` |
| EscrowTimeline (horizontal stepper) | P-33 | ✅ Implemented (with onStepTapped wiring PR #101) | `lib/widgets/payment/escrow_timeline.dart` |
| ScamAlert (inline chat warning) | P-34 | ✅ Implemented (PR #75) | `lib/features/messages/presentation/widgets/scam_alert_banner.dart` |
| ShippingQrCard | B-29 | ✅ Implemented | `lib/features/shipping/presentation/widgets/shipping_qr_card.dart` |
| TrackingTimeline | B-30 | ✅ Implemented | `lib/features/shipping/presentation/widgets/tracking_timeline.dart` |
| DutchAddressInput | B-32 | ✅ Implemented | `lib/widgets/inputs/dutch_address_input.dart` |
| ResponsiveBody | — | ✅ Implemented | `lib/widgets/layout/responsive_body.dart` |
| AdaptiveListingGrid | P-49 (PR #213) | ✅ Implemented | `lib/widgets/cards/adaptive_listing_grid.dart` |
| SkeletonLoader (shimmer) | P-07 | ✅ Implemented | `lib/widgets/feedback/skeleton_loader.dart` |
| EmptyState | P-08 | ✅ Implemented | `lib/widgets/feedback/empty_state.dart` |
| ErrorState | P-09 | ✅ Implemented | `lib/widgets/feedback/error_state.dart` |
| LanguageSwitch | P-10 | ✅ Implemented | `lib/widgets/settings/language_switch.dart` |
| GdprConsentBanner | P-11 | ✅ Implemented | `lib/widgets/consent/gdpr_consent_banner.dart` |

---

## A. Responsive Variant Matrix

> Cell legend: ✅ golden coverage exists · ⚠️ implemented but golden missing or stale · ❌ not yet supported

The breakpoints follow `lib/core/design_system/breakpoints.dart`:

- **compact:** < 600 px (phone)
- **medium:** 600–840 px (tablet)
- **expanded:** ≥ 840 px (desktop / large tablet landscape)

| Screen | Compact light | Compact dark | Medium light | Medium dark | Expanded light | Expanded dark |
|--------|:-------------:|:------------:|:------------:|:-----------:|:--------------:|:-------------:|
| Home (Buyer) | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Home (Seller) | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| Search | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Category Browse | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Category Detail | ✅ | ✅ | ⚠️ | ⚠️ | ✅ | ⚠️ |
| Favourites | ✅ | ✅ | ✅ | ✅ | ✅ | ⚠️ |
| Listing Detail | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| Listing Creation | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| Conversation List | ✅ | ✅ | ✅ | ✅ | ✅ (shell) | ⚠️ |
| Chat Thread | ✅ | ✅ | ✅ | ✅ | ✅ (shell) | ⚠️ (#203 fix in flight) |
| Own Profile | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| Public Profile | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| Settings | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| Mollie Checkout | ⚠️ (WebView) | ⚠️ (WebView) | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Transaction Detail | ✅ | ✅ | ✅ | ✅ | ⚠️ (PR #207 desktop split) | ⚠️ |
| Shipping QR | ✅ | ✅ | ✅ | ✅ | ⚠️ | ⚠️ |
| Tracking Timeline | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| ParcelShop Selector | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Onboarding | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Registration | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Login | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Review | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Appeal | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Suspension Gate | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |
| Admin Dashboard | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ | ⚠️ |

> **Read this matrix as: golden coverage gaps, not implementation gaps.** All screens are implemented and behave responsively at runtime; the `⚠️` cells indicate where a screenshot golden has not been recorded yet. Tracked under future task `P-XX` (golden coverage rollup) — out of scope for P-57.

---

## B. Cross-Link Index

| Screen | Spec md | Design png | Golden test driver |
|--------|---------|-----------|--------------------|
| Home (Buyer) | `docs/screens/02-home/01-buyer.md` (if present) | `docs/screens/designs/home_buyer_*.png` | `test/screenshots/drivers/home_buyer_screenshot_test.dart` |
| Home (Seller) | `docs/screens/02-home/02-seller.md` | — | `test/screenshots/drivers/seller_home_screenshot_test.dart` |
| Search | `docs/screens/02-home/03-search.md` | — | `test/screenshots/drivers/search_screenshot_test.dart` |
| Category Browse | `docs/screens/02-home/04-category-browse.md` | — | `test/screenshots/drivers/category_browse_screenshot_test.dart` |
| Category Detail | — | — | `test/screenshots/drivers/category_detail_desktop_screenshot_test.dart` |
| Favourites | — | — | `test/screenshots/drivers/favourites_desktop_screenshot_test.dart` |
| Listing Detail | `docs/screens/03-listings/01-listing-detail.md` | — | `test/screenshots/drivers/listing_detail_screenshot_test.dart` |
| Listing Creation | `docs/screens/03-listings/02-listing-creation.md` | — | `test/screenshots/drivers/listing_creation_screenshot_test.dart` |
| Conversation List | `docs/screens/06-chat/01-conversation-list.md` | — | (under `messages_shell_*`) |
| Chat Thread | `docs/screens/06-chat/02-chat-thread.md` | — | `test/screenshots/drivers/chat_thread_screenshot_test.dart` (skipped — #203) |
| Own Profile | — | — | `test/screenshots/drivers/own_profile_screenshot_test.dart` |
| Mollie Checkout | — | — | — |
| Transaction Detail | — | — | `test/screenshots/drivers/transaction_detail_screenshot_test.dart` |
| Shipping QR | — | — | `test/screenshots/drivers/shipping_qr_screenshot_test.dart` |

> Empty cells indicate the asset has not been recorded yet — *not* that the feature is missing.

---

## Design Generation Priority

### Phase 1 — Core Loop (must design first)
1. **Home Screen** (buyer mode) — the first thing users see ✅
2. **Listing Detail** — where trust is built or lost ✅
3. **Search** — browse and discover ✅
4. **DeelCard widget** — appears everywhere (home, search, favourites) ✅

### Phase 2 — Auth (need before real users)
5. **Onboarding** — first impression, language + value prop ✅
6. **Registration** — email + phone + OTP ✅
7. **Login** — email + biometric ✅
8. **Own Profile** — user identity ✅

### Phase 3 — Transaction Flow (end-to-end purchase)
9. **Payment Summary** — pre-checkout breakdown ✅
10. **Listing Creation** — seller's core action ✅
11. **Rating/Review** — post-transaction trust building ✅

### Phase 4 — Communication + Social
12. **Conversation List** — message center ✅
13. **Chat Thread** — buyer-seller communication ✅
14. **Seller Profile** — public reputation ✅

### Phase 5 — Settings + Polish
15. **Settings** — language, addresses, notifications ✅ (avatar pending #148)
16. **Category Browse** — enhanced discovery ✅
17. **Favourites** — saved items ✅
18. **Admin Panel** — moderation tools ⚠️ (placeholder copy; Phase B pending R-40)

---

## Design System References

When generating designs, follow these specifications:

- **Colors:** `docs/design-system/tokens.md` — primary orange #F15A24, trust green, error red
- **Typography:** Plus Jakarta Sans (Regular, Medium, SemiBold, Bold)
- **Components:** `docs/design-system/components.md` — buttons, cards, inputs, badges
- **Patterns:** `docs/design-system/patterns.md` — trust UI, escrow flow, chat, shipping
- **Accessibility:** `docs/design-system/accessibility.md` — WCAG 2.2 AA, 4.5:1 contrast, 44px touch targets
- **Breakpoints:** compact (<600px), medium (600-840px), expanded (≥840px)
- **Dark mode:** All screens must support light + dark themes (P-47, PR #157)

---

## Competitive Design References

Per the frontend launch plan, DeelMarkt targets Tier-1 design quality:

| Competitor | What to learn | What to avoid |
|-----------|--------------|---------------|
| Vinted | Clean listing cards, smooth chat | Cluttered home, weak trust signals |
| Wallapop | Location-first browse, map integration | Generic UI, no escrow visibility |
| Marktplaats | Category structure, search | Outdated design, no trust, scam reputation |
| Stripe | Payment flow clarity, trust messaging | Over-minimalism for marketplace context |
| Linear | Navigation, transitions, micro-animations | Too technical for consumer app |

---

## Maintenance

- **Refresh cadence:** every 60 days (next: 2026-06-24)
- **Enforcement:** `scripts/check_screens_inventory.dart` — pre-push hook warns at 60 d, fails at 120 d
- **Authoritative source for status:** `docs/SPRINT-PLAN.md` (PR-linked checkboxes) → cross-referenced here
- **Out of scope:** auto-generation script (`P-57a` follow-up); fixing design notes (out of pizmam-only ownership)

*See `docs/screens/` for design prompts and `docs/design-system/` for token specs.*
