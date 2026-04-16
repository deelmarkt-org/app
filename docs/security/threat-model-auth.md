# Threat Model — Authentication & Session Management

**Version:** 1.0
**Date:** 2026-04-16
**Author:** pizmam (Frontend/Design)
**Review required:** reso (Backend), belengaz (Payments/DevOps — GDPR sign-off)
**Scope:** Flutter client auth flows + GoRouter guard + Admin access control
**Framework:** STRIDE (Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege)
**Standard:** OWASP ASVS Level 2 — V3 Session Management, V4 Access Control

---

## 1. System Components in Scope

```
┌─────────────────────────────────────────────────────┐
│                  Flutter Client                     │
│                                                     │
│  GoRouter                                           │
│  ├── redirect callback                              │
│  │    ├── authStateChangesProvider (stream)         │
│  │    ├── supabase.auth.currentSession (cache)      │
│  │    └── admin_guard.isAdmin(currentUser)          │
│  └── refreshListenable (GoRouterRefreshStream)      │
│                                                     │
│  AdminDashboardNotifier                             │
│  └── calls repo directly (bypasses use cases) ❌   │
│                                                     │
│  AdminShellScreen                                   │
│  └── signOut() — fire-and-forget ❌                │
└────────────────────────┬────────────────────────────┘
                         │ Supabase JWT (HTTPS)
┌────────────────────────▼────────────────────────────┐
│              Supabase (Backend)                     │
│  ├── Auth: JWT issuance, refresh, revocation        │
│  ├── RLS: row-level security on all tables          │
│  ├── app_metadata.role: 'admin' (service-role only) │
│  └── SECURITY DEFINER function: public.is_admin()  │
│       (Phase 1.12 — not yet deployed)              │
└─────────────────────────────────────────────────────┘
```

---

## 2. Trust Boundaries

| Boundary | Direction | Controls |
|:---------|:----------|:---------|
| User ↔ Flutter client | Input | Input validation, Zod (Edge Functions) |
| Flutter client ↔ Supabase Auth | Network | HTTPS/TLS 1.3, JWT, Supabase Row-Level Security |
| Flutter client ↔ Supabase Storage | Network | HTTPS/TLS 1.3, bucket RLS (`auth.uid() = owner`) |
| Service role ↔ `app_metadata` | Internal | Service-role-only RPC (`set_admin_role`) |
| GoRouter guard ↔ `app_metadata` | Client-side | Currently client-only ❌ — Phase 1.12 adds server check |

---

## 3. STRIDE Threat Analysis

### 3.1 Spoofing (Identity)

| ID | Threat | Component | Likelihood | Impact | Status | Mitigation |
|:---|:-------|:----------|:----------:|:------:|:------:|:-----------|
| S1 | Attacker sets `app_metadata.role = 'admin'` via crafted JWT | `admin_guard.isAdmin()` reads `user.appMetadata` client-side | LOW | CRITICAL | ⚠️ Partial | `app_metadata` is writable only via service-role RPC. Phase 1.12 adds server-side `public.is_admin()` SECURITY DEFINER verification |
| S2 | Replay attack using stolen JWT after logout | GoRouter, Supabase | LOW | HIGH | ✅ Mitigated | Supabase invalidates tokens on `signOut()`. Phase 1.11 ensures await before navigation closes the race window |
| S3 | Concurrent session from second device after password change | Supabase Auth | LOW | HIGH | ✅ Mitigated | Supabase `signOut(scope: 'global')` revokes all sessions (use in security-sensitive reset flows) |

### 3.2 Tampering (Integrity)

| ID | Threat | Component | Likelihood | Impact | Status | Mitigation |
|:---|:-------|:----------|:----------:|:------:|:------:|:-----------|
| T1 | Man-in-the-middle intercept of JWT | Network layer | VERY LOW | CRITICAL | ✅ Mitigated | HTTPS/TLS 1.3 enforced; Cloudflare WAF; certificate pinning considered for future |
| T2 | Stale `currentUser` cache reflects tampered/deleted user | `supabase.auth.currentUser` | LOW | MEDIUM | ⚠️ Fixed by Phase 1.4 | Replace stale-read with `session.user` derived from validated session |
| T3 | Orphaned files in Storage if upload cancellation not handled | ImageUploadService | MEDIUM | LOW | ⚠️ Fixed by Phase 1.6 | State machine: delete orphan only when upload completed but processing not completed |

### 3.3 Repudiation (Non-repudiation)

| ID | Threat | Component | Likelihood | Impact | Status | Mitigation |
|:---|:-------|:----------|:----------:|:------:|:------:|:-----------|
| R1 | Admin action (ban user, remove listing) with no audit trail | AdminDashboardNotifier | HIGH | HIGH | ⚠️ Partial | DSA Article 24 requires server-side audit log. Phase 1.12 ADR documents requirement; reso implements `admin_audit_log` table in future [R] epic |
| R2 | signOut race: user navigates away before signOut completes | AdminShellScreen | MEDIUM | LOW | ⚠️ Fixed by Phase 1.11 | `await signOut()` before `context.go(AppRoutes.login)` |

### 3.4 Information Disclosure

| ID | Threat | Component | Likelihood | Impact | Status | Mitigation |
|:---|:-------|:----------|:----------:|:------:|:------:|:-----------|
| I1 | Expired JWT passes auth guard, user sees protected data | GoRouter redirect | MEDIUM | HIGH | ⚠️ Fixed by Phase 1.4 | `_isSessionExpired()` check; session validated before `isLoggedIn = true` |
| I2 | Admin dashboard data visible after admin role revoked | GoRouter, AdminDashboardNotifier | LOW | HIGH | ⚠️ Partial | Server RLS blocks unauthorized reads (defense-in-depth); Phase 1.12 client check reduces latency of detection |
| I3 | Hardcoded secrets in `.secrets.baseline` or codebase | CI/CD pipeline | LOW | CRITICAL | ⚠️ Fixed by Phase 1.3 | `detect-secrets scan --update` on Linux; pre-commit guard for Windows paths; explicit inclusion of `supabase/` |
| I4 | User PII logged in error messages | AppLogger (all layers) | LOW | MEDIUM | ✅ Policy | Log user ID hash only (never email, name, full UID). Reviewed in Phase 1 cross-cutting concerns |
| I5 | Storage bucket accessible without user-ownership check | Supabase Storage | LOW | HIGH | ⚠️ Verify | Phase 1.6 verifies bucket RLS policy enforces `auth.uid()::text = split_part(name, '/', 1)` |

### 3.5 Denial of Service

| ID | Threat | Component | Likelihood | Impact | Status | Mitigation |
|:---|:-------|:----------|:----------:|:------:|:------:|:-----------|
| D1 | Rapid repeated `refresh()` calls creating duplicate subscriptions | SellerHomeNotifier | MEDIUM | LOW | ⚠️ Fixed by Phase 1.2 | `_fetchFor` helper pattern; `refresh()` reads resolved values without creating new subscriptions |
| D2 | Image upload queue filled with stuck jobs due to missing backoff for HTTP 429 | PhotoUploadQueue | LOW | LOW | ⚠️ Fixed by Phase 4.10 | Thread `statusCode` through; 429 → `max(delayMs, 2000)` minimum backoff |
| D3 | Admin dashboard floods backend with parallel requests on each navigation | AdminDashboardNotifier | LOW | LOW | ✅ Mitigated | `@riverpod` keeps single notifier alive per `ProviderContainer`; `.wait` parallelises only 2 calls |

### 3.6 Elevation of Privilege

| ID | Threat | Component | Likelihood | Impact | Status | Mitigation |
|:---|:-------|:----------|:----------:|:------:|:------:|:-----------|
| E1 | Attacker edits JWT `app_metadata` to gain admin access | `admin_guard.isAdmin()` | LOW | CRITICAL | ⚠️ Phase 1.12 | Client-side check is supplemental only. Server: SECURITY DEFINER `public.is_admin()` must be authoritative. RLS policies must not rely solely on `app_metadata` |
| E2 | Non-admin user navigates to `/admin` after deep link | GoRouter redirect | LOW | HIGH | ✅ Mitigated | `authRedirect` checks `isAdmin` on every navigation via `refreshListenable` |
| E3 | Session persists after suspension lifted + admin role revoked in same operation | GoRouter, `activeSanctionProvider` | LOW | MEDIUM | ✅ Mitigated | `sanctionNotifier.ping()` triggers redirect re-evaluation; RLS is authoritative backend |
| E4 | Stale session allows navigation to protected screen after `signOut()` called | GoRouter | MEDIUM | HIGH | ⚠️ Fixed by Phase 1.4 | Await signOut (1.11) + reactive session derivation (1.4) closes race window |

---

## 4. Attack Surface Summary

| Surface | Exposure | Priority |
|:--------|:---------|:---------|
| GoRouter redirect callback | Derived `isLoggedIn` from split-brain cache | 🔴 HIGH — Fix Phase 1.4 |
| `admin_guard.isAdmin()` | Client-side only — no server check | 🔴 HIGH — Fix Phase 1.12 |
| `AdminShellScreen.signOut()` | Fire-and-forget | 🔴 HIGH — Fix Phase 1.11 |
| `ImageUploadService` orphan cleanup | No cleanup on cancel | 🟡 MEDIUM — Fix Phase 1.6 |
| `.secrets.baseline` | Windows backslash paths + missing scope | 🟡 MEDIUM — Fix Phase 1.3 |
| Storage bucket RLS | Unverified policy | 🟡 MEDIUM — Verify Phase 1.6 |
| Admin audit trail | No DSA Art 24 logging | 🟡 MEDIUM — Future [R] epic |

---

## 5. Security Controls Inventory

| Control | Type | Layer | Status |
|:--------|:-----|:------|:-------|
| HTTPS/TLS 1.3 | Preventive | Network | ✅ Active |
| Supabase JWT | Preventive | Auth | ✅ Active |
| RLS on all tables | Preventive | Database | ✅ Active (verified in each migration) |
| `detect-secrets` pre-commit hook | Detective | CI | ⚠️ Phase 1.3 fix |
| GoRouter reactive session check | Preventive | Presentation | ⚠️ Phase 1.4 fix |
| Admin server-side role check | Preventive | Domain | ⚠️ Phase 1.12 new |
| Admin signOut await | Preventive | Presentation | ⚠️ Phase 1.11 fix |
| Storage bucket ownership RLS | Preventive | Storage | ⚠️ Phase 1.6 verify |
| AppLogger PII redaction | Detective | All layers | ✅ Policy (no enforcement) |
| DSA Article 24 audit log | Accountability | Database | ⚠️ Future [R] epic |

---

## 6. Residual Risks (accepted after mitigations)

| ID | Residual Risk | Rationale for Acceptance |
|:---|:-------------|:--------------------------|
| R-1 | Certificate pinning not implemented | Out of scope for MVP; Cloudflare WAF + HSTS provides sufficient protection at current scale |
| R-2 | `app_metadata` client-side admin check still present as fallback | Server-side check (1.12) is primary; client check reduces latency for legitimate users. Supabase service-role-only write enforces integrity |
| R-3 | No rate limiting on admin dashboard refresh | Admin is a single operator; DoS from external is blocked at RLS/network layer |

---

## 7. Review & Sign-off

| Reviewer | Role | Date | Signature |
|:---------|:-----|:-----|:----------|
| pizmam | Frontend author | 2026-04-16 | ✅ |
| reso | Backend / Supabase | _pending_ | ⬜ |
| belengaz | DevOps / GDPR | _pending_ | ⬜ |

> **Note:** reso sign-off required before Phase 1.12 (server-side `public.is_admin()`) can be merged.
> belengaz sign-off required before Phase 1.11 (signOut race) is considered GDPR-compliant for session data.
