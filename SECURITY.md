# Security Policy

> **Status:** Active · **Last reviewed:** 2026-04-30 · **Next review:** 2026-07-30 (quarterly cadence)
> **Maintainer:** belengaz (`@mahmutkaya`) — DevOps & Security · with reso (`@MuBi2334`) for backend / GDPR scope.
> _DeelMarkt is a pre-launch marketplace. This policy will evolve as the operational footprint grows; substantive changes are minor-versioned in `docs/CHANGELOG.md`._

---

## 1. Reporting a Vulnerability

We take security seriously. **Please do not report vulnerabilities through public GitHub issues, pull requests, or social media.**

### Primary channel — GitHub Security Advisories (preferred)

Use GitHub's [private vulnerability reporting](https://docs.github.com/en/code-security/security-advisories/guidance-on-reporting-and-writing-information-about-vulnerabilities/privately-reporting-a-security-vulnerability) on this repository:

> [github.com/deelmarkt-org/app/security/advisories/new](https://github.com/deelmarkt-org/app/security/advisories/new)

Why we prefer this channel:

- TLS-encrypted in transit by GitHub
- Audit trail visible only to repo maintainers
- We can publish an associated CVE through GitHub's flow when a fix ships
- No PGP key management overhead on either side

### Secondary channel — email

If you cannot use GitHub Security Advisories (e.g. you are reporting an issue you discovered while logged out, or you are not a GitHub user), email:

> **[security@deelmarkt.com](mailto:security@deelmarkt.com)**

We aim to acknowledge email reports within **5 business days**. If you do not receive a reply by then, please open a GitHub Security Advisory or reach out via [support@deelmarkt.com](mailto:support@deelmarkt.com) referencing only that you "filed a security report" (without disclosing details in that channel).

### What to include in a report

To accelerate triage, please include where applicable:

- A clear description of the issue and the affected component (mobile app, web app, Edge Function, Supabase migration, CI workflow)
- Reproduction steps
- Expected vs observed behaviour
- Impact assessment (data exposure, privilege escalation, denial of service, financial impact)
- A CVSS v3.1 estimate if you have one
- Suggested mitigation if you have one
- Whether you intend to publish a write-up after fix (we will coordinate the timeline; see §3)

### What NOT to include

- **Real user PII.** If you discovered a vulnerability via real user data, redact identifiers (email, name, phone, address, payment refs). The proof-of-concept should use the App Store reviewer fixture (UUIDs prefixed `aa162162-…`) where possible.
- **Live exploit traffic.** Do not run automated scanners against production. Static analysis on public artefacts (binaries, web bundles) is acceptable; volumetric or destructive testing is not (see §4 Out of Scope).

---

## 2. Supported Platforms

DeelMarkt ships as a single-stream production product. We **do not** maintain multiple parallel releases — every supported platform receives security fixes on the latest release line only. Older client builds are **not** separately patched; mobile auto-update is enforced and the web client is always served the latest build.

| Platform | Supported | Notes |
| :--- | :--- | :--- |
| iOS app | Latest 2 minor releases | Distributed via App Store. Older builds receive a non-blocking "update required" prompt. |
| Android app | Latest 2 minor releases | Distributed via Play Store. Older builds receive a non-blocking "update required" prompt. |
| Web app | Latest deployment | Served via Cloudflare; no per-version patches. Force-reload on critical advisories. |
| Edge Functions | Latest deployment on `dev` and `main` | No retained legacy runtime. |
| Supabase migrations | Forward-only with idempotent down-migrations | Schema rollbacks coordinated with DB owner (reso). |

If you find an issue affecting an older client build that is still in the wild, please report it — we will assess whether to ship a backport or accelerate the auto-update prompt.

---

## 3. Response Process

We use a coordinated-disclosure model with conservative timelines that we can sustain at our current operational scale. As the team grows, these timelines will tighten.

| Stage | Target | Notes |
| :--- | :--- | :--- |
| **Acknowledgement** | Within **5 business days** | Reporter receives a reply confirming the report was received. |
| **Triage + severity assignment** | Within **10 business days** | We assign a CVSS v3.1 score and an internal severity tier (P0–P3). |
| **Critical fix shipped** | Within **14 days** of triage for CVSS ≥ 9.0 | "Shipped" = merged to `dev` + deployed to staging + scheduled for next production cut. Faster on truly active exploitation. |
| **High fix shipped** | Within **45 days** of triage for CVSS 7.0–8.9 | |
| **Medium / Low fix shipped** | Within **90 days** of triage for CVSS < 7.0 | |
| **Public disclosure** | Coordinated — typically **90 days** from acknowledgement | We publish via GitHub Security Advisory + CHANGELOG entry. Reporter is credited unless anonymity requested. |

If a fix takes longer than the target, we will notify the reporter and explain why. **We will not retaliate against good-faith reporters** for any reasonable schedule extension we request.

---

## 4. Out of Scope

The following report classes are **not** covered by this policy. Please route them as indicated:

| Class | Where to route |
| :--- | :--- |
| Volumetric / DoS attacks | Not in scope. We rely on Cloudflare WAF + Supabase rate limits. |
| Social-engineering of staff | Not in scope. Report any phishing attempts targeting DeelMarkt employees to [support@deelmarkt.com](mailto:support@deelmarkt.com). |
| Physical attacks on offices, devices, or staff | Not in scope. |
| Issues in third-party dependencies (Supabase, Mollie, Cloudflare, Cloudinary, Sentry, Firebase) | Report directly to that vendor under their own disclosure policy. We will coordinate downstream remediation if our usage materially amplifies the issue. |
| Theoretical vulnerabilities without a reproducible exploit path | Best-effort review only. Concrete proof-of-concept significantly accelerates triage. |
| Self-XSS, missing CSRF on idempotent read endpoints, missing security headers without exploitability | Best-effort review only. |
| **Content moderation / illegal-listings / suspected fraud** | **Not a security issue** — use the in-app DSA flagger flow, or email [trust@deelmarkt.com](mailto:trust@deelmarkt.com). Routing these to security@ delays moderation response. |

---

## 5. Safe Harbor (good-faith research)

We will not pursue legal action against you for security research that:

1. Targets only systems and data you are authorised to access (your own test account, the App Store reviewer fixture, or scope you have permission to test)
2. Avoids privacy violations, destruction of data, and interruption or degradation of service to other users
3. Discloses findings to us through the channels in §1 and gives us a reasonable window (per §3) to remediate before public disclosure
4. Does not attempt to access, modify, or exfiltrate production user data beyond the minimum required to demonstrate impact
5. Does not pivot from one finding into unrelated systems or data

This is good-faith research, not legal indemnity — we cannot waive obligations to third parties (e.g. PSD2 / GDPR / DSA regulators). If you are uncertain whether a planned activity falls within scope, ask first via [security@deelmarkt.com](mailto:security@deelmarkt.com); we will respond in writing.

We have aligned this section with the [OWASP Vulnerability Disclosure Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html) — if you are familiar with that template, this section will read as expected.

---

## 6. EU Regulatory Alignment

DeelMarkt is operated from the Netherlands and serves EU customers. The following obligations interact with this policy:

- **GDPR Art. 33** — User-data breaches that trigger Art. 33 notification are reported to the Dutch DPA (Autoriteit Persoonsgegevens) within **72 hours** of awareness. Reporters do not need to file separately with the DPA; we coordinate.
- **GDPR Art. 32** — Security of processing. The mitigations we ship as a result of your report are documented internally so we can demonstrate ongoing technical-and-organisational measures.
- **NIS2 Directive (Art. 21)** — If DeelMarkt is later classified as an important or essential entity (Digital Service Provider scope), this policy is the public-facing artefact of our incident-handling commitments. Reviewable each quarter against NIS2 implementation guidance.
- **DSA Art. 16 boundary** — `SECURITY.md` is for **technical vulnerabilities** only. **Content moderation issues** (illegal listings, scam reports, harassment) route through the in-app flagger flow per DSA Art. 16, not through `security@`. Misrouted reports are forwarded to `trust@deelmarkt.com` and the security clock does not start.
- **Mollie / PSD2 incident reporting** — Suspected payment-flow vulnerabilities trigger our PSP incident reporting obligation to Mollie. We coordinate the disclosure timeline accordingly.

This list is descriptive, not exhaustive — a reported vulnerability may surface obligations we have not anticipated. We will not delay acknowledgement to research these.

---

## 7. Acknowledgements

We publicly credit researchers who responsibly disclose vulnerabilities, unless anonymity is requested. Recognition is published in our changelog (`docs/CHANGELOG.md`) and, for higher-severity findings, in a public GitHub Security Advisory.

**We do not currently operate a monetary bug bounty programme.** As a pre-launch marketplace this would be premature. If a future bounty programme launches, we will announce it via this file and via [deelmarkt.com](https://deelmarkt.com).

---

## 8. Policy Updates

| Date | Reviewer | Change |
| :--- | :--- | :--- |
| 2026-04-30 | pizmam (cross-owner co-pilot) | Initial policy authored. Closes Tier-1 retrospective B-67. |

This policy is reviewed quarterly and on each major release. Substantive changes are versioned in `docs/CHANGELOG.md` under the relevant sprint and announced via the release notes.

---

## References

- [GitHub — Adding a security policy to your repository](https://docs.github.com/en/code-security/getting-started/adding-a-security-policy-to-your-repository)
- [OWASP Vulnerability Disclosure Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Vulnerability_Disclosure_Cheat_Sheet.html)
- [RFC 9116 — A File Format to Aid in Security Vulnerability Disclosure](https://datatracker.ietf.org/doc/rfc9116/) (machine-readable `security.txt` may be added as a follow-up)
- [GDPR — Article 33 notification](https://gdpr-info.eu/art-33-gdpr/)
- [NIS2 Directive — Art. 21 measures](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32022L2555)
- [DSA — Art. 16 trusted flagger boundary](https://eur-lex.europa.eu/legal-content/EN/TXT/?uri=CELEX:32022R2065)
