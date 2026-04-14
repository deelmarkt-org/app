# Suspension Gate Screen

> Task: P-53 | Epic: E06 | Status: Not started | Priority: #22

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/suspension-gate` (injected by router guard on session start) |
| Auth | Required (user is authenticated but gated) |
| States | `active` (can appeal), `pending` (appeal under review), `upheld` (final) |
| Responsive | Compact: full-screen scroll, Expanded: centered card max 480px |
| Dark mode | Required |
| Exit | `PopScope(canPop: false)` — logout-only via top-right action |

---

## When Shown

Displayed whenever the router guard detects an active sanction returned by the `get_active_sanction` RPC. The screen blocks all app navigation until the sanction expires or is overturned. It is never shown for `type = warning` (warnings are surfaced inline; only `suspension` and `ban` reach this gate).

---

## Layout

```
┌─────────────────────────────────┐
│  [Logout]              (top-right action)
│                                 │
│  _SanctionHeader                │
│    • Error/warning icon (64px)  │
│    • Type label (suspension/ban)│
│    • Screen title               │
│                                 │
│  DeelCard — reason              │
│    • "Reason" label             │
│    • Reason text (body-lg)      │
│                                 │
│  _CountdownChip  OR  "Permanent"│
│    • Days remaining (temp)      │
│    • Static chip (ban)          │
│                                 │
│  [state-specific body]          │
│    active  → appeal CTA         │
│    pending → _ReceiptBanner     │
│    upheld  → final copy         │
│                                 │
│  _CtaRow                        │
│    • Appeal button (primary)    │  ← active only
│    • Contact support (ghost)    │  ← always
└─────────────────────────────────┘
```

---

## Components

| Component | Widget | Notes |
|-----------|--------|-------|
| Header | `_SanctionHeader` | Icon + type chip + title; `Semantics(liveRegion: true)` on state transitions |
| Reason | `DeelCard` | `DeelmarktRadius.md`, neutral100 background |
| Countdown | `_CountdownChip` | Amber chip for temp suspension; hidden for `ban` |
| Receipt | `_ReceiptBanner` | Shown only in `pending` state; see §States |
| CTAs | `_CtaRow` | Appeal = `DeelButton.primary`, Contact = `DeelButton.ghost` |

`DeelCard` and `DeelButton` are from `lib/widgets/`. `_SanctionHeader`, `_CountdownChip`, `_ReceiptBanner`, and `_CtaRow` are private widgets within the screen file.

---

## States

### `active` — Appeal window open, `canAppeal: true`

- `_SanctionHeader`: error icon (`DeelmarktColors.error`) + `sanction.type.suspension` or `sanction.type.ban` + `sanction.screen.title`
- `_CountdownChip`: amber chip with `sanction.screen.countdown_days` (ICU plural) — omitted for `ban`
- `_CtaRow`: Appeal button (navigates to `/appeal-form`) + Contact support link

### `pending` — Appeal submitted, awaiting review

- Header: info icon (`DeelmarktColors.info`) + `sanction.screen.appeal_pending_title`
- `_ReceiptBanner`: `sanction.screen.receipt` with submission timestamp + reference ID; `sanction.screen.sla_72h` below
- Appeal button replaced by disabled receipt display; Contact support link remains

### `upheld` — Appeal rejected, decision final

- Header: error icon + `sanction.screen.appeal_upheld_title`
- Body copy: `sanction.screen.appeal_upheld_body`
- No appeal CTA; Contact support link only
- `_CountdownChip` or permanent label still shown

---

## l10n Keys

| Key | EN | NL |
|-----|----|----|
| `sanction.type.suspension` | `"Suspension"` | `"Schorsing"` | *(existing)* |
| `sanction.type.ban` | `"Ban"` | `"Verbanning"` | *(existing)* |
| `sanction.screen.title` | `"Account suspended"` | `"Account geschorst"` | *(existing)* |
| `sanction.screen.reason_label` | `"Reason"` | `"Reden"` | *(existing)* |
| `sanction.screen.expires_label` | `"Suspended until"` | `"Geschorst tot"` | *(existing)* |
| `sanction.screen.permanent` | `"Permanent"` | `"Permanent"` | *(existing)* |
| `sanction.screen.appeal_pending_title` | `"Appeal under review"` | `"Bezwaar in behandeling"` | *(existing)* |
| `sanction.screen.appeal_pending_body` | `"Your appeal is being reviewed…"` | `"Je bezwaar wordt beoordeeld…"` | *(existing)* |
| `sanction.screen.appeal_upheld_title` | `"Appeal upheld"` | `"Bezwaar afgewezen"` | *(existing)* |
| `sanction.screen.appeal_upheld_body` | `"Your appeal was reviewed and the decision stands."` | `"Je bezwaar is beoordeeld en de beslissing blijft van kracht."` | *(existing)* |
| `sanction.screen.contact_support` | `"Contact support"` | `"Neem contact op met support"` | *(existing)* |
| `sanction.screen.countdown_days` | `"{count, plural, one{1 day left} other{{count} days left}}"` | `"{count, plural, one{Nog 1 dag} other{Nog {count} dagen}}"` | **NEW** |
| `sanction.screen.sla_72h` | `"We'll review your appeal within 72 hours"` | `"We beoordelen je beroep binnen 72 uur"` | **NEW** |
| `sanction.screen.receipt` | `"Submitted {time} · Reference {id}"` | `"Ingediend {time} · Referentie {id}"` | **NEW** |
| `sanction.a11y.sanction_icon` | `"Account suspended icon"` | `"Pictogram account geschorst"` | *(existing)* |

---

## Accessibility

- `PopScope(canPop: false)` — back gesture and system back are disabled; only the logout action exits.
- `_SanctionHeader` wrapped in `Semantics(liveRegion: true)` so screen readers announce state transitions (active → pending → upheld).
- All touch targets ≥ 44×44px (`DeelButton` enforces this by default).
- Contrast: error/warning surface tokens satisfy WCAG 2.2 AA (≥ 4.5:1 body text, ≥ 3:1 large text).
- `_CountdownChip` includes `Semantics(label: <full countdown string>)` to avoid the abbreviated visual label being read ambiguously.
- Logout action in app bar has `Semantics(label: 'Log out')`.

---

## Dark Mode

| Element | Light | Dark |
|---------|-------|------|
| Screen background | `neutral50` | `darkScaffold` |
| Reason card | `neutral100` | `darkSurface` |
| Header icon (suspension) | `error` (#E53E3E) | `darkError` (#F87171) |
| Header icon (ban) | `error` | `darkError` |
| Countdown chip bg | `warningSurface` | `darkSurfaceElevated` |
| Countdown chip text | `warning` | `darkWarning` |
| Receipt banner bg | `infoSurface` | `darkSurfaceElevated` |
| Receipt banner accent | `info` | `darkInfo` |

---

## Design Tokens

| Token Category | Tokens Used |
|----------------|-------------|
| Colors | `DeelmarktColors.error`, `.errorSurface`, `.warning`, `.warningSurface`, `.info`, `.infoSurface`, `.neutral100`, `.neutral700`, `.neutral900`; dark equivalents |
| Typography | `DeelmarktTypography.headingLg` (title), `.bodyLg` (reason text), `.bodySm` (chip/receipt) |
| Spacing | `Spacing.s3` (card padding), `Spacing.s4` (section gaps), `Spacing.s5` (header top), `Spacing.s6` (horizontal padding) |
| Radius | `DeelmarktRadius.xl` (screen card on expanded), `DeelmarktRadius.md` (reason card, chip) |
| Elevation | None (flat design) |

---

## Telemetry

- Analytics event `suspension_gate_shown` fired on `initState` with properties: `{ sanction_type, appeal_state, has_expiry }`. No PII (no reason text, no user ID in event payload).
- Sentry breadcrumb added: `category: 'suspension_gate', message: 'gate shown', data: { type, state }`.
- Appeal CTA tap fires `suspension_gate_appeal_tapped` (no additional data).

---

## Design Reference

- Spec: `docs/screens/01-auth/05-suspension-gate.md` (this file)
- Designs: `01-auth/designs/suspension_gate_*` — to be created by designer
- Variants required: `light_active`, `light_pending`, `light_upheld`, `dark_active`, `dark_pending`
