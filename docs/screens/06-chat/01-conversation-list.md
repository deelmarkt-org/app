# Conversation List Screen

> Task: P-35 | Epic: E04 | Status: Placeholder | Priority: #12

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Conversation List Screen

LAYOUT:
- "Berichten" (Messages) header
- Conversation list, each row:
  - Avatar (48px) with online dot (green) or offline (grey)
  - Name "Jan de Vries" (bold if unread)
  - Last message preview: "Is de fiets nog beschikbaar?" (1 line, truncated)
  - Timestamp: "14:32" or "Gisteren" right-aligned
  - Unread badge: orange circle with count "2"
  - Listing thumbnail (40x40, rounded) far right — context of the conversation
- Divider between conversations (subtle)

CONTENT: 5-6 conversations about Dutch marketplace items. Mix of unread (bold)
and read. One conversation with an offer message preview: "Bod: € 120,00".

VARIATIONS: Light, Dark, Expanded (master-detail: list left 360px + thread
preview right), Empty state (no conversations — illustration +
"Start een gesprek door een advertentie te bekijken" CTA),
Loading (skeleton shimmer rows)
```

---

## l10n keys
```
messages.title: "Berichten" / "Messages"
messages.noConversations: "Nog geen berichten" / "No messages yet"
messages.startConversation: "Start een gesprek door een advertentie te bekijken" / "Start a conversation by viewing a listing"
messages.yesterday: "Gisteren" / "Yesterday"
messages.offerPreview: "Bod: {amount}" / "Offer: {amount}"
```
