# Plan: Wire Navigation for Issues #50–#53

> **Owner:** pizmam (emredursun) | **Sprint:** 5–8 | **Size:** Medium (7 files modified, 1 new)
> **Status:** APPROVED — ready for implementation

---

## Scope

Wire 4 navigation actions that are currently stubbed with `// Tracked: #N` comments:

| Issue | Action | File | Line |
|-------|--------|------|------|
| #50 | Address form modal (add/edit) in Settings | `settings_screen.dart:106,109` | `onAdd` / `onEdit` callbacks |
| #51 | Sell screen from empty listings | `listings_tab_view.dart:45` | `EmptyState.onAction` |
| #52 | Listing detail from profile card | `listings_tab_view.dart:69` | `DeelCard.onTap` |
| #53 | Avatar picker from profile header | `profile_header.dart:26` | `DeelAvatar.onEditTap` |

**Exclusions:**
- No new screens (all targets are existing placeholders or modals)
- No backend work (image upload, address API)
- No listing creation flow (P-24)
- No listing detail screen (B-51)

---

## Socratic Gate Decisions

1. **#50 — Address form:** Modal bottom sheet reusing `DutchAddressInput` widget. Design doc explicitly says _"Edit address modal"_ (`docs/screens/07-profile/03-settings.md:45`).
2. **#51 — Sell navigation:** Navigate to `/sell` tab (bottom nav index 2). Placeholder exists; P-24 replaces it later.
3. **#52 — Listing detail:** Wire `context.push('/listings/${listing.id}')` now. Route exists at `app_router.dart:174` with placeholder.
4. **#53 — Avatar picker:** Open native image picker only (Option B). No upload — R-27 Edge Function not yet built. Show snackbar with selected file info as confirmation.

---

## Tasks

### Task 1: Create AddressFormModal widget — `lib/features/profile/presentation/widgets/address_form_modal.dart` (NEW)

**What:** A modal bottom sheet containing `DutchAddressInput` + Save/Cancel buttons.
**Details:**
- Accepts optional `DutchAddress?` for edit mode (pre-fill fields), null for add mode
- Uses `DutchAddressInput` widget from `lib/features/shipping/presentation/widgets/dutch_address_input.dart`
- Save button calls `onSave(DutchAddress)` callback
- Title: `'settings.addAddress'.tr()` or `'settings.editAddress'.tr()` based on mode
- Form validation: postcode + house number required, street/city auto-filled
- Wrap in `ResponsiveBody` for max-width consistency
- **Verify:** Modal opens with empty fields (add) or pre-filled fields (edit), form validates, save returns `DutchAddress`

### Task 2: Wire #50 — Address form navigation in Settings — `settings_screen.dart:106,109`

**What:** Replace `// Tracked: #50` comments with modal bottom sheet calls.
**Details:**
- `onAdd`: `showModalBottomSheet` → `AddressFormModal()` → call `settingsProvider.notifier.addAddress(address)`
- `onEdit`: `showModalBottomSheet` → `AddressFormModal(address: address)` → call `settingsProvider.notifier.updateAddress(address)`
- Import `address_form_modal.dart`
- **Verify:** Tapping "Adres toevoegen" opens empty modal; tapping edit icon opens pre-filled modal

### Task 3: Wire #51 — Sell screen navigation — `listings_tab_view.dart:45`

**What:** Replace `// Tracked: #51` with navigation to sell tab.
**Details:**
- Add `BuildContext` access (widget already has it via `build`)
- Use `StatefulNavigationShell.of(context).goBranch(2)` to switch to sell tab (index 2 in bottom nav)
- Import `go_router` package
- **Verify:** Empty listings "Plaats je eerste advertentie" button navigates to Sell tab

### Task 4: Wire #52 — Listing detail navigation — `listings_tab_view.dart:69`

**What:** Replace `// Tracked: #52` with push to listing detail route.
**Details:**
- `context.push('/listings/${listing.id}')` inside `DeelCard.onTap`
- Import `go_router` for `context.push`
- **Verify:** Tapping a listing card on profile navigates to listing detail placeholder

### Task 5: Wire #53 — Avatar picker — `profile_header.dart:26`

**What:** Replace `// Tracked: #53` with image picker dialog.
**Details:**
- Add `image_picker` package to `pubspec.yaml` (needed for camera + gallery)
- Show `showModalBottomSheet` with two options: Camera / Gallery (Phosphor icons)
- Use `ImagePicker().pickImage(source: ...)` to open native picker
- On selection: show `ScaffoldMessenger.of(context).showSnackBar(...)` confirming file path (temporary until R-27)
- Log selected image path for future upload integration
- Accessibility: both options have semantic labels
- **Verify:** Edit overlay tap shows picker modal; selecting image shows confirmation snackbar

### Task 6: Add l10n keys for new UI elements

**What:** Add translation keys to `assets/l10n/en-US.json` and `assets/l10n/nl-NL.json`.
**Details:**
- `settings.editAddress`: "Adres bewerken" / "Edit address"
- `settings.addressSaved`: "Adres opgeslagen" / "Address saved"
- `profile.pickPhoto`: "Kies een foto" / "Choose a photo"
- `profile.takePhoto`: "Maak een foto" / "Take a photo"
- `profile.chooseFromGallery`: "Kies uit galerij" / "Choose from gallery"
- `profile.photoSelected`: "Foto geselecteerd" / "Photo selected"
- **Verify:** All new keys resolve without fallback warnings in both NL and EN

### Task 7: Write tests for all 4 navigation wiring changes

**What:** Widget tests verifying navigation triggers.
**Details:**
- `test/features/profile/presentation/widgets/address_form_modal_test.dart` — modal renders, validates, returns address
- Update `test/features/profile/presentation/widgets/addresses_section_test.dart` — verify onAdd/onEdit trigger modal
- `test/features/profile/presentation/widgets/listings_tab_view_navigation_test.dart` — empty state action + card tap navigation
- `test/features/profile/presentation/widgets/profile_header_navigation_test.dart` — edit overlay opens picker
- **Verify:** All tests pass, coverage >= 70% for modified files

---

## Agent Assignments

| Task | Agent | Domain |
|------|-------|--------|
| 1–2 | pizmam | Frontend/Design |
| 3–4 | pizmam | Frontend/Design |
| 5 | pizmam | Frontend/Design |
| 6 | pizmam | l10n |
| 7 | tdd-guide | Testing |

---

## Cross-Cutting Concerns

### Security
- No user input leaves the device (avatar picker is local only)
- Address form validates postcode format via existing `PostcodeInputFormatter`
- No new API calls introduced

### Testing
- Widget tests for all 4 navigation actions
- Golden tests not required (no new visual components, only wiring)
- Target: 70%+ coverage on modified files

### Accessibility (WCAG 2.2 AA)
- Modal bottom sheets use `Semantics` labels
- Image picker options have `tooltip` and semantic labels
- Touch targets ≥ 44x44px (enforced by design system)

### Documentation
- No doc updates needed (these are tracked issues, not new features)
- `// Tracked: #N` comments removed and replaced with actual implementation

---

## Dependencies

| Dependency | Status | Impact |
|------------|--------|--------|
| `DutchAddressInput` widget | EXISTS | Reuse for address modal |
| `DutchAddress` entity | EXISTS | Address data model |
| `EmptyState` + variants | EXISTS | myListings variant wired |
| `/sell` route placeholder | EXISTS | Navigation target |
| `/listings/:id` route placeholder | EXISTS | Navigation target |
| `DeelAvatar.onEditTap` | EXISTS | Callback already plumbed |
| `image_picker` package | NEW | Must add to pubspec.yaml |
| R-27 Image upload Edge Function | NOT BUILT | Avatar upload deferred |
| P-24 Listing creation | NOT BUILT | Sell screen shows placeholder |
| B-51 Listing detail screen | NOT BUILT | Detail shows placeholder |

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| `image_picker` platform issues on web | Low | DeelMarkt is mobile-first; web fallback can be added later |
| Address modal UX confusion (no API auto-fill yet) | Medium | Street/city fields show as empty/manual for now; auto-fill when postcode API wired |
| Bottom nav index hardcoded (2) | Low | Use `StatefulNavigationShell.of(context).goBranch(2)` — index matches router definition |

---

## Execution Order

1. Task 6 (l10n keys) — no dependencies
2. Task 1 (AddressFormModal) — new widget
3. Task 5 (image_picker + avatar picker) — pubspec change + new code
4. Tasks 2, 3, 4 (wire #50, #51, #52) — can be parallel
5. Task 7 (tests) — after all implementation

---

Plan saved: `docs/PLAN-wire-navigation.md`
Approve to start implementation.
