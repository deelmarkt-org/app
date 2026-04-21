# Feature Flags Registry

> Managed via Unleash (self-hosted). All flags default **OFF** in production.
> Changes to this file must be co-reviewed by pizmam + product (for trust signals: + legal).
> Rollout procedure: dev 100% → internal 10% → beta 50% → prod 100%.

## Active Flags

| Flag key | Feature | Added | Owner | Prod status | Kill criteria |
|:---------|:--------|:------|:------|:------------|:--------------|
| `listings_escrow_badge` | EscrowBadge on listing cards (issue #59, ADR-023) | 2026-04-17 | pizmam + product | OFF in prod — staged rollout after PR-B migration + PR-C UI land in staging (dev 100% → staging 100% → prod 10% canary → prod 100%) | checkout 409 rate > 2% OR badge accuracy complaint |

## Rollout Log

| Flag | Date | Action | Approver |
|:-----|:-----|:-------|:---------|
| `listings_escrow_badge` | 2026-04-17 | Registered, default OFF | pizmam |
| `listings_escrow_badge` | 2026-04-20 | Wired into `EscrowAwareListingCard` via `FeatureFlags.listingsEscrowBadge` constant (GH-59 PR-C); stays OFF in prod until staging QA passes per plan §4.4 | pizmam |

## Governance

- All trust-signal flags (escrow, KYC badges, verification marks) require legal sign-off before exceeding 10% rollout. See `docs/COMPLIANCE.md`.
- Feature flags must NOT be used to hide incomplete features in production builds shipped to app stores — use build-time compile guards instead.
- Stale flags (> 6 months with no rollout progress) are removed in the next sprint planning.
