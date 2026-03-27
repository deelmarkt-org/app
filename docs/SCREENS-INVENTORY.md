# DeelMarkt — Screen Inventory & Design Plan

> Complete inventory of all app screens with implementation status.
> Use this as the reference for generating designs for each screen.
> Last updated: 2026-03-26

---

## Summary

| Status | Count |
|--------|-------|
| Implemented | 5 |
| Placeholder (route exists) | 9 |
| Not started | 16 |
| **Total screens** | **30** |
| Shared widgets (non-screen) | 14 |

---

## 1. Auth / Onboarding

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 1 | **Onboarding** | P-14 | Not started | First launch: language picker + 3-page value prop carousel |
| 2 | **Registration** | P-15 | Not started | Email + phone + OTP verification + social auth |
| 3 | **Login** | P-16 | Not started | Email + biometric + social login |
| 4 | **KYC Prompt** | P-23 | Not started | Bottom sheet: Level 0→1 banner, Level 1→2 iDIN/itsme |
| 5 | **Social Login** | P-44 | Not started | Google + Apple OAuth redirect flow |

**Design notes:**
- Trust-first: show escrow protection messaging prominently
- Dutch-first: NL as default, EN toggle visible
- Biometric: Face ID / fingerprint prompt on login
- Dependencies: R-13 (Supabase Auth), R-17 (KYC state machine)

---

## 2. Home / Browse

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 6 | **Home (Buyer mode)** | P-29 | Placeholder | Categories carousel + recent listings + nearby listings |
| 7 | **Home (Seller mode)** | P-41 | Not started | Active listings + sales stats + action needed |
| 8 | **Search** | P-26 | Placeholder | FTS search bar + results grid + filter chips + sort |
| 9 | **Category Browse** | P-27 | Not started | L1 categories (horizontal) + L2 subcategories (grid) |

**Design notes:**
- Home is the primary landing screen — must feel premium, not cluttered
- Search: instant results, Dutch language FTS ("fietsen" matches "fiets")
- Category icons should match the marketplace aesthetic
- Responsive: compact (1-2 col grid), expanded (3-5 col grid)
- Dependencies: R-22 (Listings), R-23 (Categories), R-25 (FTS)

---

## 3. Listings

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 10 | **Listing Detail** | P-25 | Placeholder | Image gallery + trust banner + seller card + buy/message CTA |
| 11 | **Listing Creation** | P-24 | Not started | Photo-first: camera → form → quality score bar → publish |
| 12 | **Favourites** | P-28 | Not started | Saved listings grid with unfavourite toggle |

**Design notes:**
- Listing detail: Hero image gallery with swipe + pinch-zoom
- Trust banner: "Protected by DeelMarkt Escrow" — always visible, never dismissible
- Seller card: avatar + badges + response time + rating
- Quality score: red/amber/green bar encouraging better photos/description
- Creation flow: photo-first (camera opens immediately), then form fields
- Dependencies: R-22, R-24 (Favourites), R-26 (Quality score), R-27 (Image upload)

---

## 4. Payments / Transaction

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 13 | **Payment Summary** | (E03) | Not started | Item + platform fee + shipping + total + iDEAL button |
| 14 | **Mollie Checkout** | B-14 | **Implemented** | WebView for iDEAL payment via Mollie |
| 15 | **Transaction Detail** | B-24 | **Implemented** | Escrow timeline + amounts + action buttons |

**Design notes:**
- Payment summary: clear breakdown (item + EUR 1.50 platform fee + shipping)
- Escrow timeline: horizontal stepper (paid → shipped → delivered → confirmed → released)
- Action buttons: "Confirm Delivery" (success), "Open Dispute" (destructive)
- Trust: "Your money is safe" messaging throughout
- Dependencies: B-13–B-24 (all done)

---

## 5. Shipping

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 16 | **Shipping QR** | B-29 | **Implemented** | QR code display for seller to scan at service point |
| 17 | **Tracking Timeline** | B-30 | **Implemented** | Vertical stepper with carrier events + locations + timestamps |
| 18 | **ParcelShop Selector** | B-31 | **Implemented** | Master-detail list of PostNL/DHL service points |

**Design notes:**
- QR screen: large QR code, carrier badge, "Ship by" deadline, "Find service point" CTA
- Tracking: real-time updates, carrier logo, estimated delivery
- ParcelShop: compact (full-width list), expanded (master-detail with map placeholder)
- All 3 screens use ResponsiveBody wrapper (max 600px centered on tablet/desktop)
- Dependencies: B-25–B-28 (all done)

---

## 6. Chat / Messages

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 19 | **Conversation List** | P-35 | Placeholder | Unread badges, last message preview, listing thumbnail |
| 20 | **Chat Thread** | P-36 | Not started | Message bubbles + listing embed + structured offers |
| 21 | **Scam Alert** | P-37 | Not started | Inline warning banner on flagged messages |

**Design notes:**
- Conversation list: WhatsApp-style with listing context
- Chat thread: message bubbles (buyer blue, seller grey), embedded listing card
- Structured offers: "Make an Offer" button → offer message with accept/decline
- Scam alert: red warning banner, non-dismissible on high-confidence flags
- Real-time: Supabase Realtime for live messages
- Dependencies: R-31 (Messages table + Realtime), R-32 (Offers), R-35 (Scam detection)

---

## 7. Profile / Settings

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 22 | **Own Profile** | P-17 | Placeholder | Badges, ratings, verification progress, response time |
| 23 | **Seller Profile (public)** | P-39 | Not started | Public ratings, reviews list, trust badges |
| 24 | **Settings** | P-18 | Not started | Language, addresses, notifications, account deletion |
| 25 | **Rating/Review** | P-38 | Not started | Post-transaction: star rating + text, blind review |

**Design notes:**
- Profile: trust badges prominently displayed (email verified, phone, iDIN, etc.)
- Seller profile: average rating (hidden if < 3 reviews), reviews chronological
- Settings: grouped sections, each with save confirmation
- Rating: 1-5 stars + optional text, blind (both parties submit before reveal)
- Dependencies: R-19 (User profile), R-36 (Reviews), R-20 (GDPR deletion)

---

## 8. Admin / Moderation

| # | Screen | Task | Status | Description |
|---|--------|------|--------|-------------|
| 26 | **Admin Panel** | P-40 | Not started | Flagged content queue, disputes, DSA compliance, appeals |

**Design notes:**
- Web/desktop only (Retool or custom Flutter web)
- Queues: flagged listings, reported users, open disputes, DSA notices
- SLA dashboard: 24-hour response time tracking for DSA
- Dependencies: R-35 (Scam detection), R-37 (Dispute resolution), R-38 (DSA)

---

## Shared Widgets (used across screens)

| Widget | Task | Status | Used In |
|--------|------|--------|---------|
| DeelBadge (7 verification types) | P-19 | Not started | Profile, Listing Detail, Seller Profile |
| DeelAvatar (with badge overlay) | P-20 | Not started | Chat, Profile, Listing Detail, Search results |
| TrustBanner (escrow protection) | P-21 | Exists (`escrow_trust_banner.dart`) | Listing Detail, Transaction Detail |
| DeelCard (grid + list variants) | P-22 | Not started | Home, Search, Favourites, Category Browse |
| ImageGallery (swipe + zoom) | P-30 | Not started | Listing Detail, Listing Creation |
| PriceTag (Euro + BTW) | P-31 | Not started | DeelCard, Listing Detail, Transaction |
| LocationBadge (distance + pin) | P-32 | Not started | DeelCard, Search results |
| EscrowTimeline (horizontal stepper) | P-33 | Exists (`escrow_timeline.dart`) | Transaction Detail |
| ScamAlert (inline chat warning) | P-34 | Not started | Chat Thread |
| ShippingQrCard | B-29 | Implemented | Shipping QR Screen |
| TrackingTimeline | B-30 | Implemented | Tracking Screen |
| DutchAddressInput | B-32 | Implemented | ParcelShop Selector, Settings |
| ResponsiveBody | — | Implemented | All shipping screens |
| SkeletonLoader (shimmer) | P-07 | Implemented | All screens (loading state) |
| EmptyState | P-08 | Implemented | All screens (empty state) |
| ErrorState | P-09 | Implemented | All screens (error state) |
| LanguageSwitch | P-10 | Implemented | Settings, Onboarding |
| GdprConsentBanner | P-11 | Implemented | First launch overlay |

---

## Design Generation Priority

### Phase 1 — Core Loop (must design first)
1. **Home Screen** (buyer mode) — the first thing users see
2. **Listing Detail** — where trust is built or lost
3. **Search** — browse and discover
4. **DeelCard widget** — appears everywhere (home, search, favourites)

### Phase 2 — Auth (need before real users)
5. **Onboarding** — first impression, language + value prop
6. **Registration** — email + phone + OTP
7. **Login** — email + biometric
8. **Own Profile** — user identity

### Phase 3 — Transaction Flow (end-to-end purchase)
9. **Payment Summary** — pre-checkout breakdown
10. **Listing Creation** — seller's core action
11. **Rating/Review** — post-transaction trust building

### Phase 4 — Communication + Social
12. **Conversation List** — message center
13. **Chat Thread** — buyer-seller communication
14. **Seller Profile** — public reputation

### Phase 5 — Settings + Polish
15. **Settings** — language, addresses, notifications
16. **Category Browse** — enhanced discovery
17. **Favourites** — saved items
18. **Admin Panel** — moderation tools

---

## Design System References

When generating designs, follow these specifications:

- **Colors:** `docs/design-system/tokens.md` — primary orange #F15A24, trust green, error red
- **Typography:** Plus Jakarta Sans (Regular, Medium, SemiBold, Bold)
- **Components:** `docs/design-system/components.md` — buttons, cards, inputs, badges
- **Patterns:** `docs/design-system/patterns.md` — trust UI, escrow flow, chat, shipping
- **Accessibility:** `docs/design-system/accessibility.md` — WCAG 2.2 AA, 4.5:1 contrast, 44px touch targets
- **Breakpoints:** compact (<600px), medium (600-840px), expanded (≥840px)
- **Dark mode:** All screens must support light + dark themes

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

*This file is local only — not committed to git.*
