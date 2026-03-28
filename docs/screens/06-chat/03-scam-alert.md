# Scam Alert Integration

> Task: P-37 | Epic: E06 | Status: Not started | Priority: #21

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Scam Alert Banner (inline in Chat Thread)

LAYOUT:
- Error surface (#FDE8E8) banner with error (#E53E3E) left border accent
- Warning triangle icon (left)
- Text: "Dit bericht bevat mogelijk oplichting" (This message may contain a scam)
- Expandable: tap to see "Waarom deze waarschuwing?" (Why this warning?)
  - AI detected: external payment link / phone number request / too-good-to-be-true offer
- "Meld dit bericht" (Report this message) link
- Non-dismissible for high-confidence flags

VARIATIONS: Light chat context, Dark chat context,
Expanded (showing reason), Low-confidence (amber instead of red, dismissible)
```
