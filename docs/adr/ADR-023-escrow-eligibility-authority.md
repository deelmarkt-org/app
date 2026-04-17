# ADR-023: Escrow Eligibility — Backend-Authoritative Computation

### Status

**Accepted — Implementation pending** — Decision ratified 2026-04-17 · Author: pizmam · **Blocks:** GitHub issue [#59](https://github.com/deelmarkt-org/app/issues/59) · **Waiting on:** reso (`supabase/migrations/*_listings_escrow_eligible.sql` + trigger) · belengaz (`ListingDto.escrowEligible` field)

### Context

Issue [#59](https://github.com/deelmarkt-org/app/issues/59) calls for showing `EscrowBadge` on `ListingCard` when the listing is escrow-eligible. The initial plan proposed client-side derivation:

```dart
bool get isEscrowAvailable =>
    status == ListingStatus.active &&
    priceInCents >= 5000 &&
    (qualityScore ?? 0) >= 50;
```

A pre-implementation audit classified this as a critical legal risk:

- **EU Consumer Rights Directive 2011/83 Art. 6(1)(r)** requires pre-contractual information to be accurate.
- **Omnibus Directive 2019/2161** escalates misleading-practice penalties up to 4% of EU turnover.
- **ACM (Dutch Authority for Consumers & Markets)** enforces UX-truthfulness on Dutch marketplaces (see Marktplaats case 2021 on "verified seller" badge drift).

A client-derived badge will diverge from server-side eligibility the moment E03 Phase 2 ships seller-scoped rules (KYC level, dispute rate, suspension status) — because those inputs are not available in `ListingEntity`. Buyer sees "Escrow beschikbaar", checkout refuses escrow → consumer complaint is legally defensible.

### Decision

**Escrow eligibility is computed server-side and stored on the `listings` row.** The client reads a boolean field and never derives it.

1. **Schema** (reso): migration `supabase/migrations/<ts>_listings_escrow_eligible.sql`
   ```sql
   ALTER TABLE listings ADD COLUMN escrow_eligible BOOLEAN NOT NULL DEFAULT false;
   ```
2. **Computation** (reso): `BEFORE INSERT OR UPDATE` trigger sets `escrow_eligible` from:
   - `status = 'active'`
   - `price_cents >= 5000`
   - `quality_score >= 50`
   - Seller's `user_profiles.kyc_level >= 1`
   - Seller not suspended, no active dispute count > 2 in last 90 days
   - Category is escrow-eligible (excludes services, digital goods — see `categories.escrow_eligible` flag)
3. **DTO** (belengaz): `ListingDto` gains `escrowEligible: bool` (default `false` on deserialization failure — **fail-closed**).
4. **Entity** (pizmam): `ListingEntity.isEscrowAvailable` is a **final field**, not a getter. Default `false`. Tests cover the fail-closed default.
5. **UI** (pizmam): `EscrowBadge` shown only when `listing.isEscrowAvailable && unleash.isEnabled('listings_escrow_badge')`.
6. **Checkout consistency** (reso): Edge Function `create-payment-intent` re-validates `escrow_eligible` at checkout time. If the DB row has flipped since the buyer loaded the listing, return 409 Conflict with an i18n-key error; UI shows a friendly refresh prompt.

### Consequences

#### Positive
- Single source of truth; client and server cannot diverge.
- Audit trail: `escrow_eligible` flips are logged via `audit_log` table (existing infra).
- Server-side update can expand rules without app release.
- Fail-closed default (`false`) means any serialization error hides the badge rather than showing a wrong one.
- Legal defensibility: "badge displayed == row stated eligible at fetch time" is a defensible UI claim.

#### Negative
- Introduces a short-term coupling between pizmam UI PR and reso migration PR. Managed via the merge-dependency graph in `PLAN-pizmam-open-issues.md §6`.
- One extra column, one extra trigger — negligible storage / compute cost.
- Client cannot preview "what-if eligibility" for edit flows; acceptable, listing creation screen can call the same Edge Function helper to preview eligibility.

### Alternatives Considered

1. **Client-side derivation** — rejected: legal risk (see Context).
2. **`GET /functions/v1/listing-escrow-eligibility` batch endpoint** — rejected as long-term architecture: adds N+1 request latency to grid loads; failure modes are harder to reason about. Acceptable as interim if migration lags, but not the target.
3. **Embed eligibility in `listing_view` DB view, keep `listings` table unchanged** — rejected: view cannot be indexed for filter queries; search by "has escrow" becomes slow at scale.

### Rollback

Feature flag `listings_escrow_badge` defaults OFF. If a correctness issue surfaces in production, flag flip (seconds) hides all badges without redeploy. Migration itself is additive (new column with default) — rollback is a follow-up migration setting all values to `false`; zero data loss.
