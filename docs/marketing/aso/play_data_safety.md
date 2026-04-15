# Play Console Data Safety Form — DeelMarkt

> Source of truth for the Play Console Data Safety section.
> This form must be **manually entered** in the Play Console — Google does not support
> automated submission via `supply`. Update here first, then mirror in Console.
>
> Last reviewed: 2026-04-15 (pizmam)

---

## Does your app collect or share any of the required user data types?

**Yes** — see categories below.

## Is all of the data that your app collects encrypted in transit?

**Yes** — all data uses HTTPS (TLS 1.3). Supabase enforces TLS on all connections.

## Do you provide a way for users to request that their data is deleted?

**Yes** — in-app account deletion at Settings → Account → Delete account.
This triggers a soft-delete in Supabase with hard-delete after 30 days (GDPR compliance).

---

## Data Types

### Personal info

| Data type | Collected | Shared | Required | Prominent disclosure |
|-----------|-----------|--------|----------|---------------------|
| Name | ✅ | ❌ | Required | No |
| Email address | ✅ | ❌ | Required | No |
| Phone number | ✅ Optional | ❌ | Optional (2FA) | No |

**Purpose:** Account management, transaction notifications, KYC via iDIN.

### Financial info

| Data type | Collected | Shared | Required | Prominent disclosure |
|-----------|-----------|--------|----------|---------------------|
| Purchase history | ✅ | ❌ | Required | No |
| Payment info | ✅ (reference only) | With Mollie (PSP) | Required | No |

**Purpose:** Escrow payment processing, payout to sellers.
**Note:** Raw payment card data is NEVER collected by the app. Mollie processes payments
under their PSD2 licence. We store only payment status + Mollie reference ID.

### Location

| Data type | Collected | Shared | Required | Prominent disclosure |
|-----------|-----------|--------|----------|---------------------|
| Approximate location | ✅ (postal code) | ❌ | Optional | No |

**Purpose:** Nearby listings feature — postal code entered by user, not GPS.

### App activity

| Data type | Collected | Shared | Required | Prominent disclosure |
|-----------|-----------|--------|----------|---------------------|
| App interactions | ✅ (anonymous) | ❌ | No | No |

**Purpose:** Anonymous usage analytics for feature improvement.

### App info and performance

| Data type | Collected | Shared | Required | Prominent disclosure |
|-----------|-----------|--------|----------|---------------------|
| Crash logs | ✅ | With Sentry (processor) | No | No |
| Diagnostics | ✅ | With Sentry | No | No |

**Purpose:** Crash reporting via Sentry. PII excluded from stack traces via Sentry config.

---

## User control

| Feature | Implemented |
|---------|-------------|
| Users can request deletion | ✅ In-app |
| Users can opt out of analytics | ⚠️ Not yet (v1.0) — planned v1.1 |
| Users can export their data | ⚠️ Not yet (v1.0) — GDPR DSR via email support |

---

## Update History

| Date | Change | Reviewer |
|------|--------|----------|
| 2026-04-15 | Initial form | pizmam |
