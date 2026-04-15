# E02 — User Registration & Progressive KYC

> **Priority:** P0 — Critical | **Phase:** 0–1 (MVP) | **Est. Duration:** 6 weeks

---

## Overview

User registration via Supabase Auth, biometric login, progressive KYC (Levels 0–2 for MVP), user profiles with verification badges, saved addresses for shipping, and GDPR account deletion.

---

## User Stories

### Registration & Auth
- As a new user, I can register with email + phone verification (Level 0)
- As a user, I can log in with biometrics (Face ID / Fingerprint)
- As a user, I can switch between Dutch and English with one tap
- As a user, I can reset my password securely

### Progressive KYC
- As a buyer, I can message sellers after registration (Level 1 — no extra step)
- As a seller, I am prompted for iDIN (or itsme) identity verification when I create my first listing (Level 2)

### Profile & Settings
- As a user, I have a public profile showing verification badges, ratings, and response time
- As a user, I can manage my notification preferences
- As a user, I can add and manage saved addresses (for shipping)
- As a user, I can delete my account and all personal data (GDPR right-to-erasure)

---

## Technical Scope

### Registration & Auth (3 weeks)
- Supabase Auth (email + phone OTP)
- JWT 15-minute access tokens + refresh tokens
- Biometric auth: Face ID / Fingerprint integration
- Rate-limited login attempts
- Password hashing: bcrypt (cost 12) via Supabase Auth
- **All API keys and third-party credentials (iDIN, Mollie, PostNL) stored in Supabase Vault** — no secrets in env vars or source code
- **Social login (P-44):** Google + Apple Sign-In
  - iOS: native `sign_in_with_apple` (ASAuthorizationController) + SHA-256 nonce → `signInWithIdToken`
  - Android: native `google_sign_in` (Play Services) → `signInWithIdToken`; Apple via web sheet fallback
  - Web: `signInWithOAuth` redirect with `onAuthStateChange` listener
  - `user_profiles` row auto-created by `handle_new_auth_user()` trigger on first sign-in
  - OAuth provider enablement + secret rotation: see `docs/operations/oauth-runbook.md`

### Progressive KYC — Levels 0–2 (2 weeks)
- **Level 0:** Email + phone verification → browse, save favourites
- **Level 1:** First message trigger → message sellers, make offers (no extra step)
- **Level 2:** First listing trigger → iDIN **or itsme** bank-based identity verification
  - **iDIN:** Supported by ING, Rabobank, ABN AMRO — primary for Dutch users
  - **itsme:** Popular with younger Dutch users and Belgian users (relevant given Bancontact/Belgium scope)
  - User is offered whichever provider their bank supports; falls back to the other if unavailable
- Verification badge system on user profiles
- KYC state machine with clear transitions
- `kyc_level` column in users table referenced by RLS policies

### Profile, Addresses & GDPR (1 week)
- Public profile page: badges, ratings, member since, response time
- Saved addresses table (postcode, huisnummer, toevoeging, city)
- Account deletion Edge Function: async PII deletion within 30 days, audit log preserved
- Data export endpoint (JSON) for GDPR portability

### Phase 2 Additions
- **Level 3:** First escrow transaction → Onfido selfie + document verification
- **Level 4:** Monthly €2,500+ sales → KVK number + KYBC verification

---

## Acceptance Criteria

- [ ] Registration flow works end-to-end (email + phone OTP)
- [ ] Biometric login works on iOS (Face ID) and Android (Fingerprint)
- [ ] Google Sign-In works on iOS, Android, and Web (native flow on mobile, redirect on web)
- [ ] Apple Sign-In works on iOS (native sheet per Apple HIG — never via WebView for App Review compliance)
- [ ] `user_profiles` row auto-created on first OAuth sign-in via `handle_new_auth_user()` trigger
- [ ] Apple `@privaterelay.appleid.com` emails accepted (email_optional=true)
- [ ] Cancelled OAuth sign-ins are silent (no error SnackBar)
- [ ] OAuth provider-disabled errors surface `auth.oauthUnavailable` with email fallback CTA
- [ ] iDIN verification triggers on first listing creation
- [ ] itsme is offered as an alternative when triggered for Level 2 KYC
- [ ] Verification badges display correctly on profiles
- [ ] JWT tokens refresh correctly without user disruption
- [ ] RLS policies enforce access based on `kyc_level`
- [ ] Saved addresses CRUD works
- [ ] Account deletion removes all PII within 30 days
- [ ] NL/EN language switch works throughout auth flows
- [ ] All third-party credentials stored in Supabase Vault — confirmed by code review (no secrets in env vars)
- [ ] ≥70% test coverage

---

## Dependencies

- **E07** (Infrastructure) — Supabase project setup, Supabase Vault
- iDIN provider contract (primary)
- itsme provider contract (secondary, for Phase 1 or early Phase 2)
