# Rollback Playbook — Post-Merge Fixes (#131, #100, #108, #113)

**Version:** 1.0
**Date:** 2026-04-16
**Author:** pizmam (Frontend/Design)
**Scope:** Phases 0–5 of `docs/PLAN-post-merge-fixes.md`
**On-call owner (Sprint 3):** belengaz (Payments/DevOps)

---

## 1. General Principles

1. **Measure first.** Before reverting, check Crashlytics + Sentry for the error spike origin. A revert that touches auth (Phases 1.4, 1.11, 1.12) will disrupt active sessions — only revert if the impact is confirmed.
2. **Canary rollback first for flagged changes.** Disable the Unleash flag before `git revert` for any phase gated behind a feature flag. This takes effect within 30 s without a deploy.
3. **SLA is time-to-mitigation, not time-to-root-cause.** Mitigation = user impact stopped. Investigation can continue after.
4. **Coordinate on-call.** Tag `@belengaz` in the deploy Slack channel before any revert that touches `dev` or `main`.

---

## 2. Rollback Decision Tree

```
User impact reported?
  │
  ├─ YES: identify phase from Sentry tag or error message
  │         └─ Does phase have a feature flag?
  │                ├─ YES → disable flag first (< 1 min), observe 5 min
  │                │         └─ Impact stopped? → no revert needed, investigate
  │                │         └─ Impact continues → git revert
  │                └─ NO  → git revert immediately
  │
  └─ NO: false alarm, no action needed
```

---

## 3. Per-Phase Rollback Procedures

### Phase 0 — ADR docs

**SLA:** N/A (docs only — no user impact possible)
**Action:** `git revert <sha>` if doc content is incorrect. No deploy needed.

---

### Phase 1.1 — Unread count fix

**Sentry tag:** `tag: 'home'`
**Symptom:** Unread count showing incorrect values (too high or zero)
**SLA:** 30 min

```bash
git revert <phase-1.1-sha>
git push origin dev
# Wait for CI, then notify belengaz to merge
```

**Canary flag:** None — no flag. Straight revert.

---

### Phase 1.2 — Refresh re-entry safety

**Sentry tag:** `tag: 'home'`
**Symptom:** SellerHome frozen, repeated network calls visible in Charles/Sentry
**SLA:** 30 min

```bash
git revert <phase-1.2-sha>
git push origin dev
```

**Test after revert:** Pull-to-refresh on SellerHome completes within 3 s.

---

### Phase 1.3 — secrets.baseline

**Symptom:** CI detect-secrets hook failing unexpectedly
**SLA:** 30 min

```bash
git revert <phase-1.3-sha>
git push origin dev
# Re-run detect-secrets scan to establish new baseline on Linux
```

**Note:** Reverting the baseline does not re-expose any secrets — it only reverts the path annotations.

---

### Phase 1.4 — Reactive auth guard (FEATURE FLAGGED)

**Feature flag:** `auth_guard_reactive_enabled` (Unleash)
**Sentry tag:** `tag: 'auth'`
**Symptom:** Users can't log in, redirect loops, or session incorrectly invalidated
**SLA: 15 min (flag disable) + 30 min (full revert if flag doesn't resolve)**

**Step 1 — Disable flag (< 1 min)**

```
Unleash Dashboard → Feature Flags → auth_guard_reactive_enabled
→ Set enabled: false for ALL environments
```

**Step 2 — Verify (5 min)**

- Crashlytics: auth crash-free rate returns to > 99%
- Manual: sign in with test account, verify redirect works
- Manual: admin login, verify `/admin` accessible

**Step 3 — Git revert (if flag alone doesn't resolve)**

```bash
git revert <phase-1.4-sha>
git push origin dev
```

**Canary schedule (before 100% rollout):**

| Day | Rollout % | Monitor |
|:----|----------:|:--------|
| 1 | 0% (internal only: `@deelmarkt.nl`) | Auth crash-free rate |
| 3 | 10% | Login success rate (threshold: > 99%) |
| 7 | 50% | p95 login latency (threshold: < 2 s) |
| 10 | 100% | — |
| 14 | Remove flag in follow-up PR | — |

---

### Phase 1.5 — Admin use case migration

**Sentry tag:** `tag: 'admin'`
**Symptom:** Admin dashboard fails to load (stats or activity missing)
**SLA:** 30 min

```bash
git revert <phase-1.5-sha>
git push origin dev
# This reverts notifier + GetAdminActivityUseCase + admin_providers.dart
# build_runner regenerates .g.dart on next build
```

**Verify after revert:** Admin dashboard loads stats + activity feed.

---

### Phase 1.6 — Storage orphan cleanup

**Toggle:** Set `STORAGE_ORPHAN_CLEANUP_ENABLED = false` in
`lib/core/config/upload_config.dart` (constant, requires rebuild)

OR fast path:

```bash
git revert <phase-1.6-sha>
git push origin dev
```

**Sentry tag:** `tag: 'sell'`
**Symptom:** Upload cancel throwing errors, orphan-delete Sentry alerts
**SLA:** 60 min (orphans accumulate in bucket but no user-facing impact)

**Note:** Orphaned files are cleaned by a weekly Supabase Storage cron job
(`supabase/functions/storage-cleanup`). Temporary accumulation is harmless.

---

### Phase 1.7 — Publish guard in ViewModel

**Sentry tag:** `tag: 'sell'`
**Symptom:** Listings published with no images, or publish always fails
**SLA:** 30 min

```bash
git revert <phase-1.7-sha>
git push origin dev
```

---

### Phase 1.8–1.10 — Token/tearoff/liveRegion fixes

**Symptom:** Visual regression (wrong opacity colour), tearoff crash, missing Semantics
**SLA:** 30 min each — independent reverts

```bash
git revert <phase-1.8-sha>   # Colors.black26 revert
git revert <phase-1.9-sha>   # liveRegion revert
git revert <phase-1.10-sha>  # tearoff revert
```

---

### Phase 1.11 — Admin signOut await

**Sentry tag:** `tag: 'admin'`
**Symptom:** Admin signOut failing with unhandled exception, logout navigation broken
**SLA:** 15 min

```bash
git revert <phase-1.11-sha>
# Reverts to fire-and-forget signOut — restores pre-fix behaviour
git push origin dev
```

---

### Phase 1.12 — Server-side admin role check (FEATURE FLAGGED)

**Feature flag:** `admin_server_verify_enabled` (Unleash)
**Sentry tag:** `tag: 'admin_security'`
**Symptom:** Legitimate admins blocked from admin panel (false positive), OR
            non-admins not blocked (false negative — more serious)
**SLA:** 30 min

**Step 1 — Disable flag**

```
Unleash Dashboard → admin_server_verify_enabled → Set enabled: false
```

**Step 2 — Verify:** Admin can access dashboard, non-admin redirected to home.

**Step 3 — Git revert if needed:**

```bash
git revert <phase-1.12-client-sha>
# Server-side SQL function remains — coordinate with reso to drop if needed
```

---

### Phase 2 — Design system / a11y

**Symptom:** Visual regression (wrong colours, wrong typography), golden failures in CI
**SLA:** 15 min

```bash
git revert <phase-2-sha>
# Regenerate goldens from pre-Phase-2 baseline if needed
flutter test --update-goldens test/features/admin/
```

---

### Phase 3 — Test coverage

**Impact:** Test-only. No user-facing impact possible.
**SLA:** N/A

```bash
git revert <phase-3-sha>
```

---

### Phase 4 — Polish (#113)

Each item in Phase 4 is independently revertable:

```bash
git revert <phase-4.1-sha>   # dead NewListingFab widget
git revert <phase-4.2-sha>   # HomeSliverAppBar extraction
# ... etc
```

**SLA:** 15 min per item. Visual only.

---

### Phase 5a–5e — SonarCloud refactor

**Symptom:** Behaviour regression from extraction (widget tree changed)
**SLA:** 15 min per sub-PR

```bash
git revert <phase-5a-sha>
# Rerun SonarCloud scan to confirm regression reversal
```

---

## 4. Post-Revert Verification Checklist

After any revert touching auth (1.4, 1.11, 1.12):

- [ ] Staging: sign in with buyer account → reaches `/home`
- [ ] Staging: sign in with admin account → reaches `/admin`
- [ ] Staging: sign out → reaches `/login`
- [ ] Staging: expired session simulation (manually expire token) → redirected to `/login`
- [ ] Crashlytics: auth error rate < 0.1% for 15 min window
- [ ] Sentry: no new `NavigationException` or `AuthException` alerts

After any revert touching sell/upload (1.6, 1.7, 1.8, 1.9, 4.10):

- [ ] Staging: create listing → photo upload completes → publish succeeds
- [ ] Staging: cancel mid-upload → no Sentry error from orphan cleanup

---

## 5. Escalation Path

| Scenario | Contact |
|:---------|:--------|
| Auth revert doesn't resolve issue | reso (backend auth) |
| Storage bucket policy questions | reso (Supabase owner) |
| Unleash flag not responding | belengaz (infrastructure) |
| GDPR-sensitive session data question | belengaz (GDPR sign-off) |
| SonarCloud quality gate still failing | pizmam + CI agent |

---

## 6. Related Documents

- `docs/adr/ADR-001-reactive-auth-guard.md`
- `docs/adr/ADR-002-admin-usecase-layer.md`
- `docs/security/threat-model-auth.md`
- `docs/PLAN-post-merge-fixes.md` §11 (Deployment & Rollback summary)
- `docs/operations/oauth-runbook.md` (OAuth credential rotation)
