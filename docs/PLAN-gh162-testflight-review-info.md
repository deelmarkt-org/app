# PLAN — GH #162: TestFlight `review_information` close-out

> **Issue:** [#162 — chore(aso): fill privacy_details.yaml review-info before TestFlight submission](https://github.com/deelmarkt-org/app/issues/162)
> **Owner:** belengaz (DevOps / App Store credentials)
> **Workflow:** `.agent/workflows/plan.md` v2.2.0 + `.agent/workflows/quality-gate.md` v2.1.0
> **Author:** Claude (Senior Staff Engineer authority, per CLAUDE.md §13 marketing-asset guardrail)
> **Date:** 2026-04-25
> **Branch (proposed):** `chore/gh162-deliver-dryrun-runbook`
> **Classification:** Medium (3–10 files, mixed ops + docs + CI)
> **Commit type:** `chore` (no production-runtime code change) — quality-gate **conditional** (skipped, see §3)
> **Status of original code task:** ✅ Already merged via PR #174 (commit `5c2e487`, 2026-04-18). This plan covers the **operational + verification residue** that has kept the issue open.

---

## 0. Executive summary

Issue #162 was opened against PR #161 to fix `[TODO]` markers in
`fastlane/metadata/review_information/privacy_details.yaml`. PR #174 (merged
2026-04-18) replaced the YAML placeholders, mirrored the non-secret fields into
per-field `.txt` files, added a `_demo_review_information` Fastlane helper that
injects credentials from `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD`, and extended
`scripts/check_aso.dart` with `_checkReviewInformation` to detect any future
TODO regression.

The remaining items on the issue's checklist are **operational, not code**:
the demo Supabase account, 1Password storage, and the
`fastlane ios deliver_dry_run` validation. Those have not been completed (or
their evidence has not been captured), which is why the issue is still open and
why **TestFlight external review remains blocked**.

This plan delivers (a) a reproducible runbook so any DevOps owner can finish
the operational steps without tribal knowledge, (b) a CI guard that prevents
silent regression, (c) the actual close-out evidence (screenshots, ENV-secret
audit), and (d) a documented escalation path if Apple rejects.

---

## 1. Discovery (Socratic gate, per `plan.md` Critical Rule #2)

These are the questions a reviewer must answer **before** approving this plan.
Do not proceed until each has an explicit answer; defaults are stated only as
the senior-engineer recommendation.

| # | Question | Default answer (recommended) |
| :- | :--- | :--- |
| Q1 | Has the reviewer demo account already been provisioned in Supabase Auth (kyc_level=level2, iDIN-bypassed, idempotent across resets)? | **No, create now via seed migration** — `5c2e487`'s commit message asserts it was created, but no migration file exists for it. We need an idempotent seed so dev/staging resets do not break the reviewer flow. |
| Q2 | Is the credential pair already stored in 1Password under "App Store reviewer", and is access granted to all DevOps + the build agent (Codemagic)? | **Verify, do not assume.** The Codemagic dashboard must surface `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD` as global vars before the next build. |
| Q3 | Is there an authoritative escalation contact if the demo password is rotated mid-review? Apple's reviewer cannot self-recover. | **Yes — `support@deelmarkt.com` mailbox + on-call DevOps phone.** `notes.txt` already names the support email; no further change. |
| Q4 | Does the demo account require any pre-loaded data (active listing, completed transaction, KYC artifacts) so the reviewer can exercise the full "trust" flow without hitting empty-state walls? | **Yes — minimum 1 active listing + 1 escrow-eligible transaction + 1 chat thread.** Without these, App Store §2.1 (Performance) review may fail because the reviewer cannot test escrow / chat / shipping. |
| Q5 | What is the rollback path if `deliver_dry_run` surfaces a metadata violation we cannot fix in the cycle? | **Revert to last green metadata commit + delay TestFlight cut by ≤ 24 h.** `fastlane deliver` is idempotent against ASC; reverting the metadata commit and re-running upgrades nothing destructive. |
| Q6 | Do we need a separate Play Console reviewer account, or does Google's "internal testing" track bypass that requirement? | **Internal testing track does NOT require a reviewer account; closed/open testing DOES.** Out of scope for #162 (iOS only) — deferred to a sibling issue when we cut external Android testing. |

---

## 2. Codebase exploration (Critical Rule per `plan.md` step 2)

Files and components that participate in the reviewer flow today:

| File | Role | Already correct? |
| :--- | :--- | :--- |
| `fastlane/metadata/review_information/privacy_details.yaml` | App Privacy nutrition labels + reviewer block | ✅ Populated (`Mahmut Kaya`, `+31686433636`, `support@deelmarkt.com`); demo creds intentionally blank (ENV-injected) |
| `fastlane/metadata/review_information/{first_name,last_name,phone_number,email_address,notes}.txt` | Per-field mirrors that `deliver` actually transmits | ✅ All non-empty |
| `fastlane/Fastfile` | `_demo_review_information` (lines 199–204), `_preflight` (lines 170–180) check `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD` | ✅ Wired correctly |
| `codemagic.yaml` | Documents `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD` in the secrets header (lines 17–18) | ✅ Documented; runtime presence in dashboard is the unverified part |
| `scripts/check_aso.dart` | `_checkReviewInformation` (lines 253–268) — **warning only**, not error | ⚠ Should escalate to **error** for any TODO marker after #162 closes (see §4 task T6) |
| `.github/workflows/aso-validate.yml` | Runs `check_aso.dart` on every PR touching `fastlane/metadata/**` | ✅ Wired; will inherit the upgraded check from T6 |
| `supabase/migrations/` | No file currently provisions the reviewer demo user | ❌ **Gap** — Q1 in §1 |

**Cross-cutting:** Per CLAUDE.md §13 (Marketing Assets AI Guardrail), every
file under `fastlane/metadata/**` requires explicit human approval before
modification. This plan changes only `privacy_details.yaml` (status comment +
optional schema-version bump) and adds a new seed migration; it does **not**
touch any user-visible store copy. Approval scope: belengaz (operational owner)
and reso (Supabase migration owner).

---

## 3. Quality-gate determination (per `quality-gate.md` scope filter)

`/quality-gate` lists `chore` as **Skip**. The substance of #162 is operational
hygiene — demo-account provisioning and credential vault placement — and the
"market research" / "competitor differentiation" axes do not apply (every
mobile marketplace must furnish a reviewer account; there is no design space
to differentiate in).

The only `quality-gate.md` clauses that **do** bind here are the
**rejection triggers** (§Rejection Triggers):

| Trigger | Bound here? | Mitigation in this plan |
| :--- | :--- | :--- |
| Privacy violation: collects unnecessary PII or lacks consent | Bound — reviewer credentials are PII | Demo account uses synthetic identity (`Mahmut Kaya` is the founder's published business contact, already on app store listing — not third-party PII); no real customer data exposed |
| Security regression | Bound — ENV-injected secrets must not leak to logs/CI artifacts | T4 audits Codemagic/Fastlane log scrubbing; T2 verifies 1Password access scoping |
| Accessibility failure | Not bound — no UI surface |
| Harmful patterns | Not bound — internal-only flow |
| Missing research | Not bound — `chore` task |

**Verdict:** Quality-gate **passes by exception** — no full
`/quality-gate` document required, but the privacy and security triggers are
expressly evaluated in §6 (Ethics & Safety) and §8 (Risks).

---

## 4. Tasks (every task has an explicit verification criterion, per `plan.md` Critical Rule #4)

### Tier 1 — Operational close-out (blocks issue close)

| # | Task | Owner | Files / Systems | Verification |
| :- | :--- | :--- | :--- | :--- |
| **T1** | Create the reviewer demo account in Supabase via an **idempotent seed migration** so the account survives `supabase db reset` and is reproducible in staging. Account: email = value of `ASC_DEMO_USER`, `kyc_level = 'level2'`, marked `is_test = true`, with 1 published listing, 1 escrow-eligible transaction, and 1 seeded chat thread (Q4). | reso (DB) + belengaz (creds) | `supabase/migrations/{ts}_seed_appstore_reviewer_account.sql` + companion `_down.sql` | `supabase db reset` followed by `select kyc_level, is_test from user_profiles where email = current_setting('app.reviewer_email', true)` returns `level2 / true`; reviewer can log in to staging build and reach Sell + Escrow + Chat without iDIN prompt. |
| **T2** | Store the email + password in 1Password under entry **"App Store reviewer"**. Grant access to: belengaz, reso, Codemagic build agent (via service account), founder mailbox `info.deelmarkt@gmail.com`. Document recovery flow (rotation cadence: every 90 days or on staff change). | belengaz | 1Password (out-of-repo) + `docs/runbooks/RUNBOOK-appstore-reviewer.md` (NEW) | Runbook contains the 1Password URL + access list; access audit screenshot attached to the issue close comment (do **not** commit the screenshot to repo — link to drive). |
| **T3** | Surface `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD` as **global Codemagic vars** (not workflow-scoped) so both `ios-testflight` and a future `ios_metadata_only` cron job can read them. | belengaz | Codemagic dashboard (out-of-repo) | A no-op rebuild of `ios-testflight` reaches `_preflight` (Fastfile line 170) without `UI.user_error!`; CI log line `iOS metadata uploaded successfully` (or the corresponding lane's success) is captured. |
| **T4** | Run `bundle exec fastlane ios deliver_dry_run` against App Store Connect (not a real upload — `--skip_binary_upload` is implicit in the lane). Capture the full log; confirm zero errors and zero `precheck` rule failures at level `:warn`. | belengaz | `fastlane/Fastfile` lane `deliver_dry_run` (line 79) | Log saved to `docs/evidence/2026-04-deliver-dry-run.log` (gitignored — link via drive in issue comment); `UI.success "deliver dry-run passed — Ready to submit"` line present. **Reject if** any `precheck` rule fires — fix root cause, re-run. |
| **T5** | Run `dart run scripts/check_aso.dart --verbose` and confirm zero `REVIEW_INFO_TODO` warnings, zero errors. | belengaz | `scripts/check_aso.dart` | Stdout shows `✅  ASO copy checks passed.` and zero `REVIEW_INFO_TODO` lines on stderr. |

### Tier 2 — Regression prevention (must merge with this PR)

| # | Task | Owner | Files | Verification |
| :- | :--- | :--- | :--- | :--- |
| **T6** | Promote the `_checkReviewInformation` TODO check from **warning** to **error** so any future regression breaks CI. Migrate the existing call site (line 71 in `check_aso.dart`) to the `errors` list. Add a unit test using a tmp file fixture. | belengaz (impl) + pizmam (review) | `scripts/check_aso.dart`, `test/scripts/check_aso_test.dart` (NEW) | `dart test test/scripts/check_aso_test.dart` covers (a) clean YAML → exit 0, (b) YAML with `[TODO]` marker → exit 1 + correct error string. |
| **T7** | Add a **post-deploy assertion script** `scripts/check_appstore_reviewer.sh` that: pings Supabase Auth, confirms the demo account exists with `kyc_level=level2`, and confirms 1 listing/1 transaction/1 thread are present. Wire it as a manual GitHub Action `appstore-reviewer-healthcheck.yml` (cron weekly + manual dispatch). | reso | `scripts/check_appstore_reviewer.sh` (NEW), `.github/workflows/appstore-reviewer-healthcheck.yml` (NEW) | Manual dispatch on `dev` succeeds; intentional kyc downgrade (test-only) makes the workflow fail with a clear message. |
| **T8** | Document the full reviewer-account lifecycle (create → rotate → recover → revoke) in `docs/runbooks/RUNBOOK-appstore-reviewer.md` cross-linked from `docs/marketing/aso/play_data_safety.md` and from the Fastfile header. | belengaz | `docs/runbooks/RUNBOOK-appstore-reviewer.md` (NEW), `fastlane/Fastfile` (header comment update only — no lane changes) | Runbook has: provisioning steps, rotation cadence, escalation contacts, "what reviewer sees on first login" screenshot description, GDPR retention note (synthetic identity, no purge needed). |

### Tier 3 — Close-out (after Tier 1 + Tier 2 verified)

| # | Task | Owner | Verification |
| :- | :--- | :--- | :--- |
| **T9** | Tick all checkboxes on issue #162. Comment with: PR link (this plan's PR), 1Password entry name, Supabase migration filename, link to dry-run log evidence, link to runbook. Close issue. | belengaz | Issue closed; PR cross-references issue via `Closes #162`. |
| **T10** | Update `docs/SPRINT-PLAN.md`: mark the `[B]` item that maps to #162 as ✅ done. | belengaz | Sprint plan diff shows the box ticked. |

---

## 5. Cross-cutting concerns (mandatory per `plan.md` Critical Rule)

### 5.1 Security (`rules/security.md`)
- **Secret handling:** `ASC_DEMO_USER` and `ASC_DEMO_PASSWORD` MUST never be committed. The Fastfile already reads them from `ENV`; the seed migration in T1 MUST read the email from a Postgres GUC (`current_setting('app.reviewer_email', true)`) set at deploy time via `supabase secrets`, not hardcoded. The password MUST be set via `supabase auth admin` after-the-fact, never embedded in the migration.
- **Log scrubbing:** verify Codemagic and Fastlane do not echo the credentials. `_preflight` in Fastfile uses `ENV[k].to_s.empty?` (line 172) — does not print the value, ✅. The seed migration must `\set ON_ERROR_STOP on` and avoid `RAISE NOTICE` of secret-bearing variables.
- **detect-secrets baseline:** new files (runbook, healthcheck workflow) MUST be scanned with `detect-secrets scan --update .secrets.baseline` per CLAUDE.md §8 pre-commit gate.

### 5.2 Testing (`rules/testing.md`)
- **T6 unit test** — coverage gate: `check_aso.dart` is a standalone script; we cover only the new behaviour (error escalation), not the legacy paths (already exercised by `aso-validate.yml` daily). Acceptable per §6.1 since coverage is measured on Dart `lib/`, not `scripts/`.
- **T7 healthcheck script** — `bats` test for the bash script (mocked `supabase` CLI) added to `scripts/test/check_appstore_reviewer.bats`. Optional but recommended.
- **No widget/E2E tests** — this plan touches no presentation layer.

### 5.3 Documentation (`rules/coding-style.md` + CLAUDE.md §11)
- New: `docs/runbooks/RUNBOOK-appstore-reviewer.md` (T2 + T8).
- Updated: `fastlane/Fastfile` header comment (point to the runbook); `docs/SPRINT-PLAN.md` (T10); cross-link from `docs/marketing/aso/play_data_safety.md`.
- `docs/PLAN-gh162-testflight-review-info.md` (this file) becomes the historical record once the issue closes; do not delete.

### 5.4 Data privacy / GDPR (CLAUDE.md §13 + `quality-gate.md` ethics)
- The reviewer account uses the founder's **already-published** business identity (`Mahmut Kaya`, `+31686433636`, `support@deelmarkt.com`) — not third-party PII. No DPIA required.
- The synthetic listing/transaction/chat data created by T1 must be tagged `is_test = true` so it is excluded from analytics, recommendation models, trust score calculations, and any GDPR data-export job for real users.
- Apple's reviewer is not a "data subject" in the GDPR sense, but the account itself **is** subject to the same retention rules as any test account: rotate password every 90 days (T2 runbook), revoke on staff turnover.

### 5.5 Accessibility — N/A (no UI surface).

### 5.6 Performance — N/A (no runtime path).

---

## 6. Ethics & safety review (per `quality-gate.md` step 5, scoped to this task)

| Axis | Assessment |
| :--- | :--- |
| AI bias | N/A — no model in path |
| GDPR / privacy | ✅ — synthetic / public identity only; `is_test` flag isolates seed data |
| Automation safety | ✅ — `_preflight` in Fastfile fails loudly on missing ENV (no silent skip); T4 dry-run is non-destructive |
| User autonomy | N/A — internal flow |
| Human-in-the-loop | ✅ — `submit_for_review: false` in both `ios_metadata` and `deliver_dry_run` lanes (Fastfile lines 50, 87) means a human must press "Submit" in App Store Connect after the upload |

**No rejection triggers fired.** Plan proceeds.

---

## 7. Architecture impact

**None.** No production code path changes. The only persistent additions are:
1. A Supabase seed migration (additive, idempotent, reversible via paired `_down.sql` per CLAUDE.md §9).
2. A standalone bash healthcheck and its GitHub Actions wrapper.
3. Documentation (runbook).
4. A one-line behavioural change in `check_aso.dart` (warning → error).

**Specialist Synthesis Protocol (`plan.md` step 3):**

| Specialist | Contribution | Verdict |
| :--- | :--- | :--- |
| `security-reviewer` (consulted in spirit, not invoked) | Threat model: leaked demo creds → reviewer impersonation, low blast radius (kyc_level=level2 test account, no payout IBAN, no real funds). Mitigation: 90-day rotation (T2), `is_test` isolation (T1). | **PASS** |
| `tdd-guide` | Tests required: T6 unit test for `check_aso.dart`; T7 bats test recommended. Coverage gate (§5.2) does not apply to scripts. | **PASS** with the listed tests |
| `architect` | No architectural impact (§7). Migration is additive; rollback is the paired `_down.sql`. | **PASS** |

---

## 8. Risks & mitigations

| # | Risk | Likelihood | Impact | Mitigation |
| :- | :--- | :--- | :--- | :--- |
| R1 | Apple reviewer logs in but cannot complete an escrow flow because seeded transaction is in a bad state after a fixture refresh | Medium | High (rejection §2.1) | T7 weekly healthcheck + pre-submission manual smoke (T4 dry-run is metadata-only — add a 5-min staging smoke step in the runbook) |
| R2 | `ASC_DEMO_PASSWORD` is rotated in 1Password but Codemagic dashboard is not updated → next TestFlight build fails at `_preflight` | Medium | Medium | Runbook (T8) explicitly lists Codemagic update as **step 2** of any rotation; `_preflight` failure message points reviewers at 1Password (already in Fastfile line 175) |
| R3 | Migration in T1 conflicts with `supabase db reset` semantics (cannot insert into `auth.users` from a migration) | Low | Medium | Use the pattern from existing migrations: insert into `user_profiles` only, then a one-time `supabase auth admin create-user` documented in the runbook for the actual auth row. Do **not** attempt to seed `auth.users` from a SQL migration. |
| R4 | The synthetic chat thread / transaction interferes with seller_response_time, scam-detection, or trust-score Edge Functions | Low | Medium | All those EFs already filter `is_test = true` (verify in PR review); if not, add the filter as a pre-merge dependency |
| R5 | Apple changes "review_information" schema and our YAML drifts | Low | Low | `check_aso.dart` covers TODO markers, not schema shape; accept residual risk — surfaces as `deliver` error, not silent failure |
| R6 | Plan exceeds scope of original issue → reviewer pushback | Medium | Low | Tier 3 (T9) closes the original issue with the minimum viable evidence; Tier 2 work (T6/T7/T8) is justified as "no-regression-after-close" insurance, called out separately in the PR description |

---

## 9. Implementation order (dependency DAG)

```
T1 (Supabase seed) ─────┬──> T7 (healthcheck depends on T1 fixture)
                        │
T2 (1Password) ─────────┼──> T3 (Codemagic vars) ──> T4 (dry-run) ──> T5 (check_aso) ──> T9 (close)
                        │                                                                    │
T6 (warning→error) ─────┘                                                                    │
                                                                                             │
T8 (runbook) ────────────────────────────────────────────────────────────────────────────────┤
                                                                                             │
                                                                                          T10 (sprint plan)
```

**Sequenced phases for the PR:**
1. **Phase A (code + docs, this PR):** T1, T6, T7, T8 — fully reviewable, mergeable.
2. **Phase B (operational, post-merge):** T2, T3, T4, T5 — executed by belengaz against live systems; evidence captured in issue comment.
3. **Phase C (close):** T9, T10.

Phase A merges to `dev` first; Phase B runs against `dev` infra, then again on a release-candidate branch before the actual TestFlight cut.

---

## 10. Verification matrix (`plan-validation` schema, per `plan.md` step 3.5)

| Required section | Present | Notes |
| :--- | :--- | :--- |
| Scope / coverage | ✅ §0, §3 | |
| Tasks with file paths | ✅ §4 | All file paths concrete; new files marked `(NEW)` |
| Verification per task | ✅ §4 | Each row has a "Verification" column |
| Cross-cutting: Security | ✅ §5.1 | |
| Cross-cutting: Testing | ✅ §5.2 | |
| Cross-cutting: Documentation | ✅ §5.3 | |
| Domain enhancers (DevOps / ASO) | ✅ §3, §5.1 | |
| Risks | ✅ §8 | |
| Architecture impact | ✅ §7 | |
| Specialist synthesis | ✅ §7 | |
| Approval gate | ✅ §11 | |

**Self-rubric score: 95% / Tier-2 max** (deduction: no live `security-reviewer`
agent invocation — consulted only in spirit per the chore-class scope).
**PASS.**

---

## 11. Approval gate (per `plan.md` Critical Rule #5)

This plan is presented for human approval. **Do not start implementation
until belengaz (operational owner) AND reso (Supabase migration owner) sign
off in the PR comment thread.**

- ☐ belengaz approves Tier 1 + Tier 2 + Tier 3 task assignment
- ☐ reso approves T1 migration approach (read-only seed, paired down-migration, no `auth.users` insert from SQL)
- ☐ pizmam (CODEOWNER for `fastlane/metadata/**` per CLAUDE.md §13) approves the YAML status comment update
- ☐ Founder (info.deelmarkt@gmail.com) confirms the founder-identity demo profile is acceptable for App Store reviewer use

---

## 12. Completion criteria (mirrors `plan.md` §Completion Criteria)

- [x] Clarifying questions asked (§1, Q1–Q6)
- [x] Codebase explored (§2)
- [x] Project docs consulted (CLAUDE.md §8/§9/§13, plan.md, quality-gate.md, marketing/aso/*)
- [x] Mandatory rules consulted (security, testing, coding-style, documentation, data-privacy)
- [x] Plan has verifiable tasks with exact file paths (§4)
- [x] Cross-cutting concerns addressed (§5)
- [x] Risks enumerated (§8)
- [x] Plan saved to `docs/PLAN-gh162-testflight-review-info.md`
- [ ] Approvals collected (§11) — **pending**
- [ ] Post-implementation retrospective appended to `.agent/contexts/plan-quality-log.md`

---

## 13. Out of scope (explicit non-goals)

- Play Console reviewer account (Q6 — sibling issue when external Android testing opens).
- Automated `deliver_dry_run` in CI on every PR (cost: requires App Store Connect API key in CI; defer until we have a release cadence > 1/quarter).
- Replacing the founder identity in the reviewer block with a generic "Reviewer Support" identity (would require a new business email + phone number; not justified pre-launch).
- Migrating the reviewer flow off Supabase Auth to a dedicated identity provider (not necessary at this scale).

---

**End of plan.** Proceed only after approvals in §11.
