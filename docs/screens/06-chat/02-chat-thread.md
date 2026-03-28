# Chat Thread Screen

> Task: P-36 | Epic: E04 | Status: Not started | Priority: #8

---

## Screen Info

| Field | Value |
|-------|-------|
| Route | `/messages/:conversationId` |
| Auth | Required |
| States | Loading, Data (messages), Empty (new conversation), Error, Typing |
| Responsive | Compact: full-screen, Expanded: master-detail (list left, thread right) |
| Dark mode | Required |

## Layout

1. **App bar** — Back arrow, other user avatar + name + "Online" indicator, options menu (⋯)
2. **Listing embed** (top, collapsible) — Small card: thumbnail + title + price + status
3. **Message list** — Scrollable, newest at bottom:
   - Buyer messages: right-aligned, orange-tinted background
   - Seller messages: left-aligned, grey/surface background
   - Timestamps: grouped by day ("Vandaag", "Gisteren"), time per message
   - Read receipts: double checkmark
4. **Structured offer** (special message type):
   - Card with: "Bod van € 120,00" (Offer of €120)
   - Two buttons: "Accepteren" (Accept, green) / "Afwijzen" (Decline, grey)
   - Or status: "Geaccepteerd ✓" / "Afgewezen ✗"
5. **Scam alert** (if flagged) — Red banner: "⚠ Dit bericht bevat mogelijk oplichting" (may contain scam)
6. **Input bar** (sticky bottom):
   - Text input: "Typ een bericht..." (Type a message)
   - Attachment icon (camera/image)
   - "Doe een bod" (Make an offer) button
   - Send button (orange, arrow icon)

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Chat Thread Screen

LAYOUT:
- App bar: back arrow, "Jan de Vries" with small avatar (32px) and green
  online dot, options (⋯) menu right
- Listing context card (collapsible, subtle surface background):
  tiny thumbnail + "Canyon Speedmax" + "€ 149,00" + "Te koop"
- Message thread:
  - Day separator: "Vandaag" centered in grey text
  - Seller message (left, grey bubble): "Hoi! Is de fiets nog beschikbaar?"
  - Buyer message (right, subtle orange bubble): "Ja, nog beschikbaar!
    Wanneer kun je langskomen?"
  - Seller: "Ik bied € 120,00 — is dat akkoord?" — this is a structured
    OFFER CARD: bordered card with "Bod: € 120,00", "Accepteren" (green)
    + "Afwijzen" (outlined grey) buttons
  - Timestamps: "14:32" right-aligned under each message, small grey text
  - Read receipts: ✓✓ blue under buyer messages

- Input bar at bottom:
  - Camera icon (left)
  - Text field: "Typ een bericht..." placeholder
  - "Bod" (Offer) chip/button
  - Orange send arrow button (right)

CONTENT: Conversation about buying a bicycle. Natural Dutch chat language.
Messages should feel real — short, casual, with some emoji.

VARIATIONS: Light, Dark, Expanded (master-detail: conversation list 320px
left, thread right), Offer accepted state (green "Geaccepteerd ✓" badge
on offer card), Scam alert (red banner above input bar with warning icon)
```

---

## l10n keys
```
chat.typeMessage: "Typ een bericht..." / "Type a message..."
chat.makeOffer: "Doe een bod" / "Make an offer"
chat.offer: "Bod" / "Offer"
chat.offerOf: "Bod van {amount}" / "Offer of {amount}"
chat.accept: "Accepteren" / "Accept"
chat.decline: "Afwijzen" / "Decline"
chat.accepted: "Geaccepteerd" / "Accepted"
chat.declined: "Afgewezen" / "Declined"
chat.online: "Online" / "Online"
chat.today: "Vandaag" / "Today"
chat.yesterday: "Gisteren" / "Yesterday"
chat.scamWarning: "Dit bericht bevat mogelijk oplichting" / "This message may contain a scam"
```
