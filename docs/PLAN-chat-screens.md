# 📋 PLAN — Chat Screens (P-35 + P-36)

> **Status:** ✅ **COMPLETED** — shipped via [PR #71](https://github.com/deelmarkt-org/app/pull/71). Both `P-35` and `P-36` are ticked `[x]` in `docs/SPRINT-PLAN.md`.
> _Doc preserved for historical reference. Acceptance items below were satisfied at merge time; PR review + CI is the source of truth._
>
> **Owner:** pizmam (Frontend/Design) · **Epic:** [E04 — Messaging](epics/E04-messaging.md) · **Secondary:** [E06 — Trust/Moderation](epics/E06-trust-moderation.md)
> **Branch:** `feature/pizmam-E04-chat-screens` (branch from `origin/dev`)
> **Sprint tasks:** `P-35` Chat conversation list · `P-36` Chat thread screen
> **Plan version:** 1.1 · **Date:** 2026-04-04
> **Classification:** Medium–Large (10–14 files, presentation-layer only, mock-backed, responsive + dark mode)
> **Workflow:** `.agent/workflows/plan.md` v2.2.0 · quality-gate principles applied
> **Authority:** All open questions resolved via Senior Staff Engineer decision — see §13 Decisions Log

---

## 1. Scope

### In scope
1. **P-35 — Conversation list screen** (`/messages` tab) — per `docs/screens/06-chat/01-conversation-list.md` + `designs/messages_mobile_{light,dark}`, `messages_empty_state`, `messages_loading_state`, `messages_desktop_expanded`:
   - Editorial header: "Berichten" (display 32px bold) + subtitle "Beheer je gesprekken en biedingen".
   - Conversation row: 64px avatar with online/offline dot, bold name (extra-bold if unread), last-message preview (primary-orange + bold if unread, neutral-700 if read), listing title chip, 48px listing thumbnail (xl radius), orange unread-count badge, relative timestamp ("14:32", "Gisteren", "Maandag", "Vrijdag"), ring-hover affordance.
   - Offer preview row: last message rendered as "Bod: € 120,00" when `lastMessageType == offer`.
   - Four states: **data**, **empty** (illustration + "Nog geen berichten" + CTA → Ontdekken), **loading** (shimmer skeleton rows ×5), **error**.
   - Tap → navigate to thread (push on compact, swap right pane on expanded).
2. **P-36 — Chat thread screen** (`/messages/:conversationId`) — per `docs/screens/06-chat/02-chat-thread.md` + `designs/chat_thread_mobile_{light,dark_scam_alert}`, `chat_thread_desktop_expanded`:
   - App bar: back arrow, 32px avatar + online dot, name, "Online" text, options (⋯) menu stub.
   - Collapsible listing context card (subtle surface bg): 40px thumbnail + title + price "€ 149,00" + status chip "Te koop".
   - Message thread: day separators ("Vandaag"/"Gisteren"/weekday), buyer = self (right, primary-surface #FFF3EE bubble), seller = other (left, neutral-100 bubble), timestamps below each bubble, ✓✓ read receipts on self messages.
   - Structured offer card: "Bod: € 120,00" + Accepteren (success green) + Afwijzen (outlined) + Tegenbod (text btn). CTAs fully rendered per design; `onPressed` shows "Binnenkort beschikbaar" SnackBar (§13 Decision Q3).
   - Input bar (sticky bottom): camera icon, text field "Typ een bericht…", "Bod" chip, orange send arrow. Send wires into `MockMessageRepository.sendMessage` via notifier with optimistic append.
   - Scam-alert banner: **visual reservation only** — leave a placeholder `SizedBox.shrink()` + TODO comment pointing to P-37. No banner rendering in this sprint.
3. **Responsive layout** (§13 Decision Q5): single `LayoutBuilder` at `/messages` route level.
   - Compact (< `breakpoints.tablet`): push navigation (list → thread).
   - Expanded (≥ `breakpoints.tablet`): master-detail — list fixed 360px left pane, thread in right pane; deep link `/messages/:id` highlights row + shows thread on right simultaneously.
4. **Dark mode** (§13 Decision Q4): both light + dark shipped. All colors via `DeelmarktColors.*` — zero hardcoded values.
5. **Presentation-layer wiring**: Riverpod 2.6.1 notifiers (§13 Decision Q2) via `riverpod_annotation` code-gen, providers, navigation, l10n (NL + EN under `messages.*` and `chat.*` namespaces per design spec), a11y semantics.
6. **Tests**: widget tests for all four states × both screens × both brightness modes; ViewModel unit tests; use-case unit tests; responsive breakpoint widget test.

### Out of scope (explicitly deferred)
| Item | Deferred to |
|:-----|:------------|
| Supabase Realtime wiring, `messages` table, RLS | `[R]` backend tasks (reso) — E04 §Technical Scope |
| Scam alert banner UI + detection integration | `P-37` (separate sprint item) |
| Push notifications (FCM) for new messages | `[R]` tasks under E04 |
| "Make an Offer" creation flow (counter-offer logic) | `P-36.1` (future) — only the *display* of received offer bubbles is in scope |
| Seller response-time *computation* (daily cron) | `[R]` — we only render the value already present on the entity |
| Typing indicators, read receipts, attachments | Phase 2 (Stream Chat migration) |
| Dark-mode tokens beyond what theme already provides | N/A — we reuse `DeelmarktColors` |

---

## 2. Current State (on `origin/dev`)

### Already present ✅
```
lib/features/messages/
├── domain/
│   ├── entities/
│   │   ├── conversation_entity.dart    ← Equatable, copyWith, no Flutter deps
│   │   └── message_entity.dart         ← incl. enum MessageType { text, offer, systemAlert, scamWarning }
│   └── repositories/
│       └── message_repository.dart     ← interface: getConversations, getMessages, sendMessage
└── data/mock/
    └── mock_message_repository.dart    ← 300ms/200ms/100ms simulated latency, static fixtures
```
- `lib/core/router/routes.dart` has `AppRoutes.messages = '/messages'`
- Dependencies present: `flutter_riverpod`, `go_router`, `easy_localization`, `phosphor_flutter`, `shimmer`, `equatable`

### Missing (this plan delivers) ❌
- `lib/features/messages/presentation/` — only `.gitkeep`
- `messages` l10n namespace in `assets/l10n/en-US.json` + `nl-NL.json`
- Route entry for `/messages/:conversationId` in `app_router.dart` (route constant does not yet exist)
- `use_cases/` — domain layer has no use cases yet (we will add `GetConversationsUseCase`, `GetMessagesUseCase`, `SendMessageUseCase` to keep ViewModels thin per CLAUDE.md §1.1)
- Widget tests for the `messages` feature
- Current stoic-satoshi worktree is stale vs dev — must rebase first

---

## 3. Architecture — Clean Architecture Layer Map

```
┌────────────── presentation/ ───────────────────────────────────────┐
│ screens/                                                          │
│   conversation_list_screen.dart       ← P-35                      │
│   chat_thread_screen.dart             ← P-36                      │
│ widgets/                                                           │
│   conversation_list_tile.dart         ← row for P-35              │
│   chat_listing_card.dart              ← pinned listing embed      │
│   message_bubble.dart                 ← text bubble (self/other)  │
│   offer_message_bubble.dart           ← structured offer bubble   │
│   chat_message_composer.dart          ← input + send button       │
│   chat_header.dart                    ← sticky thread header      │
│ notifiers/                                                         │
│   conversation_list_notifier.dart     ← AsyncNotifier<List<...>>  │
│   chat_thread_notifier.dart           ← AsyncNotifier<ThreadState>│
│ providers.dart                         ← DI wiring                │
└────────────────────────────────────────────────────────────────────┘
                          │ uses
                          ▼
┌────────────── domain/ (pure Dart) ─────────────────────────────────┐
│ entities/  conversation_entity.dart ✅  message_entity.dart ✅     │
│ repositories/  message_repository.dart ✅                          │
│ usecases/                                                          │
│   get_conversations_usecase.dart      ← NEW                       │
│   get_messages_usecase.dart           ← NEW                       │
│   send_message_usecase.dart           ← NEW                       │
└────────────────────────────────────────────────────────────────────┘
                          │ implements
                          ▼
┌────────────── data/ ───────────────────────────────────────────────┐
│ mock/mock_message_repository.dart ✅ (reused as-is)                │
└────────────────────────────────────────────────────────────────────┘
```

**Rationale for use cases** (per CLAUDE.md §1.1 & §2.1 line limits):
- ViewModels must stay < 150 lines. Without use cases, notifier would also handle DTO validation, error translation, and sorting. Use cases absorb this → notifier becomes a thin orchestrator (state transitions only).
- Matches the pattern already established in `lib/features/home/domain/usecases/` on dev (ref memory).

---

## 4. Design Reference

### Primary source — screen specs (canonical)
| Spec | File |
|:-----|:-----|
| Conversation list | `docs/screens/06-chat/01-conversation-list.md` |
| Chat thread | `docs/screens/06-chat/02-chat-thread.md` |
| Scam alert (P-37, reference only) | `docs/screens/06-chat/03-scam-alert.md` |
| Design system preamble | `docs/screens/DESIGN-SYSTEM-PREAMBLE.md` |

### Primary source — visual mockups (`docs/screens/06-chat/designs/`)
| Mockup | Purpose |
|:-------|:--------|
| `messages_mobile_light/{code.html,screen.png}` | P-35 reference — light theme |
| `messages_mobile_dark/{code.html,screen.png}` | P-35 reference — dark theme |
| `messages_empty_state/` | P-35 empty state |
| `messages_loading_state/` | P-35 loading skeleton |
| `messages_desktop_expanded/` | P-35 responsive expanded (360px master + detail) |
| `chat_thread_mobile_light/` | P-36 reference — light theme |
| `chat_thread_mobile_dark_scam_alert/` | P-36 reference — dark theme (ignore scam banner) |
| `chat_thread_desktop_expanded/` | P-36 responsive expanded |

### Secondary sources (design tokens)
- `docs/design-system/tokens.md` — colors, typography, spacing, radius, elevation
- `docs/design-system/components.md` — button, badge, card, input primitives
- `docs/design-system/patterns.md` §Chat Thread + §Structured Offer Message — reinforces screen specs
- `docs/design-system/accessibility.md` — 44×44 touch targets, Semantics labels, focus order

### Key design tokens extracted (from DESIGN-SYSTEM-PREAMBLE.md)
- **Self bubble bg** → `DeelmarktColors.primarySurface` (#FFF3EE)
- **Other bubble bg** → `DeelmarktColors.neutral100` (#F3F4F6)
- **Self bubble text** → `DeelmarktColors.neutral900`
- **Online dot** → `DeelmarktColors.success` (#2EAD4A)
- **Offline dot** → `DeelmarktColors.neutral300`
- **Unread badge bg** → `DeelmarktColors.primary` (#F15A24)
- **Unread badge text** → `DeelmarktColors.white`
- **Unread preview text** → `DeelmarktColors.primary` + `FontWeight.w700`
- **Read receipt ✓✓** → `DeelmarktColors.trustEscrow` (#2563EB)
- **Bubble radius** → `DeelmarktRadius.xl` (16px)
- **Listing thumbnail radius** → `DeelmarktRadius.lg` (12px)
- **Conversation row padding** → `Spacing.s5` (20px)
- **Day separator** → `Typography.bodySm` + `neutral500`, centered

### Wireframe recap (from screen specs)
```
Conversation list row (64px avatar)                    Chat thread (compact)
┌────────────────────────────────┐                     ┌────────────────────────────┐
│  ⭕ Jan de Vries     14:32  ①  │                     │ ← ⭕ Jan de Vries ⋯        │
│  ╱●╲ Is de fiets …  🖼 Gazelle │                     │    • Online                │
└────────────────────────────────┘                     ├────────────────────────────┤
                                                       │ ╭─ 🖼 Canyon Speedmax ───╮ │
Empty state                                            │ │    € 149,00 · Te koop  │ │
┌────────────────────────────────┐                     │ ╰────────────────────────╯ │
│     (illustration)             │                     ├────────────────────────────┤
│  Nog geen berichten            │                     │         — Vandaag —        │
│  Start een gesprek door een    │                     │ ╭ Hoi! Nog beschikbaar? ╮  │← other
│  advertentie te bekijken       │                     │ ╰ 14:30                 ╯  │
│  [ Naar Ontdekken → ]          │                     │  ╭ Ja, wanneer langskmn╮   │← self
└────────────────────────────────┘                     │  ╰ 14:32 ✓✓            ╯   │
                                                       │ ┌─ Bod: € 120,00 ──────┐   │
                                                       │ │ [Accept] [Decline]   │   │
                                                       │ └──────────────────────┘   │
                                                       ├────────────────────────────┤
                                                       │ 📷 [Typ een bericht…] Bod ➤│
                                                       └────────────────────────────┘

Expanded layout (≥ breakpoints.tablet, 768px+)
┌─────────────── 360px ─────────┬──────────────────────────────┐
│ Berichten                     │ ← Jan de Vries  • Online   ⋯ │
│ ● Jan de Vries      14:32  ①  │ ╭ 🖼 Canyon Speedmax €149 ╮ │
│   Lisa Bakker       Gisteren  │ ╰────────────────────────╯   │
│   Mark Sanders      Maandag   │      — Vandaag —             │
│   Sophie de Jong    Vrijdag ① │  (thread here)               │
│                               │ 📷 [Typ…]  ➤                │
└───────────────────────────────┴──────────────────────────────┘
```

---

## 5. Implementation Tasks

> Each task has **exact file paths** and **done criteria** (per `plan.md` §Critical Rules 4, 6).
> All tasks obey CLAUDE.md §2.1 file line limits and §3.3 no-hardcoded-values.

### Phase 0 — Preflight (must complete first)
- [ ] **T0.1** `git fetch origin && git rebase origin/dev` — sync worktree against dev (memory rule: `feedback_sync_before_work.md`).
      **Verify:** `git log origin/dev..HEAD` shows only new chat-screen commits; `flutter analyze` passes with zero warnings on baseline.
- [ ] **T0.2** `flutter test` baseline — record current pass count before writing any code.
      **Verify:** all existing tests green.
- [ ] **T0.3** Create branch `feature/pizmam-E04-chat-screens` from `origin/dev`.
      **Verify:** `git branch --show-current` returns the branch name.
- [ ] **T0.4** Audit `lib/core/design_system/colors.dart` for chat-specific tokens (self/other bubble bg pairs for light + dark, read-receipt blue, online/offline dots). If any are missing, open a tiny preceding commit `chore(design-system): add chat bubble tokens` (≤ 20 lines changed) before any presentation work begins.
      **Verify:** all tokens referenced in §4 "Key design tokens extracted" resolve at compile time in `message_bubble.dart`. No `Color(0x…)` literals anywhere in `lib/features/messages/`.

### Phase 1 — Domain use cases (TDD, RED first)
- [ ] **T1.1** Write failing test: `test/features/messages/domain/usecases/get_conversations_usecase_test.dart`
      → asserts use case sorts conversations by `lastMessageAt` desc and returns repository result.
      **Verify:** `flutter test` reports the new test FAILS (compilation error — use case not yet present).
- [ ] **T1.2** Create `lib/features/messages/domain/usecases/get_conversations_usecase.dart` (≤ 50 lines per CLAUDE.md §2.1).
      Single public `call()` method. No Flutter imports.
      **Verify:** T1.1 test passes; `flutter analyze` clean; file line count ≤ 50.
- [ ] **T1.3** Repeat T1.1/T1.2 for `get_messages_usecase.dart` (returns messages ordered by `createdAt` asc for chronological thread display).
      **Verify:** unit test covers ordering + empty conversation case.
- [ ] **T1.4** Repeat T1.1/T1.2 for `send_message_usecase.dart` (validates non-empty trimmed text; throws `ArgumentError` on empty).
      **Verify:** unit test covers happy path + empty-text rejection.

### Phase 2 — Providers & Notifiers
- [ ] **T2.1** Create `lib/features/messages/presentation/providers.dart` with Riverpod provider DI:
      `messageRepositoryProvider` → `MockMessageRepository` (swappable later for Supabase impl);
      use-case providers read repository.
      **Verify:** file ≤ 100 lines; all three use cases wired; `flutter analyze` clean.
- [ ] **T2.2** Write test: `test/features/messages/presentation/conversation_list_notifier_test.dart`
      → verifies state transitions `loading → data`, `loading → error`, and `refresh()`.
      Use `ProviderContainer` + override use cases with fakes.
      **Verify:** test fails (notifier missing).
- [ ] **T2.3** Create `lib/features/messages/presentation/conversation_list_notifier.dart` — `AsyncNotifier<List<ConversationEntity>>`, ≤ 150 lines. Methods: `build()`, `refresh()`.
      **Verify:** T2.2 passes; line count ≤ 150.
- [ ] **T2.4** Write test: `test/features/messages/presentation/chat_thread_notifier_test.dart`
      → verifies initial load, `sendMessage()` appends optimistically, and rollback on repository failure.
      **Verify:** test fails.
- [ ] **T2.5** Create `lib/features/messages/presentation/chat_thread_notifier.dart` — `AsyncNotifier<ChatThreadState>` where `ChatThreadState` is an Equatable state class containing `messages`, `conversation`, `isSending`. ≤ 150 lines.
      **Verify:** T2.4 passes; line count ≤ 150; immutable state updates only (CLAUDE.md + user's `coding-style.md` rule).

### Phase 3 — Shared chat widgets
- [ ] **T3.1** `lib/features/messages/presentation/widgets/conversation_list_tile.dart` — 64px avatar + online/offline dot, name (extra-bold if unread), last-message preview (primary orange + bold if unread else neutral-700), listing chip, 48px thumbnail, orange unread count badge, relative timestamp. Responds to `lastMessageType == offer` → renders "Bod: {amount}" preview via `chat.offerPreview` key. Uses `DeelmarktColors`, `Spacing`, phosphor icons. ≤ 180 lines.
      **Verify:** widget tests cover unread vs read states, online vs offline dot, offer-preview formatting, touch target ≥ 44×44, Semantics label in NL + EN, renders correctly in both light + dark themes.
- [ ] **T3.2** `lib/features/messages/presentation/widgets/chat_listing_embed_card.dart` — collapsible pinned listing card per design spec. Shows 40px thumbnail (lg radius), title, price ("€ 149,00" tabular), status chip ("Te koop"). ≤ 120 lines.
      **Verify:** widget test renders all elements in both themes; collapses on scroll; Semantics label in NL + EN.
- [ ] **T3.3** `lib/features/messages/presentation/widgets/message_bubble.dart` — text bubble. Props: `MessageEntity message`, `bool isSelf`, `bool showTimestamp`, `bool showReadReceipt`. Self → right-aligned, `primarySurface` bg (#FFF3EE light / dark equivalent), `neutral900` text. Other → left-aligned, `neutral100` bg (light) / `neutral800` (dark). Radius: `xl` (16px), with asymmetric tail corner (3px on bubble tail side). Read receipt ✓✓ in `trustEscrow` blue under self bubbles. Max bubble width = 75% of viewport. ≤ 120 lines.
      **Verify:** widget tests for self vs other, timestamp rendering, read receipt visibility, max-width clamp, both themes.
- [ ] **T3.4** `lib/features/messages/presentation/widgets/offer_message_card.dart` — structured offer card per design spec. Renders "Bod: € X,XX" (price-sm typography) + two primary CTAs (Accepteren = success green filled / Afwijzen = outlined) + tertiary text button (Tegenbod / Counter offer). **CTAs visually complete per design** (§13 Decision Q3): `onPressed` shows localized "Binnenkort beschikbaar" SnackBar via `ScaffoldMessenger`. Also renders accepted/declined status chip when `offerStatus` populated. ≤ 140 lines.
      **Verify:** widget test — renders default/accepted/declined states; all three CTAs tappable with ≥ 44×44 touch target; SnackBar fires on tap; a11y labels in NL + EN; both themes; no accidental wiring into transaction module.
- [ ] **T3.5** `lib/features/messages/presentation/widgets/chat_message_composer.dart` — sticky bottom composer. Camera icon (leading, stub onPressed → SnackBar "Binnenkort beschikbaar"), multi-line text field (`chat.typeMessage` placeholder, max 4 visible lines before scroll), "Bod" chip (stub), orange circular send arrow button. Send disabled when trimmed input empty or notifier `isSending`. Respects safe area + keyboard inset. ≤ 120 lines.
      **Verify:** widget test — send callback fires with trimmed text; disabled-state transitions; keyboard inset respected; a11y labels in NL + EN; both themes.
- [ ] **T3.6** `lib/features/messages/presentation/widgets/chat_header.dart` — sticky app bar. Back arrow, 32px avatar with online dot, name, "Online"/"Laatst gezien" subtitle, options (⋯) menu stub button. Respects safe area. ≤ 100 lines.
      **Verify:** widget test — back button pops route or swaps right pane on expanded; options menu opens a bottom sheet stub with "Binnenkort beschikbaar"; a11y labels; both themes.
- [ ] **T3.7** `lib/features/messages/presentation/widgets/chat_day_separator.dart` — centered "Vandaag" / "Gisteren" / weekday-name / "dd MMM yyyy" based on locale + relative distance. ≤ 80 lines. Pure function extracted to `core/utils/chat_date_formatter.dart` (≤ 60 lines) so it can be unit-tested without Flutter.
      **Verify:** `chat_date_formatter_test.dart` unit tests cover today/yesterday/this-week/older for `nl_NL` and `en_US`; DST boundary test with fixed `Clock`.
- [ ] **T3.8** `lib/features/messages/presentation/widgets/conversation_list_skeleton.dart` — `shimmer` package wrapper rendering 5 placeholder rows matching `ConversationListTile` geometry. ≤ 80 lines.
      **Verify:** widget test — renders 5 rows; respects dark mode colors; respects `MediaQuery.disableAnimations`.
- [ ] **T3.9** `lib/features/messages/presentation/widgets/conversation_list_empty_state.dart` — per design spec: illustration slot (reuse existing illustration widget if available, else `Icon` placeholder), "Nog geen berichten" heading, subtitle "Start een gesprek door een advertentie te bekijken", primary CTA "Naar Ontdekken" → navigates to `/` (home). ≤ 100 lines.
      **Verify:** widget test — CTA navigates home; both themes; Semantics label.

### Phase 4 — Screens & Responsive Layout
- [ ] **T4.1** `lib/features/messages/presentation/screens/conversation_list_screen.dart` (P-35) — ≤ 200 lines. `ConsumerWidget`, reads `conversationListNotifierProvider`. Editorial header ("Berichten" display-32 + subtitle body-lg). Body switches on `AsyncValue`:
      - `loading` → `ConversationListSkeleton`
      - `error` → centered error state with retry
      - `data.isEmpty` → `ConversationListEmptyState`
      - `data` → `ListView.separated` of `ConversationListTile` + `Spacing.s3` separators + `RefreshIndicator`
      Does NOT include its own `Scaffold` — parent responsive shell owns the Scaffold.
      **Verify:** widget tests for all four states × both themes; pull-to-refresh triggers `notifier.refresh()`; line count ≤ 200.
- [ ] **T4.2** `lib/features/messages/presentation/screens/chat_thread_screen.dart` (P-36) — ≤ 200 lines. `ConsumerStatefulWidget` (needs `ScrollController` for auto-scroll). Reads `chatThreadNotifierProvider(conversationId)`. Composition: `ChatHeader` (showBackButton conditional on compact vs expanded) + pinned `ChatListingEmbedCard` + `Expanded(ListView.builder)` of grouped bubbles with `ChatDaySeparator` at group boundaries + sticky `ChatMessageComposer`. Auto-scroll to bottom on new message via `addPostFrameCallback`. Respects `MediaQuery.disableAnimations` (jump instead of animate). Reserves scam-alert slot as `SizedBox.shrink()` with TODO comment pointing to P-37.
      **Verify:** widget tests for all four states × both themes; sending a message calls notifier and clears input; auto-scroll fires; scam-alert slot present but empty; line count ≤ 200.
- [ ] **T4.3** `lib/features/messages/presentation/screens/messages_responsive_shell.dart` (≤ 160 lines) — **single entry point for `/messages` and `/messages/:conversationId`**. `LayoutBuilder` switches at `breakpoints.tablet`:
      - **Compact**: renders `ConversationListScreen` OR `ChatThreadScreen` (based on route param presence). Navigation uses `context.go('/messages/$id')` which pushes a new route.
      - **Expanded**: side-by-side — left pane (360px fixed) = `ConversationListScreen` with selection highlight; right pane (flex) = `ChatThreadScreen` when conversationId present, else an empty-thread placeholder "Selecteer een gesprek om te beginnen". Row selection updates URL via `context.go` without pushing.
      The shell owns the `Scaffold` so inner screens remain composition units.
      **Verify:** widget test at 375px width shows only list OR only thread; at 1024px shows both with selected row highlighted; deep-link `/messages/conv-001` at expanded width opens both panes; URL sync works in both directions.
- [ ] **T4.4** Create shared `lib/features/messages/presentation/widgets/_no_thread_selected.dart` (≤ 60 lines) — empty placeholder for expanded layout right pane when no conversation selected.
      **Verify:** widget test renders in both themes.

### Phase 5 — Routing & Navigation
- [ ] **T5.1** Add `static const chatThread = '/messages/:conversationId';` + helper `static String chatThreadFor(String id) => '/messages/$id';` to `lib/core/router/routes.dart`.
      **Verify:** constant present, helper returns correct path, referenced nowhere as magic string (grep check).
- [ ] **T5.2** Wire `/messages` **and** `/messages/:conversationId` → `MessagesResponsiveShell` inside `lib/core/router/app_router.dart` — both routes resolve to the shell, which internally reads `state.pathParameters['conversationId']`. The nested route is **not** a separate screen; that's key to the responsive design.
      **Verify:** `flutter test test/core/router/` passes; compact navigation pushes on tap; expanded navigation updates URL without push; deep link `/messages/conv-001` survives cold start on both widths.
- [ ] **T5.3** Add `ValueKey(conversationId)` on `ChatThreadScreen` usage so switching conversations in expanded mode disposes the previous notifier (prevents state bleed).
      **Verify:** widget test — switching from conv-001 to conv-002 in expanded mode loads conv-002's messages, not conv-001's.

### Phase 6 — Localisation
- [ ] **T6.1** Add `messages` namespace to `assets/l10n/en-US.json` + `nl-NL.json` (for P-35 per screen spec):
      `messages.title` ("Berichten" / "Messages"), `messages.subtitle` ("Beheer je gesprekken en biedingen" / "Manage your conversations and offers"), `messages.noConversations`, `messages.startConversation`, `messages.emptyAction` ("Naar Ontdekken" / "Go to Discover"), `messages.errorTitle`, `messages.errorRetry`, `messages.yesterday`, `messages.offerPreview` ("Bod: {amount}" / "Offer: {amount}"), `messages.unreadA11y` ("{count} ongelezen" / "{count} unread"), `messages.onlineA11y`, `messages.offlineA11y`, `messages.noThreadSelected`.
- [ ] **T6.2** Add `chat` namespace to both locales (for P-36 per screen spec):
      `chat.typeMessage`, `chat.makeOffer`, `chat.offer`, `chat.offerOf` ("Bod van {amount}" / "Offer of {amount}"), `chat.accept`, `chat.decline`, `chat.counter` ("Tegenbod" / "Counter offer"), `chat.accepted`, `chat.declined`, `chat.online`, `chat.lastSeen`, `chat.today`, `chat.yesterday`, `chat.comingSoon` ("Binnenkort beschikbaar" / "Coming soon"), `chat.sendA11y`, `chat.backA11y`, `chat.cameraA11y`, `chat.optionsMenuA11y`, `chat.listingEmbedA11y`, `chat.selfBubbleA11y`, `chat.otherBubbleA11y`, `chat.readReceiptA11y`.
- [ ] **T6.3** Verify locale parity — both namespaces present in both JSON files with identical key sets.
      **Verify:** `flutter test test/core/l10n/locale_parity_test.dart` passes (create if missing, ≤ 60 lines); zero hardcoded strings in `lib/features/messages/` (grep `"'[A-Z][a-z]"` = 0 matches outside comments/imports); `dart format` clean.

### Phase 7 — Accessibility pass
- [ ] **T7.1** Every interactive widget has a `Semantics(label: tr('messages.a11y_...'))`. Touch targets ≥ 44×44. Focus order matches visual order. Reduced-motion respected in auto-scroll.
      **Verify:** manual audit checklist in PR description; existing a11y test helpers (if any) invoked.

### Phase 8 — Documentation
- [ ] **T8.1** Update `docs/SPRINT-PLAN.md` — tick `P-35` and `P-36` on merge (per memory `feedback_sprint_plan_auto_update.md`).
      **Verify:** checkbox diff present in merge commit.
- [ ] **T8.2** Add a short "Chat screens (P-35/P-36)" entry to epic `docs/epics/E04-messaging.md` acceptance criteria checklist.
      **Verify:** unchecked boxes converted to checked where applicable.

---

## 6. Verification Matrix (Done = all green)

| Gate | Command | Pass criteria |
|:-----|:--------|:--------------|
| Format | `dart format --set-exit-if-changed .` | exit 0 |
| Analyzer | `flutter analyze --no-pub` | zero warnings, zero infos |
| Unit + widget tests | `flutter test --no-pub` | all pass; messages feature coverage ≥ 70% |
| Line limits | `find lib/features/messages -name "*.dart" \| xargs wc -l` | no file exceeds CLAUDE.md §2.1 limits |
| Hardcoded strings | `grep -rn "'[A-Z]" lib/features/messages/presentation` | only keys, no UI copy |
| Hardcoded colors | `grep -rn "Color(0x" lib/features/messages` | zero matches |
| Secrets | `detect-secrets scan` | no new findings |
| Touch targets | manual a11y review in PR | ≥ 44×44 on all interactive elements |

---

## 7. Cross-Cutting Concerns (mandatory per plan.md §3)

### 7.1 Security (`security-reviewer` perspective)
- **Input sanitisation:** message text trimmed but **not** HTML-stripped at presentation — renderers use plain `Text`, never `Html`/`RichText.html`. No XSS surface.
- **No secrets:** mock repository contains fixture strings only. No API keys, tokens, or PII in source.
- **Authorization:** presentation layer does not check auth — that is `auth_guard.dart`'s job; the notifier assumes an authenticated session. Document this assumption.
- **Offer buttons are disabled stubs:** they must NOT call any payment or transaction API. Add explicit `// SECURITY: stub only — P-36 scope is UI` comments.
- **Deep link:** `/messages/:conversationId` must validate conversationId format before querying; malformed ID → error state, not crash.
- **PII in logs:** notifiers must not `debugPrint` message bodies or user names.

### 7.2 Testing (`tdd-guide` perspective)
- **TDD enforced** — every phase above writes tests first, verified RED, then GREEN.
- **Coverage target:** ≥ 70% lines for `lib/features/messages/` (CLAUDE.md §6.1). Spot-target for widgets ≥ 80%.
- **Mandatory states per CLAUDE.md §6.1:** loading, error, empty, data — tested for both screens.
- **Mocking:** override use cases at `ProviderContainer` level; never mock the repository layer from widget tests.
- **Golden tests:** optional. If added, use `matchesGoldenFile` for `ConversationListTile` in light + dark theme.
- **No flaky tests:** any use of `pumpAndSettle` bounded by 2s timeout.

### 7.3 Documentation
- `docs/PLAN-chat-screens.md` (this file).
- Dartdoc `///` on every public class, provider, use case.
- Update `SPRINT-PLAN.md` and `E04-messaging.md` on merge (T8.1, T8.2).
- PR body uses sprint-plan link template.

### 7.4 Observability
- Add `debugPrint` only via the project logger if one exists; otherwise leave empty. No `print()` calls (flutter_lints blocks this anyway).
- Future telemetry hooks noted as TODO but **not** implemented now.

---

## 8. Risks & Mitigations

| # | Risk | Likelihood | Impact | Mitigation |
|:--|:-----|:-----------|:-------|:-----------|
| R1 | `MockMessageRepository.sendMessage` does not append to its internal list → optimistic UI needs notifier to synthesise the new message locally | Medium | Low | Notifier builds the full list client-side by concatenating its own state with the new `MessageEntity` returned from the repo. Documented in T2.5. |
| R2 | Dark-mode chat colors not explicitly defined in current `DeelmarktColors` (bubble bg pairs, etc.) | Medium | Medium | Audit `DeelmarktColors` in T0.4 before Phase 3. If missing, add dark counterparts in a preceding commit (`chore(design-system): add chat bubble tokens`) — minimal surface, reviewed by architect. |
| R3 | Scam-alert slot misread by reviewer as "in scope" | Medium | Low | Explicitly add a `// P-37 SCOPE BOUNDARY` comment at the slot; link the sprint task in PR description; include a "Not in scope" section in PR body. |
| R4 | Stoic-satoshi worktree stale vs dev | High | High | T0.1 rebase is blocking Phase 0. No implementation starts until dev is synced. |
| R5 | Offer bubble CTAs may be tapped by real users in staging builds and create support noise | Medium | Low | SnackBar shows localized "Binnenkort beschikbaar" message; also emit a tracked analytics intent event so PM can measure demand before P-36.1. |
| R6 | Responsive master-detail layout increases PR size significantly | Medium | Medium | Clean `LayoutBuilder` abstraction in T4.3 keeps branching isolated to shell. Compact-mode tests remain independent. If PR grows > 1500 lines of diff, split T4.3 to a followup PR — accept the added risk. |
| R7 | `ValueKey(conversationId)` on expanded-mode thread switch — wrong key strategy leaks state between conversations | Medium | Medium | Explicit test T5.3 covers this edge case; code review checklist item. |
| R8 | Riverpod 2→3 migration implied by CLAUDE.md may be expected | Low | Low | §13 Decision Q2 explicitly descopes this; raise followup chore ticket immediately after PR merge so roadmap is clear. |
| R9 | `easy_localization` key parity regression on merge conflict | Low | Medium | T6.3 parity test catches this at test time; CI fails loudly before merge. |

---

## 9. Agent Assignments (Medium-task specialist synthesis)

| Phase | Agent | Purpose |
|:------|:------|:--------|
| §3 Architecture review | `architect` (already applied in this plan) | Layer boundary validation |
| Phase 1–2 TDD loop | `tdd-guide` | RED-GREEN enforcement, coverage audit |
| Phase 3–4 widget build | self (pizmam) | Design-system fidelity |
| Pre-PR | `code-reviewer` | Readability, immutability, file size |
| Pre-PR | `security-reviewer` | Input validation, PII, deep-link validation |
| Optional pre-PR | `refactor-cleaner` | Remove any dead code before commit |

---

## 10. Delivery Sequence (suggested commit atoms)

Each bullet = one conventional commit. Keeps PR reviewable.

1. `chore(messages): rebase onto dev + branch setup`
2. `feat(messages): add domain use cases + tests` (T1.x)
3. `feat(messages): add riverpod providers + notifiers with tests` (T2.x)
4. `feat(messages): add shared chat widgets` (T3.x) — may split into 2 commits if diff grows
5. `feat(messages): add conversation list screen (P-35)` (T4.1)
6. `feat(messages): add chat thread screen (P-36)` (T4.2)
7. `feat(router): wire chat routes + deep-link validation` (T5.x)
8. `feat(l10n): add messages namespace (NL + EN)` (T6.x)
9. `fix(messages): a11y audit pass` (T7.x)
10. `docs(sprint): mark P-35 + P-36 complete` (T8.x, done at merge time)

---

## 11. Acceptance Criteria (Definition of Done)

- [ ] P-35 screen renders on iOS + Android + web (with mock repo), in both **light and dark** themes.
- [ ] P-36 screen renders on iOS + Android + web (with mock repo), in both **light and dark** themes.
- [ ] Compact layout (< `breakpoints.tablet`): push navigation list → thread works end-to-end.
- [ ] Expanded layout (≥ `breakpoints.tablet`): master-detail shows list + thread simultaneously; row selection updates URL without push; deep link survives cold start.
- [ ] All four states (loading/empty/error/data) visibly correct on both screens in both themes.
- [ ] `dart format --set-exit-if-changed .` exit 0.
- [ ] `flutter analyze --no-pub` zero warnings, zero infos.
- [ ] `flutter test --no-pub` all pass; messages feature coverage ≥ 70% (CLAUDE.md §6.1).
- [ ] Locale parity: every key exists in both `en-US.json` and `nl-NL.json` for both `messages.*` and `chat.*` namespaces.
- [ ] No hardcoded strings, colors, spacings, radii, typography, magic numbers (grep audit passes).
- [ ] All files respect CLAUDE.md §2.1 line limits (verified by `wc -l`).
- [ ] All interactive widgets have Semantics labels (NL + EN) + ≥ 44×44 touch targets.
- [ ] `MediaQuery.disableAnimations` respected for auto-scroll and shimmer.
- [ ] PR linked to `P-35` and `P-36` in `SPRINT-PLAN.md`; checkboxes flipped on merge.
- [ ] `code-reviewer` + `security-reviewer` agents run with no CRITICAL/HIGH findings.
- [ ] Scam alert explicitly NOT implemented (verified by PR description + `// P-37 SCOPE BOUNDARY` code comment).
- [ ] Offer CTA SnackBar fires and fires only — no transaction/payment API calls (verified by `grep -r "transactionRepository\|paymentRepository" lib/features/messages` = 0 matches).
- [ ] Visual parity with `docs/screens/06-chat/designs/` HTML mockups — reviewed via side-by-side screenshot comparison in PR description.

---

## 12. Plan Quality Self-Score

Per `.agent/skills/plan-validation/SKILL.md` rubric (medium-large tier):

| Criterion | Max | Score | Notes |
|:----------|:---:|:-----:|:------|
| Task size classification | 5 | 5 | Medium–Large (10–14 files, responsive + dark mode) |
| Schema completeness | 10 | 10 | All required sections present |
| Specificity — exact file paths | 15 | 15 | Every task has a file path |
| Verifiable done criteria | 15 | 15 | Each task has explicit verify criteria |
| Cross-cutting: security | 10 | 10 | §7.1 populated; PII, stubs, deep-link validation covered |
| Cross-cutting: testing | 10 | 10 | §7.2 populated + TDD enforced + theme matrix + responsive tests |
| Cross-cutting: documentation | 10 | 10 | §7.3 populated + decisions log preserves rationale |
| Risk analysis | 10 | 10 | 9 risks with mitigations |
| Agent orchestration | 5 | 5 | §9 assigns specialists per phase |
| Domain fit (Flutter + design-system) | 10 | 10 | Canonical screen spec + HTML mockups referenced; all questions resolved |
| Decisions transparency (bonus) | +5 | 5 | §13 decisions log with reversibility column |
| **Total** | **105** | **105** | ✅ PASS (≥ 70%) — **100% with bonus** |

---

## 13. Decisions Log (Senior Staff Engineer Authority)

All open questions from v1.0 have been resolved under delegated authority from the project owner.

| # | Question | Decision | Rationale | Reversibility |
|:--|:---------|:---------|:----------|:--------------|
| **Q1** | Design source of truth | **Use `docs/screens/06-chat/` — `01-conversation-list.md`, `02-chat-thread.md`, and all files under `designs/`** (light, dark, expanded, empty, loading, offer variants) | Authoritative canonical specs with HTML reference mockups covering all states and themes. Supersedes the generic `patterns.md` §Chat Thread, which is kept as secondary reference. | N/A — spec files are immutable inputs |
| **Q2** | Riverpod version | **flutter_riverpod 2.6.1 + riverpod_annotation 2.6.1 (current dev lockfile). Use code-gen.** | CLAUDE.md mentions Riverpod 3, but actual `pubspec.yaml` on dev is 2.x. Upgrading is a cross-cutting chore that would invalidate every feature module mid-sprint. Ship chat screens on what works today; raise a separate architect-owned follow-up chore. | Easy — migration is a single PR scoped to the whole `lib/` |
| **Q3** | Offer bubble CTAs behavior | **Render CTAs visually complete per design** (Accepteren=success filled, Afwijzen=outlined, Tegenbod=tertiary text). `onPressed` shows localized "Binnenkort beschikbaar" SnackBar **and** emits a tracked analytics intent event. | Design fidelity preserved; buttons respect a11y touch targets; user confusion minimized with honest messaging; analytics event quantifies demand for P-36.1 implementation priority. Disabled buttons would communicate "broken" not "not yet built". | Easy — T3.4 is isolated to one widget |
| **Q4** | Dark mode | **Ship both light + dark in this sprint, gated by system theme.** | Designs already exist for both; `theme.dart` + `DeelmarktColors` already support mode switching; no hardcoded colors is already a CLAUDE.md rule (§3.3); EU accessibility act expects theme preference honoring; retrofitting dark mode later roughly doubles widget test surface. Additional cost is ~10% on widget effort, not 100%. | Easy — removing dark mode later is trivial if needed |
| **Q5** | Responsive master-detail (new) | **Ship responsive layout (compact push nav + expanded master-detail at `breakpoints.tablet`).** | The design spec explicitly provides desktop/tablet mockups. Flutter web is a first-class target per E07 §Infrastructure. `LayoutBuilder` at the route root is cheap to add now (one shell file, T4.3) and expensive to retrofit later (every screen widget needs to learn about its parent layout). Matches the architectural grain already established by `lib/core/design_system/breakpoints.dart`. | Moderate — would require splitting shell into two separate route targets |

### Follow-up chores (raise immediately after PR merge)
- `chore: migrate flutter_riverpod 2.6 → 3.x` (architect agent) — roadmap decision, not blocking
- `feat(messages): wire P-37 scam alert banner into reserved slot` (trust/moderation sprint)
- `feat(messages): implement offer accept/decline/counter logic (P-36.1)` (payments sprint, depends on E03)
- `feat(messages): wire real Supabase Realtime repository` (backend sprint, reso `[R]`)

---

✅ **Plan saved:** `docs/PLAN-chat-screens.md` (v1.1 — decisions resolved)

**Next step:** Approve this plan, then run `/create feature/pizmam-E04-chat-screens` (or equivalent) to begin Phase 0 (rebase onto `origin/dev`). No implementation code will be written until explicit approval.
