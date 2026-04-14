# Appeal Form Screen

> Task: P-53 | Epic: E06 | Status: Not started | Priority: #23

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/appeal-form` (push from suspension gate `active` state only) |
| Auth | Required |
| States | `idle`, `typing`, `submitting`, `error`, `success` |
| Responsive | Compact: full-screen scroll, Expanded: centered card max 480px |
| Dark mode | Required |
| Entry | Only reachable from suspension gate `active` state (`canAppeal: true`) |
| Exit | System back / swipe — triggers discard-confirm dialog if draft is dirty |

---

## When Shown

Navigated to from the "Appeal" CTA on the suspension gate screen, exclusively when `canAppeal: true`. If the user navigates here and `canAppeal` has since changed (race condition), the ViewModel fetches sanction state on `initState` and pops back with a snackbar if the window has closed.

---

## Layout

```
┌─────────────────────────────────┐
│  ← Back               (app bar) │
│  "Submit an appeal"    (title)  │
│                                 │
│  DeelCard — sanction summary    │
│    • Type + reason (read-only)  │
│    • Expires label + date/perm  │
│                                 │
│  Textarea (autofocus)           │
│    • Hint text                  │
│    • Min 10 / max 1000 chars    │
│    • Live char counter          │
│                                 │
│  [Submit appeal]  (primary btn) │
│    disabled when invalid/loading│
└─────────────────────────────────┘
```

---

## Components

| Component | Widget | Notes |
|-----------|--------|-------|
| Sanction summary | `DeelCard` | Read-only; mirrors reason card from gate |
| Textarea | `TextField` (multiline) | `autofocus: true`, max lines uncapped, `maxLength: 1000` (enforced) |
| Char counter | Inline below textarea | `Semantics(value: '$count / 1000')` — announced on change |
| Submit | `DeelButton.primary` | Disabled while `count < 10` or state is `submitting` |

---

## States

### `idle` — No input yet

- Textarea shows hint: `sanction.screen.appeal_hint`
- Char counter shows `0 / 1000`
- Submit button disabled

### `typing` — User is entering text

- Counter updates live: e.g. `42 / 1000`; turns error-coloured below 10 chars
- Submit enabled once `count >= 10`
- Draft auto-saved to `SharedPreferences` key `"appeal_draft_{sanctionId}"` with 500ms debounce

### `submitting` — API call in flight

- Submit button shows inline spinner; label replaced with loading indicator
- Textarea and submit are disabled; back gesture blocked via `WillPopScope` / `PopScope`

### `error` — API returned error

- Error snackbar shown (bottom): message from server or generic fallback
- Form returns to `typing` state; user can retry
- Draft is preserved

### `success` — Appeal accepted by server

- Draft cleared from `SharedPreferences`
- Screen pops back to suspension gate
- Gate refreshes and transitions to `pending` state showing `_ReceiptBanner`

---

## Validation

| Rule | Client | Server |
|------|--------|--------|
| Minimum length | 10 chars (submit disabled below) | Non-empty enforced |
| Maximum length | 1000 chars (`maxLength` enforced, counter) | ≤ 1000 chars |
| Appeal window | Checked on `initState` (pop if closed) | Window + eligibility enforced |
| Eligible sanction type | Enforced at gate (warnings cannot appeal) | Eligibility re-checked |

---

## Draft Persistence

- **Key:** `"appeal_draft_{sanctionId}"` in `SharedPreferences`
- **Write:** Debounced 500ms after last keystroke via `Timer`
- **Read:** On `initState` — pre-fills textarea if draft exists
- **Clear:** On successful submit
- **Discard dialog:** When user attempts back navigation with a non-empty, un-submitted draft:
  - Title: `sanction.screen.appeal_title` (reused)
  - Body: confirm discard prompt (hardcoded is acceptable here as it's a dialog; use l10n key if one is added in Phase B)
  - Actions: "Discard" (destructive) / "Keep editing" (cancel)

---

## l10n Keys

| Key | EN | NL |
|-----|----|----|
| `sanction.screen.appeal_title` | `"Submit an appeal"` | `"Bezwaar indienen"` | *(existing)* |
| `sanction.screen.appeal_hint` | `"Explain why you believe this decision is incorrect (max 1000 characters)"` | `"Leg uit waarom je denkt dat deze beslissing onjuist is (max. 1000 tekens)"` | *(existing)* |
| `sanction.screen.appeal_submit` | `"Submit appeal"` | `"Bezwaar indienen"` | *(existing)* |
| `sanction.screen.appeal_window_closed` | `"The 14-day appeal window for this sanction has closed."` | `"De bezwaartermijn van 14 dagen voor deze sanctie is verlopen."` | *(existing)* |
| `sanction.screen.reason_label` | `"Reason"` | `"Reden"` | *(existing)* |
| `sanction.screen.expires_label` | `"Suspended until"` | `"Geschorst tot"` | *(existing)* |
| `sanction.screen.permanent` | `"Permanent"` | `"Permanent"` | *(existing)* |
| `sanction.screen.sla_72h` | `"We'll review your appeal within 72 hours"` | `"We beoordelen je beroep binnen 72 uur"` | **NEW** |
| `sanction.screen.receipt` | `"Submitted {time} · Reference {id}"` | `"Ingediend {time} · Referentie {id}"` | **NEW** |
| `sanction.a11y.appeal_form` | `"Appeal form"` | `"Bezwaarformulier"` | *(existing)* |

---

## Accessibility

- Textarea receives `autofocus: true` so focus lands on it immediately (avoids extra tap on mobile).
- Char counter announced on every change via `Semantics(value: '$count / 1000', liveRegion: true)`.
- Submit button has `Semantics(enabled: isValid && !isSubmitting)` — state communicated to assistive tech.
- Back navigation discard dialog buttons meet 44×44px touch target requirement.
- All text uses `DeelmarktTypography` tokens; no inline `TextStyle`.
- Focus order: app bar back → sanction card → textarea → submit button (natural top-to-bottom).

---

## Dark Mode

| Element | Light | Dark |
|---------|-------|------|
| Screen background | `neutral50` | `darkScaffold` |
| Sanction summary card | `neutral100` | `darkSurface` |
| Textarea background | `white` | `darkSurfaceElevated` |
| Textarea border (idle) | `neutral300` | `darkBorder` |
| Textarea border (focus) | `primary` | `darkPrimary` |
| Counter (valid) | `neutral500` | `darkOnSurfaceSecondary` |
| Counter (< 10 chars) | `error` | `darkError` |
| Submit button (active) | `primary` | `darkPrimary` |

---

## Design Tokens

| Token Category | Tokens Used |
|----------------|-------------|
| Colors | `DeelmarktColors.primary`, `.neutral100`, `.neutral300`, `.neutral500`, `.error`; dark equivalents |
| Typography | `DeelmarktTypography.headingMd` (screen title), `.bodyLg` (textarea text, card body), `.bodySm` (counter) |
| Spacing | `Spacing.s3` (card internal padding), `Spacing.s4` (section gaps), `Spacing.s6` (horizontal padding) |
| Radius | `DeelmarktRadius.md` (card, textarea border) |

---

## Design Reference

- Spec: `docs/screens/01-auth/07-appeal-form.md` (this file)
- Designs: `01-auth/designs/appeal_form_*` — to be created by designer
- Variants required: `light_idle`, `light_typing`, `light_submitting`, `light_error`, `dark_idle`
