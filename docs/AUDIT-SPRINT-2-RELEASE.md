# Sprint 2 Release Audit — Post-Merge Verification

> Created: 2026-04-13 by belengaz
> Status: **COMPLETE**
> Main merge PRs: #139, #142 (dev → main)
> Main HEAD: `fcf0251`

---

## Summary

19 PRs merged to `dev` Apr 10–12, rolled up into `main` via PRs #139 + #142.

| Category | Count |
|----------|-------|
| DELIVERED | 15 |
| DELIVERED WITH ISSUES | 2 (#110, #132) |
| NOT ON MAIN | 1 (#135 — R-29/R-30) |
| MERGE GAP | 1 (#142 — didn't include #135) |

### Action items

| # | Item | Owner | Status |
|---|------|-------|--------|
| 1 | Add `config.toml` entries for `initiate-idin` + `export-user-data` EFs | reso | GitHub issue filed |
| 2 | Create `user-data-exports` storage bucket | reso | GitHub issue filed |
| 3 | Merge R-29/R-30 to main (or defer to Sprint 3) | reso | GitHub issue filed |
| 4 | Schedule pg_cron tasks (iDIN expiry + search outbox) | reso | GitHub issue filed |
| 5 | Correct false "session timeout" claim in PR #110 body | pizmam | GitHub issue filed |
| 6 | Sprint plan: flip R-18, R-21 checkboxes | belengaz | Done in this commit |
| 7 | Verify EF deployments + Vault keys on staging/prod | belengaz | Pending |

---

## Global state on `origin/main`

| Check | Result |
|-------|--------|
| `flutter analyze` | 0 issues |
| `check_quality.dart --all` | 478 files, 0 violations |
| `flutter test` | 3074 tests, all passing |
| EF directories (21) | All present |
| Migrations (32) | All present |
| Routes (`app_router.dart`) | All intact |
| Providers (`repository_providers.dart`) | All registered |
| Parity infra (weights + script) | Intact |
| Tree pollution (`dev/null/`, `.cursor/`) | Clean |

---

## Per-PR verdicts

| PR | Task | Author | Verdict | Key finding |
|----|------|--------|---------|-------------|
| #97 | B-54 shipping routing | belengaz | DELIVERED | All shipping routes intact |
| #98 | R-36 reviews | reso | DELIVERED | Migration + blind review logic present |
| #99 | P-30/P-31 wire | pizmam | DELIVERED | PriceTag + ImageGallery wired, `originalPriceInCents` added |
| #101 | P-32/P-33a escrow | pizmam | DELIVERED | LocationBadge + EscrowTimeline wired |
| #102 | R-37 sanctions | reso | DELIVERED | Migration + entity + repos + provider |
| #103 | R-38 DSA notices | reso | DELIVERED | Migration + entity + repos + provider |
| #105 | R-26/R-27 EFs | belengaz | DELIVERED | Both EFs + parity script intact |
| #106 | R-26/R-27 clients | belengaz | DELIVERED | Services + models + error mapper present |
| #107 | P-41 seller toggle | pizmam | DELIVERED | Auth gate, transaction routing, all design fixes confirmed |
| #110 | P-40 admin Phase A | pizmam | WITH ISSUES | B1/B3/B4 resolved. B2 unresolved: session-timeout claim false |
| #111 | R-27 upload-on-pick | pizmam | DELIVERED | Dedup done, mock gate added, publicId plumbed |
| #112 | Quality fixes | pizmam | DELIVERED | All EFs intact, spec refs present, notifier split clean |
| #132 | R-18/R-21 iDIN+GDPR | reso | PARTIAL | Code present. Missing: config.toml entries, storage bucket |
| #135 | R-29/R-30 outbox | reso | NOT ON MAIN | Migration + EF exist on dev only |
| #136-141 | Fix/sync PRs | various | DELIVERED | kIsWeb guards, l10n, conflict resolution correct |
| #142 | dev-to-main merge | pizmam | GAP | app_router.dart conflict correct; R-29/R-30 not included |

---

## Sprint plan reconciliation

| Task | Expected | Actual | Action |
|------|----------|--------|--------|
| P-40 | [x] | [x] | OK (B2 session-timeout is false but non-blocking) |
| P-41 | [x] | [x] | OK |
| R-18 | [x] | [x] | Fixed in this commit (was unchecked) |
| R-21 | [x] | [x] | Fixed in this commit (was unchecked) |
| R-26 | [x] | [x] | OK |
| R-27 | [x] | [x] | OK |
| R-29 | [ ] | [ ] | Correct — code not on main yet |
| R-30 | [ ] | [ ] | Correct — code not on main yet |
| R-37 | [x] | [x] | OK |
| R-38 | [x] | [x] | OK |
| B-54 | [x] | [x] | OK |

---

## Deployment checklist

| Component | Status | Action |
|-----------|--------|--------|
| EF `image-upload-process` | Code on main | Verify deployed |
| EF `listing-quality-score` | Code on main | Verify deployed |
| EF `initiate-idin` | Code on main | Missing config.toml entry — reso issue |
| EF `export-user-data` | Code on main | Missing config.toml entry — reso issue |
| EF `process-search-outbox` | Not on main | On dev only — reso issue |
| Storage `user-data-exports` | Not configured | reso issue |
| Vault: CLOUDINARY keys | Referenced | Verify in staging/prod |
| Vault: CLOUDMERSIVE_API_KEY | Referenced | Verify in staging/prod |
| Vault: IDIN keys | Referenced in EF | Verify or use mock mode |
| pg_cron: iDIN session expiry | TODO in migration | Schedule after deploy |
| pg_cron: search outbox cron | Documented in EF | After R-29/R-30 on main |
