# DeelMarkt — Screen Design Prompts

> Structured AI design prompts for every screen in the app.
> Each file contains the prompt, design specs, and links to generated assets.

## How to use

1. Open the screen `.md` file
2. Copy the **Design Prompt** section
3. Paste into your design tool (Midjourney, DALL-E, Figma AI, v0.dev, etc.)
4. Save generated designs back into the `designs/` subfolder
5. Reference the design when implementing the Flutter screen

## Directory structure

```
docs/screens/
├── 01-auth/          Auth & onboarding flows
├── 02-home/          Home, search, category browse
├── 03-listings/      Listing detail, creation, favourites
├── 04-payments/      Payment summary, checkout, transaction detail
├── 05-shipping/      QR, tracking, parcel shop (implemented)
├── 06-chat/          Conversations, chat thread, scam alerts
├── 07-profile/       Profile, settings, ratings
└── 08-admin/         Admin moderation panel
```

## Design system tokens (use in every prompt)

> See [DESIGN-SYSTEM-PREAMBLE.md](DESIGN-SYSTEM-PREAMBLE.md) for the complete preamble.
> Source of truth: [docs/design-system/tokens.md](../design-system/tokens.md)

- **Primary:** `#F15A24` (orange) — CTAs, FAB, active states
- **Secondary:** `#1E4F7A` (blue) — headers, links, small text, trust badges
- **Success:** `#2EAD4A` — verified, escrow released
- **Error:** `#E53E3E` — scam alerts, destructive actions
- **Trust Verified:** `#16A34A` — iDIN badge (dedicated, never general UI)
- **Background light:** `#F8F9FB` scaffold, `#FFFFFF` cards
- **Background dark:** `#121212` scaffold, `#1E1E1E` cards, `#333333` borders
- **Typography:** Plus Jakarta Sans (Regular 400, Medium 500, SemiBold 600, Bold 700)
- **Radius:** xs 6px, sm 8px, md 10px, lg 12px (buttons), xl 16px (cards), xxl 24px
- **Spacing:** s1 4px, s2 8px, s3 12px, s4 16px, s5 20px, s6 24px, s8 32px
- **Button heights:** Large 52px, Medium 44px, Small 36px
- **Card image ratio:** 4:3 (NOT 16:9)
- **Touch targets:** minimum 44x44px, 8px spacing between
- **Breakpoints:** compact <600px, medium 600-840px, expanded >=840px
- **Contrast rule:** Orange on white = 3.4:1 — large text only. Small text: use secondary blue.

## Design generation priority

1. Home Screen (buyer) — first impression
2. Listing Detail — where trust is built
3. Search — browse and discover
4. Onboarding — first launch experience
5. Registration + Login — auth flow
6. Payment Summary — checkout clarity
7. Listing Creation — seller core action
8. Chat Thread — buyer-seller communication
