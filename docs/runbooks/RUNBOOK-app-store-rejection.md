# RUNBOOK — App Store / Play Store rejection response

> **Owner:** belengaz (DevOps / Store submission)
> **Backup owner:** pizmam (UI / ASO copy + screenshots)
> **Last reviewed:** 2026-04-30
> **Next scheduled review:** 2026-07-30 (90-day cadence)
> **Severity classification:** SEV-1 (production submission rejected, customer-facing release blocked) · SEV-2 (TestFlight / internal-test rejection) · SEV-3 (informational guideline reference, no rejection yet)
> **Source of truth for code:** `fastlane/metadata/**` · ASO: `scripts/check_aso.dart` · review fixture: [`RUNBOOK-appstore-reviewer.md`](RUNBOOK-appstore-reviewer.md)

This runbook is the **authoritative response procedure** when Apple App Review or Google Play Console rejects a DeelMarkt submission. Closes Tier-1 retrospective B-68 (5 of 5).

A rejection is not a "bug" — it's a binary block on the customer-facing release. Average cycle delay is **24-72 hours per round trip**. The right response shape depends entirely on the **rejection class** (which Apple / Google rule was cited).

---

## 1. What this runbook covers

```
Submission paths:
  ├── iOS App Store
  │   ├── TestFlight external review (informal, fast)
  │   └── App Store production review (App Review §2.1, §4.0, §5.1.1, §5.1.6)
  └── Google Play Console
      ├── Internal testing (no review)
      ├── Closed testing (light review)
      ├── Open testing (full policy review)
      └── Production (full policy review)
```

Reference: `docs/PLAN-gh162-testflight-review-info.md` (Phase A code) · `RUNBOOK-appstore-reviewer.md` (demo account) · CLAUDE.md §13 (marketing-asset hard-gate) · §14 (App Store reviewer fixture).

---

## 2. Symptoms (how this surfaces)

| Symptom | Likely severity | First check |
|:---|:---|:---|
| App Store Connect email: "Your submission requires modifications" + guideline reference | **SEV-1** if production, SEV-2 if TestFlight | Read the guideline reference (§3.1) |
| Play Console policy email: "Your app has been removed/rejected" + policy reference | **SEV-1** | Same |
| Apple "Metadata rejection" (no binary needed; copy/screenshot fix) | **SEV-2** (faster cycle) | `fastlane/metadata/**` review |
| Apple "Binary rejection" (crash, broken flow, demo account fails) | **SEV-1** | Reproduce locally |
| Play Console policy strike (account-wide flag, not just app) | **SEV-1** | Account-level review |
| Reviewer cannot log in / demo account broken | **SEV-1** | Cross-reference [`RUNBOOK-appstore-reviewer.md`](RUNBOOK-appstore-reviewer.md) |
| Review delay > 72h with no communication | **SEV-2** (likely informational) | Check App Store Connect / Play Console status |
| Apple "Expedited review request" needed | **SEV-1** path | (decision to escalate) |

If you receive a rejection notice, treat as **SEV-2 by default** and escalate to SEV-1 if §3.2 classifies the cause as binary / privacy / security.

---

## 3. Triage (do this first, before mitigation)

### 3.1 Read the rejection notice fully

Apple emails include:
- **Guideline reference** (e.g. "Guideline 4.0 - Design")
- **Verbatim quote** from the reviewer
- **Screenshots** of the offending screen (sometimes)
- **Reviewer's reproduction steps**

Play Console policy notices include:
- **Policy reference** (e.g. "User Data policy / Permissions")
- **Specific app section** that violates
- **Required action**

**Hard rule:** read the FULL notice, including any attached PDF or screenshots, before classifying. Misclassification doubles cycle time.

### 3.2 Classify the rejection class

| Apple guideline / Play policy | Class | Skip to | Severity |
|:---|:---|:---|:---|
| Apple §2.1 "Performance" — crashes, broken core flow | Binary / behaviour | §4.1 | SEV-1 |
| Apple §4.0 "Design" — UX, layout, navigation | UI/UX | §4.2 | SEV-2 |
| Apple §5.1.1 "Privacy — Data Collection" | Privacy labels | §4.3 | SEV-1 (legal) |
| Apple §5.1.6 "Third-party SDK" | SBOM / SDK transparency | §4.4 | SEV-2 |
| Apple §5.1 demo account broken | Reviewer fixture | §4.5 | SEV-1 |
| Apple §2.3.7 / §2.3.10 "Accurate metadata / keyword stuffing" | ASO copy | §4.6 | SEV-2 |
| Play "User Data" policy | Privacy labels (Play side) | §4.3 + §4.7 | SEV-1 (legal) |
| Play "Permissions" policy | Manifest permissions | §4.8 | SEV-1 |
| Play "Restricted Content" policy | Content scope | §4.9 | SEV-2 |
| Play "Deceptive Behavior" | ASO copy / UX | §4.6 | SEV-2 |

If the rejection cites a guideline not in the table, treat as SEV-2 and engage incident commander.

### 3.3 Snapshot the impact

```
- What was being submitted (build number, version, platform)
- Original release-notes commitments (was this a critical fix?)
- Cycle delay risk (Apple median 24-48h, Play 4-12h)
- Customer commitment (any release-date promises in marketing or to users?)
```

Write the snapshot in the incident channel.

---

## 4. Mitigation by rejection class

### 4.1 §2.1 Performance — crashes / broken flow

**Cause:** Reviewer hit a crash or broken UX flow during evaluation.

**Mitigation:**

1. Reproduce the crash locally on the same device class and OS version the reviewer used (the rejection notice usually identifies the device).
2. If reproducible: hotfix branch off `main` → fix → merge → new build → submit.
3. If not reproducible: request additional info from Apple via App Store Connect message; provide test account credentials + reproduction steps; ask reviewer to retry.
4. **Coordinate with reso/belengaz** if the crash is in payment / Edge Function path — backend fix may be needed.
5. After resubmission, monitor Sentry for the same crash signature in production traffic; if it's a real customer-facing bug, the cycle time is justified.

### 4.2 §4.0 Design — UX / layout

**Cause:** Reviewer found a UX issue (touch target too small, navigation dead end, accessibility issue).

**Mitigation:**

1. Identify the screen + variant (light / dark, language).
2. Engage pizmam if the fix is presentation-layer.
3. Cross-check against `docs/screens/` spec — was the spec followed?
4. Apply fix → new build → resubmit.
5. **Hard rule:** do not fix the symptom on one screen if the same pattern affects others. Apple may re-reject if a sibling screen has the same issue.

### 4.3 §5.1.1 Privacy — Data Collection (legal class — SEV-1)

**Cause:** Apple privacy nutrition labels (`fastlane/metadata/review_information/privacy_details.yaml`) under-declare or incorrectly declare data collection. This is a legal compliance issue under GDPR + Apple's privacy framework.

**Mitigation:**

1. **Engage incident commander** (founder + reso). This is GDPR-adjacent — sign-off authority required.
2. Read the rejection notice's specific data category Apple flagged (e.g. "your app collects email but does not declare it under Contact Info").
3. Audit the actual collection in `lib/`, `supabase/functions/`, and dependencies via SBOM (B-60).
4. Update `privacy_details.yaml` with the missing declaration. **CLAUDE.md §13 hard-gate** — requires reso/belengaz GDPR sign-off in PR review.
5. New submission with updated metadata. Apple's metadata-only rejection cycle is faster (no binary rebuild required).
6. **GDPR follow-up:** if the under-declaration also implies users were not properly notified of the collection, a data-subject rights review may be warranted. Coordinate with reso.

### 4.4 §5.1.6 Third-party SDK — transparency

**Cause:** Apple wants disclosure of third-party SDKs and their data practices. SBOM (B-60) is the underlying artifact.

**Mitigation:**

1. Run `pana` license + SBOM check (post-B-60).
2. Verify each third-party SDK in `pubspec.lock` is declared correctly in `privacy_details.yaml`.
3. Update `privacy_details.yaml` if drift found.
4. New submission. Same as §4.3 cycle time.

### 4.5 §5.1 Demo account broken

**Cause:** Apple reviewer cannot log into the demo account, or the account's pre-loaded data is incomplete (no listing, no transaction, no chat).

**Mitigation:**

1. **Cross-reference [`RUNBOOK-appstore-reviewer.md`](RUNBOOK-appstore-reviewer.md) §Recovery.** This runbook is its sibling.
2. Verify `appstore-reviewer-healthcheck.yml` workflow is green; if red, fix per §14 + RUNBOOK-supabase-rls-regression.md §4.4.
3. Verify `ASC_DEMO_USER` / `ASC_DEMO_PASSWORD` in Codemagic match what's been provisioned.
4. Provide updated credentials via App Store Connect message; ask reviewer to retry.
5. **Do not rotate the password mid-review** unless absolutely necessary — the reviewer may have copied it; rotation breaks their flow.

### 4.6 §2.3.7 / §2.3.10 ASO copy / keyword stuffing

**Cause:** Apple flagged ASO copy as inaccurate or keyword-stuffed.

**Mitigation:**

1. Pizmam reviews `fastlane/metadata/<locale>/{description,keywords,subtitle}.txt`.
2. Run `dart run scripts/check_aso.dart` — should already enforce char budgets. If new fails post-Apple-rejection, the ASO check needs tightening (open issue).
3. Cross-reference each claim against `docs/marketing/aso/claims_ledger.md` (CLAUDE.md §13). Remove any unsupported claims.
4. Re-submit metadata-only.

### 4.7 Play User Data policy

**Cause:** Play Console flagged data collection without proper Data Safety form or in-app disclosure.

**Mitigation:**

1. Update `docs/marketing/aso/play_data_safety.md` to match actual collection.
2. Re-fill the Play Console Data Safety form via dashboard (manual step).
3. Re-submit. Play's review cycle is 4-12h typically; faster than Apple.

### 4.8 Play Permissions policy

**Cause:** AndroidManifest declares a permission Play considers high-risk without proper justification (e.g. SMS, Call Log, Location-Background).

**Mitigation:**

1. Audit `android/app/src/main/AndroidManifest.xml`.
2. Remove the unjustified permission OR file a Permission Declaration form via Play Console with justification.
3. Re-submit.

### 4.9 Play Restricted Content / Deceptive Behavior

**Cause:** Play flagged content claims (e.g. "free returns") that aren't accurate, or marketplace-class content that needs additional disclosures.

**Mitigation:**

1. Same shape as §4.6.
2. May require Play-specific disclosure additions in store listing description.

---

## 5. Verification (after mitigation)

Mitigation is not complete until **all** of the following hold:

- [ ] Re-submission accepted by Apple App Store Connect / Play Console
- [ ] `dart run scripts/check_aso.dart` exits 0 in both locales
- [ ] `bash scripts/check_screenshots.sh` exits 0
- [ ] `bash scripts/check_appstore_reviewer.sh` exits 0 (if §4.5 was the cause)
- [ ] If `privacy_details.yaml` was edited: reso/belengaz GDPR sign-off recorded in the merge commit
- [ ] CHANGELOG entry under the release that shipped the fix
- [ ] PagerDuty incident closed with a resolution comment linking back to the §3.2 rejection class
- [ ] If §4.3 / §4.7 (privacy class): legal/compliance review checklist updated

---

## 6. Communication (during the incident)

| Audience | Channel | When |
|:---|:---|:---|
| Engineering team | `#payments-incidents` Slack | At rejection notice receipt, every 6h until re-submission, on resolution |
| Founder + belengaz | DM | Immediately on SEV-1 rejection (production submission blocked) |
| Pizmam (UI / ASO) | DM | If §4.2 / §4.6 — UI or copy fix needed |
| Reso (GDPR sign-off) | DM | If §4.3 / §4.7 — privacy declarations affected |
| Marketing / external comms (if any) | Per founder | If a release-date promise needs adjustment |
| Apple App Review | App Store Connect message | For clarification questions, or to provide additional info |
| Play Console | Console message | Same |
| Status page | DeelMarkt status page | Only if release was customer-promised; phrase generically ("update delayed") |
| Regulator (DPA) | GDPR Art. 33 if applicable | Only if §4.3 reveals a confirmed under-collection notification gap |

**Hard rule:** do not commit to a re-submission timeline before §3.3 impact snapshot is reviewed; Apple cycle times are 24-72h regardless of how fast we submit the fix.

---

## 7. Post-incident (within 5 business days)

- File a retrospective in `docs/audits/` named `INCIDENT-store-rejection-<YYYY-MM-DD>.md`
- Action items become GitHub issues; specifically:
  - If §4.3 / §4.7 — open a CI guard issue: pre-submit privacy-labels lint that runs `pana` + diffs against shipped declarations
  - If §4.2 — open a UX regression issue if the same flaw affects multiple screens
  - If §4.5 — review reviewer-fixture rotation cadence (CLAUDE.md §14 90-day cadence — was it skipped?)
- Update this runbook if the rejection class was new
- Update `docs/marketing/aso/claims_ledger.md` if any claim was removed

---

## 8. Escalation contacts

| Role | Who | Channel |
|:---|:---|:---|
| Primary owner (DevOps + submission) | belengaz (`@mahmutkaya`) | Slack DM, PagerDuty primary |
| Backup owner (UI + ASO copy) | pizmam (`@emredursun`) | Slack DM, PagerDuty secondary |
| GDPR sign-off | reso (`@MuBi2334`) | For §4.3 / §4.7 |
| Founder (incident commander, SEV-1 release-blocked) | (via belengaz) | Reserved for production-rejection or customer-promised release affected |
| Apple App Review | App Store Connect → Resolution Center | Formal communication channel |
| Apple Developer Support (expedited review) | [developer.apple.com/contact/](https://developer.apple.com/contact/) | Use sparingly — rate-limited per developer account |
| Play Console support | Play Console → Help → Contact us | For policy clarification |

---

## 9. Related runbooks (siblings under B-68)

- [`RUNBOOK-redis-outage.md`](RUNBOOK-redis-outage.md) — Redis outage (B-68 2/5)
- [`RUNBOOK-supabase-rls-regression.md`](RUNBOOK-supabase-rls-regression.md) — RLS regression (B-68 3/5)
- [`RUNBOOK-cert-pinning-rotation.md`](RUNBOOK-cert-pinning-rotation.md) — cert rotation (B-68 4/5)
- [`RUNBOOK-mollie-webhook-failure.md`](RUNBOOK-mollie-webhook-failure.md) — Mollie webhook (B-68 1/5)
- [`RUNBOOK-appstore-reviewer.md`](RUNBOOK-appstore-reviewer.md) — demo account fixture (cross-referenced in §4.5)

**B-68 is now 5 of 5 complete with this runbook.**

---

## 10. References

- CLAUDE.md §13 (Marketing Assets hard-gate), §14 (App Store reviewer fixture)
- `docs/PLAN-gh162-testflight-review-info.md` — Phase A code
- `fastlane/metadata/review_information/privacy_details.yaml` — Apple privacy nutrition labels
- `docs/marketing/aso/claims_ledger.md` — claim → shipped feature mapping
- `scripts/check_aso.dart` — ASO copy lint
- `scripts/check_screenshots.sh` — screenshot manifest audit
- Tier-1 retrospective: `docs/audits/2026-04-25-tier1-retrospective.md` §B-68
- Apple App Review Guidelines: [developer.apple.com/app-store/review/guidelines](https://developer.apple.com/app-store/review/guidelines/)
- Play Console policy: [play.google.com/about/developer-content-policy](https://play.google.com/about/developer-content-policy/)
- Apple Privacy Details: [developer.apple.com/app-store/app-privacy-details](https://developer.apple.com/app-store/app-privacy-details/)
- Play Data Safety: [support.google.com/googleplay/android-developer/answer/10787469](https://support.google.com/googleplay/android-developer/answer/10787469)
