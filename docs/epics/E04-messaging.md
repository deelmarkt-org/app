# E04 — In-App Messaging

> **Priority:** P0 — Critical | **Phase:** 0–1 (MVP) | **Est. Duration:** 3 weeks

---

## Overview

Real-time in-app messaging between buyers and sellers via **Supabase Realtime** (PostgreSQL-backed). Keeps everything in a single platform, avoids a separate Firebase Firestore dependency. Integrates scam detection from E06. Migrates to Stream Chat SDK at ~1K MAU.

> **Architecture Decision:** ADR-15 confirms **Supabase Realtime** for Phase 1 chat, not Firebase Firestore. Supabase Realtime provides WebSocket subscriptions over PostgreSQL — sufficient for MVP load, with no additional service dependency.

**Chat tech stack lineage:**
- **Phase 0–1 (MVP):** Supabase Realtime (PostgreSQL subscriptions)
- **Phase 2 (~1K MAU):** Stream Chat Flutter SDK (pre-built UI, offline, SLA 99.999%)

---

## User Stories

### Phase 0–1 (MVP)
- As a buyer, I can message a seller directly from a listing
- As a buyer, I can make a structured offer via "Make an Offer" button
- As a user, I see the listing card embedded at the top of every conversation
- As a user, I see seller response times ("Usually responds within 1 hour")
- As a user, I receive push notifications for new messages
- As a user, messages with suspicious links/phone numbers are flagged in real-time (via E06)

### Phase 2 Additions
- As a user, I can read messages in my chosen language (auto-translation via Stream Chat or DeepL)
- As a user, I can share my location in-chat to coordinate a meetup handoff
- As a user, conversation history is available offline (Stream Chat offline support)

---

## Technical Scope

### Supabase Realtime Messaging (2 weeks)
- PostgreSQL `messages` table with Supabase Realtime subscriptions (WebSocket)
- Conversation threads linked to listings
- Structured "Make an Offer" message type with price field
- Listing card embed at conversation top
- Push notifications via FCM on new messages (Edge Function trigger)
- Unread message count badge

### Seller Response Time (0.5 week)
- Calculate median response time from message timestamps (median chosen over mean for robustness against outliers — holidays, long absences)
- Store as computed field on user profile (updated daily via cron/Edge Function)
- Display on seller profile and conversation header

### Scam Detection Integration (0.5 week)
- Call E06 scam detection API on each outgoing message
- Flag messages containing external links, phone numbers, off-platform payment requests
- Display warning banner to recipient on flagged messages

---

## Phase 2 — Stream Chat Migration (at ~1K MAU)

> **Trigger:** When Supabase Realtime connection limits or missing features (offline, rich UI) become friction

- Stream Chat Flutter SDK integration
- Pre-built UI components; offline support via local cache
- **Auto-translation:** Stream Chat supports DeepL integration — enable for NL↔EN minimum; add DE/FR when Phase 3 language support is added
- **In-app location sharing:** Structured message type — user taps "Share meetup location" → map pin sent as a message; recipient taps to open in Maps app. Reduces off-platform friction for local handoff deals.
- Maintain listing card embed and scam detection hook (E06 API remains unchanged)

---

## Acceptance Criteria

- [ ] Real-time messaging works on iOS and Android (Supabase Realtime WebSocket)
- [ ] Listing card displayed at top of each conversation
- [ ] "Make an Offer" structured message works
- [ ] Push notifications delivered for new messages
- [ ] Suspicious messages flagged with warning (via E06 integration)
- [ ] Seller response time displayed on profile
- [ ] Unread message count shown
- [ ] ≥70% test coverage

---

## Dependencies

- **E02** (User Auth) — users must be authenticated (Level 1+)
- **E01** (Listings) — conversations linked to listings
- **E06** (Trust) — scam detection engine (can develop in parallel, integrate later)
- **E07** (Infrastructure) — Supabase project, Firebase FCM
