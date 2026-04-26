# Settings Screen

> Task: P-18 | Epic: E02 | Status: Not started | Priority: #15

---

## Design Prompt

> Prepend [DESIGN-SYSTEM-PREAMBLE.md](../DESIGN-SYSTEM-PREAMBLE.md) before this prompt.

```
SCREEN-SPECIFIC DESIGN: Settings Screen

LAYOUT:
- "Instellingen" (Settings) header with back arrow
- Grouped sections with subtle headers:

ACCOUNT section:
- "Taal" (Language) — NL/EN segmented control (inline, no navigation)
- "E-mailadres" — "info@deelmarkt.com" with edit icon
- "Telefoonnummer" — "+31 6 •••• 1234" with edit icon

ADRESSEN (Addresses) section:
- Saved addresses list: "Kalverstraat 1, Amsterdam" with edit/delete
- "Adres toevoegen" (Add address) button

MELDINGEN (Notifications) section:
- Toggle rows: "Berichten" (Messages) ON, "Biedingen" (Offers) ON,
  "Verzendupdates" (Shipping updates) ON, "Marketing" OFF

PRIVACY section:
- "Gegevens exporteren" (Export data) — GDPR data export
- "Account verwijderen" (Delete account) — destructive red text

APP section:
- "Versie" (Version) — "1.0.0 (42)"
- "Licenties" (Licenses) — open source licenses

CONTENT: Clean grouped list, no clutter. Each section has a subtle header.

STATES: Loading (skeleton shimmer), Error ("Dat lukte niet — probeer opnieuw"),
Empty (see specific empty state below), Data (normal content)

VARIATIONS: Light, Dark, Expanded (max 720px centered),
Edit address modal (DutchAddressInput widget with postcode auto-fill)
```

---

## l10n keys
```
settings.title: "Instellingen" / "Settings"
settings.account: "Account" / "Account"
settings.language: "Taal" / "Language"
settings.email: "E-mailadres" / "Email"
settings.phone: "Telefoonnummer" / "Phone number"
settings.addresses: "Adressen" / "Addresses"
settings.addAddress: "Adres toevoegen" / "Add address"
settings.notifications: "Meldingen" / "Notifications"
settings.messages: "Berichten" / "Messages"
settings.offers: "Biedingen" / "Offers"
settings.shippingUpdates: "Verzendupdates" / "Shipping updates"
settings.marketing: "Marketing" / "Marketing"
settings.privacy: "Privacy" / "Privacy"
settings.exportData: "Gegevens exporteren" / "Export data"
settings.deleteAccount: "Account verwijderen" / "Delete account"
settings.version: "Versie" / "Version"
settings.licenses: "Licenties" / "Licenses"
```
