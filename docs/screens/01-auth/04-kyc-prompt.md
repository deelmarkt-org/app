# KYC Prompt (Bottom Sheet)

> Task: P-23 | Epic: E02 | Status: Not started | Priority: #10

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: KYC Verification Prompt (Bottom Sheet)

TWO VARIANTS:

VARIANT 1 — Level 0→1 Banner (inline, shown on listing detail):
- Subtle banner below trust banner: shield icon + "Verifieer je account om
  te kopen" (Verify to buy) + "Verifieer nu →" orange link
- Appears contextually, not blocking

VARIANT 2 — Level 1→2 Bottom Sheet (modal, for high-value transactions):
- Drag handle at top
- Shield icon (large, green)
- "Extra verificatie vereist" (Additional verification required)
- "Voor transacties boven €500 is iDIN-verificatie nodig"
- "Wat is iDIN?" expandable FAQ
- Progress: "Stap 1 van 2" with progress bar
- "Verifieer met iDIN" large orange button (bank logo)
- "Later" ghost button
- Trust footer: lock icon + "Je bankgegevens worden niet opgeslagen"
  (Your bank details are not stored)

RESPONSIVE: Banner variant is full-width on all breakpoints.
Bottom sheet: max-width 480px centered on expanded layouts.

VARIATIONS: Light, Dark, Banner dismissed state, iDIN redirect loading,
Verification success (green checkmark animation), Expanded (centered modal)
```
