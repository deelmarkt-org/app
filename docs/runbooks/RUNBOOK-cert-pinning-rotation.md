# RUNBOOK — Certificate pinning rotation

> **Owner:** belengaz (DevOps / Mobile)
> **Backup owner:** reso (Edge Function consumers)
> **Last reviewed:** 2026-04-30
> **Next scheduled review:** 2027-04-30 (annual cadence — pin expiry is 2027-06-01)
> **Severity classification:** SEV-1 (handshake failures blocking app traffic) · SEV-2 (planned rotation deadline approaching) · SEV-3 (advance notice from CA, > 30 days lead time)
> **Source of truth for code:** `android/app/src/main/res/xml/network_security_config.xml` · iOS: TrustKit pending (B-37 TODO)

This runbook is the **authoritative response procedure** when TLS certificate pinning needs to be rotated, either as a planned event (CA expiry, scheduled rotation) or as an emergency (CA compromise, premature revocation, broken handshakes in production). Pinning failures lock users out of the app entirely; the only recovery is shipping a new build with updated pins. Closes Tier-1 retrospective B-68 (4 of 5).

---

## 1. What pinning protects

Certificate pinning hardens the TLS chain by accepting **only** specified certificate fingerprints — even if a public CA is compromised. DeelMarkt pins:

| Domain | Purpose | Pin set | CA chain |
|:---|:---|:---|:---|
| `*.supabase.co` | Supabase API + Realtime + Storage + GoTrue + Edge Functions | GTS Root R4 + WE1 intermediate | Google Trust Services |
| `*.mollie.com` | Mollie payment API + webhook | (per `network_security_config.xml`) | Google Trust Services |
| `*.cloudinary.com` | Image delivery | (per `network_security_config.xml`) | GlobalSign |

Current expiry: **2027-06-01** (per `network_security_config.xml` `<pin-set expiration="2027-06-01">`).

Platform implementation:
- **Android:** native via `network_security_config.xml` (B-37, declarative XML)
- **iOS:** **TODO** — TrustKit integration pending (B-37 TODO comment); ATS defaults still apply but are weaker than Android's pinned set
- **Web:** N/A — browsers manage cert validation; HSTS + CSP only

Reference: `docs/ARCHITECTURE.md` §Security · `CLAUDE.md` §9 · OWASP MSTG-NETWORK-4 (certificate pinning).

---

## 2. Symptoms (how this surfaces)

| Symptom | Likely severity | First check |
|:---|:---|:---|
| Spike in mobile-app analytics events for "TLS handshake failed" or "SSL pinning error" | **SEV-1** | Cert chain expiry / pin match (§3.1) |
| Sentry mobile crashes filtered to `SSLHandshakeException` / `SSLPeerUnverifiedException` | **SEV-1** | Same |
| App Store reviewer or Play Console internal-test reviewer reports app cannot connect | **SEV-1** | Cert chain (likely a recent CA rotation we missed) |
| CA email / dashboard notification: "your certificate / intermediate is being rotated on YYYY-MM-DD" | **SEV-3** if > 30 days lead, **SEV-2** if < 30 days | Plan rotation (§4.1) |
| `network_security_config.xml` `<pin-set expiration="...">` < 90 days from today | **SEV-2** | Plan rotation |
| Customer support: "I can't log in" / "the app keeps spinning" recurring | **SEV-1** | Cross-reference with Sentry; check device-class breakdown (older Android ≤ 7 vs newer) |

If symptoms emerge unexpectedly with no advance CA notice, treat as **SEV-1** and begin §3 triage immediately.

---

## 3. Triage (do this first, before mitigation)

### 3.1 Verify CA chain matches committed pins

```bash
# Pull live cert chain from each pinned domain
for d in YOUR-PROJECT.supabase.co api.mollie.com res.cloudinary.com; do
  echo "=== $d ==="
  openssl s_client -connect "$d:443" -servername "$d" -showcerts < /dev/null 2>/dev/null | \
    openssl x509 -noout -fingerprint -sha256
done

# Compare each fingerprint against the pins committed in
# android/app/src/main/res/xml/network_security_config.xml
# (note: pin format is base64-encoded SHA-256 of subject public key, NOT cert fingerprint —
# convert via:
#   openssl s_client -connect <d>:443 -servername <d> < /dev/null 2>/dev/null | \
#     openssl x509 -pubkey -noout | \
#     openssl pkey -pubin -outform DER | \
#     openssl dgst -sha256 -binary | \
#     openssl enc -base64
```

If pins do not match → CA has rotated; this is the failure class for §4.

### 3.2 Identify the rotation class

| Trigger | Class | Skip to |
|:---|:---|:---|
| Planned CA rotation announced > 30 days in advance | Planned | §4.1 |
| Planned CA rotation announced < 30 days, no production breakage yet | Tight planned | §4.2 |
| Production handshakes failing **right now** | Emergency | §4.3 |
| CA compromise / premature revocation announcement | Emergency | §4.3 |
| Pin expiry date < 90 days, no CA notice received | Proactive rotation | §4.1 |

### 3.3 Snapshot the blast radius

```
# Mobile analytics (Firebase / Sentry):
#   - Count of "SSL handshake" errors in last 1h, 24h, 7d
#   - Device class distribution (iOS vs Android, version ranges)
#   - App version distribution (which builds are affected)
#   - Geographic distribution (regional CA availability)
```

Write counts in the incident channel. **Do not include user identifiers** — only counts and device/version classes.

---

## 4. Mitigation by rotation class

### 4.1 Planned rotation (> 30 days lead time)

**Cause:** CA email / Supabase / Mollie / Cloudinary advance notice. No production impact yet.

**Mitigation:**

1. **Stage the new pin alongside the existing pin** — Android `<pin-set>` allows multiple pins; both are accepted during the transition window:
   ```xml
   <pin-set expiration="2028-06-01">
     <!-- Existing pin (kept for rollback safety) -->
     <pin digest="SHA-256">mEflZT5enoR1FuXLgYYGqnVEoZvmf9c2bVBpiOjYQ0c=</pin>
     <!-- New pin -->
     <pin digest="SHA-256">NEW_BASE64_HERE</pin>
   </pin-set>
   ```
2. Compute the new pin via:
   ```bash
   openssl s_client -connect <d>:443 -servername <d> < /dev/null 2>/dev/null | \
     openssl x509 -pubkey -noout | \
     openssl pkey -pubin -outform DER | \
     openssl dgst -sha256 -binary | \
     openssl enc -base64
   ```
3. Ship in the next normal app release (TestFlight + Play Internal first, then production). Auto-update prompts users; force-update is NOT required.
4. After CA rotation has happened on the server side, ship a follow-up release that REMOVES the old pin — only the new pin remains.
5. Update `network_security_config.xml` `expiration` attribute to match the new cert's expiry.

### 4.2 Tight planned rotation (< 30 days lead time)

**Cause:** Late CA notice; insufficient lead time for normal release cadence.

**Mitigation:**

1. Ship the dual-pin update on the **fastest possible release path**:
   - iOS: TestFlight → expedited App Review request → production
   - Android: Internal testing → closed → open → production (each track propagates faster than App Review)
2. Enable Remote Config force-update prompt 7 days BEFORE the CA rotation date. Users on stale builds get a non-dismissible update prompt.
3. Coordinate with Supabase / Mollie / Cloudinary — confirm the rotation date does not change.
4. After rotation, ship the old-pin removal as a normal release.

### 4.3 Emergency rotation (handshakes failing now)

**Cause:** CA compromise, premature revocation, or unannounced rotation that broke production.

**Mitigation:**

1. **Engage incident commander** (founder + belengaz). Escalate to SEV-1.
2. **Determine impact scope** (§3.3 blast radius). If < 5% of users affected, may proceed with normal expedited release. If > 5%, force-update / temporary pin disable may be required.
3. **Two parallel tracks:**
   - **Track A — App release:** Update `network_security_config.xml` with the new pin (drop old pin if it's actively rejecting); expedited TestFlight + Play Internal → production
   - **Track B — Backstop pin disable (last resort):** Ship a Remote Config flag `cert_pinning_enabled` (default `true`); on emergency, set `false` to bypass pinning for affected versions until Track A reaches users. **This is high-risk** — pinning bypass means any compromised CA in the chain becomes exploitable. Use only when handshake failures are blocking critical flows (login, payment) and Track A is > 24h away.
   - **Track C — Pre-emptive force-update:** Set Remote Config `min_supported_app_version` to a build that includes the new pin; users on older builds get a non-dismissible update prompt.
4. If Track B is engaged, **document the bypass window** (start + end timestamps, affected app-version range) for the incident retrospective and any required GDPR notification analysis (cert pinning is a security-of-processing measure under Art. 32; bypass should be discussed with reso for GDPR sign-off).
5. After Track A reaches all affected users (typically 7-14 days for App Store, 1-3 days for Play Store), revert Track B Remote Config flags.

### 4.4 Pin expiry < 90 days, no CA notice

**Cause:** Calendar drift; CA has not announced rotation but the committed `expiration` attribute is approaching.

**Mitigation:**

1. Re-verify the live CA chain via §3.1. If pins still match, the CA has not rotated — extend the `expiration` attribute via a new release, set to a date based on the live cert's notAfter (read via `openssl x509 -noout -dates`).
2. Subscribe to CA rotation announcements (Google Trust Services email, GlobalSign portal) so we get formal notice next cycle.
3. Add a CI check (B-66 follow-up scope): `scripts/check_cert_pin_expiry.sh` that runs weekly and warns 90 days out, fails 30 days out.

---

## 5. Verification (after mitigation)

Mitigation is not complete until **all** of the following hold:

- [ ] Live CA fingerprints match the pins committed in `network_security_config.xml`
- [ ] `network_security_config.xml` `expiration` attribute is in the future (≥ 365 days for healthy state)
- [ ] No new "SSL handshake" / "SSL pinning error" Sentry events in the 30 minutes following the release
- [ ] Test device installs the new build successfully and completes login + payment + image-load flows
- [ ] PagerDuty incident closed with a resolution comment linking back to the §3.2 rotation class
- [ ] If Track B (pin disable) was used: Remote Config flag reverted; bypass window documented in incident retrospective
- [ ] CHANGELOG entry under the release that shipped the new pins

---

## 6. Communication (during the incident)

| Audience | Channel | When |
|:---|:---|:---|
| Engineering team | `#payments-incidents` Slack | At triage start, every 30 min during SEV-1 mitigation, at resolution |
| Founder + belengaz | DM | Immediately on SEV-1 confirmation |
| Affected customers (mobile) | App-side banner + email if individually identifiable | After mitigation rollout begins; instruct to update app |
| App Store reviewer | App Store Connect message | If review is in progress and rotation breaks the demo flow (cross-ref §RUNBOOK-app-store-rejection.md) |
| Supabase / Mollie / Cloudinary | Vendor support | Only if CA rotation timing was missed by the vendor side |
| Status page (if public) | DeelMarkt status page | SEV-1 only, generic wording ("update your app to continue") |
| Regulator (GDPR Art. 33) | DPA notification | Only if Track B (pin disable) bypass led to confirmed exposure (extremely rare) |

**Hard rule:** "update your app" messaging must be precise about which app version range is affected — confused customers may try uninstall/reinstall and lose local state.

---

## 7. Post-incident (within 5 business days)

- File a retrospective in `docs/audits/` named `INCIDENT-cert-pin-<YYYY-MM-DD>.md`
- Action items become GitHub issues; specifically:
  - If iOS TrustKit is still pending (B-37 TODO), escalate priority — iOS users had no pinning during this incident
  - If pin-expiry CI check is missing, open issue (B-66 follow-up)
- Update this runbook if the rotation class was new
- Verify `next scheduled review` date is updated to align with new cert expiry

---

## 8. Escalation contacts

| Role | Who | Channel |
|:---|:---|:---|
| Primary owner (mobile + DevOps) | belengaz (`@mahmutkaya`) | Slack DM, PagerDuty primary |
| Backup owner (Edge Function chain) | reso (`@MuBi2334`) | Slack DM, PagerDuty secondary |
| Founder (incident commander for SEV-1) | (via belengaz) | Reserved for SEV-1 with Track B bypass under consideration |
| Supabase support | dashboard → Support | If `*.supabase.co` chain is the problem |
| Mollie merchant support | dashboard → Support | If `api.mollie.com` chain is the problem |
| Cloudinary support | dashboard → Support | If image-load chain is the problem |
| Apple Developer Support (expedited review) | [developer.apple.com/contact](https://developer.apple.com/contact/) | Track A iOS path under emergency |

---

## 9. Related runbooks (siblings under B-68)

- [`RUNBOOK-redis-outage.md`](RUNBOOK-redis-outage.md) — Redis outage (B-68 2/5)
- [`RUNBOOK-supabase-rls-regression.md`](RUNBOOK-supabase-rls-regression.md) — RLS regression (B-68 3/5)
- [`RUNBOOK-mollie-webhook-failure.md`](RUNBOOK-mollie-webhook-failure.md) — Mollie webhook (B-68 1/5)
- `RUNBOOK-app-store-rejection.md` — App Store rejection response (B-68 5/5)

---

## 10. References

- Source: `android/app/src/main/res/xml/network_security_config.xml`
- Manifest: `android/app/src/main/AndroidManifest.xml` (`networkSecurityConfig` attribute)
- Tier-1 retrospective: `docs/audits/2026-04-25-tier1-retrospective.md` §B-68
- B-37 spec: SPRINT-PLAN.md (`network_security_config.xml` + cert pinning Supabase + Mollie)
- Android docs: [developer.android.com/training/articles/security-config](https://developer.android.com/training/articles/security-config)
- iOS pinning (TrustKit): [github.com/datatheorem/TrustKit](https://github.com/datatheorem/TrustKit)
- OWASP MSTG-NETWORK-4: [mas.owasp.org/MASTG/tests/android/MASVS-NETWORK](https://mas.owasp.org/MASTG/tests/android/MASVS-NETWORK/)
- Google Trust Services rotation calendar: [pki.goog](https://pki.goog/)
