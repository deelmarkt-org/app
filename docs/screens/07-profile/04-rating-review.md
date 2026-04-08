# Rating & Review Screen

> Task: P-38 | Epic: E06 | Status: Not started | Priority: #11

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Post-Transaction Rating Screen

LAYOUT:
- "Beoordeling" (Review) header with close X
- Listing context: small card with thumbnail + title + price + buyer/seller name
- "Hoe was je ervaring met [naam]?" (How was your experience with [name]?)
- 5 large star icons (48px each, tappable):
  filled stars = orange, empty = grey outline
  Show 4 stars selected as example
- Text input (multiline, 4 lines visible):
  placeholder "Vertel over je ervaring..." (Tell about your experience)
  Character count "0/500" bottom-right
- Info callout: shield icon + "Blinde beoordeling — de ander kan jouw
  beoordeling pas zien na het invullen van hun eigen beoordeling"
  (Blind review — the other party can only see your review after submitting theirs)
- "Beoordeling plaatsen" (Submit review) primary orange button

CONTENT: Post-purchase review for a bicycle transaction. Natural Dutch text.

VARIATIONS (include all 4 states per preamble: loading skeleton, error, empty, data): Light, Dark, Expanded (centered max 500px),
Already submitted state ("Bedankt! Wacht op de beoordeling van de verkoper"),
Both submitted state (showing both reviews side by side)
```

---

## l10n keys
```
review.title: "Beoordeling" / "Review"
review.how_was_experience: "Hoe was je ervaring met {name}?" / "How was your experience with {name}?"
review.tell_about: "Vertel over je ervaring..." / "Tell about your experience..."
review.blind_review: "Blinde beoordeling" / "Blind review"
review.blind_explanation: "De ander kan jouw beoordeling pas zien na het invullen van hun eigen beoordeling" / "The other party can only see your review after submitting theirs"
review.submit: "Beoordeling plaatsen" / "Submit review"
review.thank_you: "Bedankt!" / "Thank you!"
review.waiting_for_other: "Wacht op de beoordeling van de verkoper" / "Waiting for the seller's review"
```
