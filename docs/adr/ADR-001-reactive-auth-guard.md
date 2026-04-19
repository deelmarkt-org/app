# ADR-001 — Reactive Auth Guard with JWT Expiry Check

**Status:** Accepted
**Date:** 2026-04-16
**Author:** pizmam (Frontend/Design)
**Reviewers:** reso (Backend), belengaz (Payments/DevOps)
**Implements:** Issue #118 (Phase 1.4 — post-merge-fixes)
**References:**
- `lib/core/router/app_router.dart:88–124`
- `lib/core/router/auth_guard.dart`
- `lib/core/router/admin_guard.dart`
- `docs/security/threat-model-auth.md`
- OWASP ASVS L2 — V3 Session Management

---

## Context

`app_router.dart` line 98 reads `supabase.auth.currentUser` synchronously in the
GoRouter redirect callback. This is a **stale read**: the GoRouter redirect closure
captures the Supabase client at router-creation time and calls `.currentUser` (the
local cache) rather than deriving user identity from the same auth-state stream that
drives `isLoggedIn`. This creates a **split-brain** window:

```
Stream says: no session  →  isLoggedIn = false
Cache says:  user exists →  currentUser = User{uid: 'abc'}
admin_guard: isAdmin(currentUser) = true  // even though session expired!
```

Additionally, JWT expiry is not verified. A user whose Supabase session token has
expired passes the guard if `authState.valueOrNull?.session != null` — the session
object exists in memory but the JWT itself is expired.

Security threat matrix excerpt (full detail in `docs/security/threat-model-auth.md`):

| Threat | Vector |
|:-------|:-------|
| Privilege persistence | Expired admin JWT still passes `isAdmin()` check |
| Role demotion race | Admin role revoked server-side; client session not yet refreshed |
| Session cache drift | `currentUser` lags behind stream by one event |

---

## Decision

Replace the split-brain `currentUser` stale read with a **unified session derivation**
that sources both `isLoggedIn` and `currentUser` from the same `Session` object, and
adds JWT expiry validation. No `??` fallback between stream-state and local cache.

### New derivation (app_router.dart redirect callback)

```dart
final authState = ref.read(authStateChangesProvider);
final supabase = ref.read(supabaseClientProvider);

// Unified session source — no split between isLoggedIn and currentUser.
// When Supabase has not emitted yet (isLoading), fall back to synchronous
// currentSession (available immediately after Supabase.initialize()).
final Session? session =
    authState.isLoading
        ? supabase.auth.currentSession
        : authState.valueOrNull?.session;

// JWT expiry guard — prevents expired sessions from passing the auth check.
// Session.isExpired is true when expiresAt <= now (supabase_flutter v2+).
final isSessionValid = session != null && !_isSessionExpired(session);
final isLoggedIn = isSessionValid;
final currentUser = isSessionValid ? session.user : null;
```

```dart
bool _isSessionExpired(Session session) {
  if (session.expiresAt == null) return false; // no expiry = long-lived service token
  final expiresAt = DateTime.fromMillisecondsSinceEpoch(
    session.expiresAt! * 1000,
    isUtc: true,
  );
  // Subtract 30s buffer to proactively refresh before hard expiry.
  return DateTime.now().toUtc().isAfter(expiresAt.subtract(const Duration(seconds: 30)));
}
```

### Proactive session refresh scheduling

When the session is within 60 seconds of expiry and still valid, schedule a refresh:

```dart
if (session != null && !isSessionValid == false) {
  final expiresAt = session.expiresAt;
  if (expiresAt != null) {
    final secondsLeft = expiresAt - DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    if (secondsLeft < 60) {
      unawaited(supabase.auth.refreshSession().catchError((e, st) {
        AppLogger.warning('Proactive session refresh failed', tag: 'auth', error: e);
      }));
    }
  }
}
```

### Feature-flag gating

The new guard is gated behind `auth_guard_reactive_enabled` (Unleash feature flag,
`lib/core/config/feature_flags.dart`). When `false`, the router uses the existing
logic (pre-#118). This enables safe canary rollout per §11.2 of the implementation plan.

```dart
final useReactiveGuard =
    ref.read(featureFlagsProvider).isEnabled('auth_guard_reactive_enabled');

final isLoggedIn = useReactiveGuard
    ? isSessionValid
    : (authState.isLoading
        ? supabase.auth.currentSession != null
        : authState.valueOrNull?.session != null);
final currentUser = useReactiveGuard
    ? (isSessionValid ? session?.user : null)
    : supabase.auth.currentUser; // legacy stale read
```

---

## Alternatives Considered

### Option A: Keep `supabase.auth.currentUser` + add expiry check on top

**Rejected.** `currentUser` is still a separate cache read. Even with an expiry check
layered on top, `isLoggedIn` and `currentUser` still have different failure modes:
stream could emit `null` session while cache still has the user object. This is the
split-brain we are eliminating.

### Option B: Use `supabase.auth.currentSession` directly for both

**Rejected for the non-loading branch.** When we have a stream value, we should
use it — the stream is the authoritative reactive source. Bypassing it for the
synchronous cache defeats the purpose of `authStateChangesProvider`.

### Option C: Replace GoRouterRefreshStream with Riverpod-native refreshListenable

**Deferred.** Valid long-term improvement but out of scope for this correctness fix.
Tracked as future `[P]` refactor in `docs/SPRINT-PLAN.md`.

---

## Consequences

### Positive

- Single source of truth for auth state in redirect callback.
- Expired JWTs no longer pass the auth guard.
- Admin role demotion takes effect within one GoRouter refresh cycle (stream event
  fires on next Supabase heartbeat or page focus).
- Proactive refresh reduces the chance of mid-session expiry.

### Negative

- Adds ~10 LOC to redirect callback — partially offset by removing old fallback logic.
- Requires `auth_guard_reactive_enabled` feature flag infrastructure (coordinate with
  belengaz — see Phase D7 open decision).
- `_isSessionExpired` helper must be unit-tested against edge cases:
  `expiresAt = null`, exactly-on-boundary, 29s before expiry, 31s before expiry.

### Risks

| Risk | Mitigation |
|:-----|:-----------|
| Feature flag infrastructure not in place | Implement `lib/core/config/feature_flags.dart` as prerequisite (D6) |
| `session.expiresAt` null for some token types | Guard: `if (session.expiresAt == null) return false` |
| Proactive refresh races with concurrent refresh | `supabase_flutter` deduplicates concurrent refresh calls internally |
| Admin demoted mid-session sees inconsistent UI | Admin panel re-fetches stats on each route push; server RLS blocks unauthorized reads anyway |

---

## Rollback

Disable `auth_guard_reactive_enabled` flag in Unleash dashboard.
Canary SLA: 15 minutes to full rollback.
See `docs/operations/rollback-playbook.md` §Phase-1.4 for step-by-step procedure.

---

## Compliance

- **OWASP ASVS L2 V3.3.1** — Sessions invalidated on logout (covered by Phase 1.11 await fix).
- **OWASP ASVS L2 V3.3.4** — Session tokens not reused after expiry (covered by expiry check here).
- **OWASP ASVS L2 V3.7.1** — Re-authentication required for sensitive actions (admin gate via Phase 1.12).
