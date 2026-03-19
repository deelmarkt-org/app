# Manual Tasks — belengaz (Sprint 1)

> Tasks that require external dashboards, accounts, or credentials.
> Work through these while waiting for PR reviews and CI runs.

---

## 1. Cloudflare DNS (B-01) — BLOCKING

Everything depends on DNS resolving. Do this first.

- [x] Log in to [dash.cloudflare.com](https://dash.cloudflare.com)
- [x] Check site status — should say **"Active"**, not "Pending Nameserver Update"
- [x] If pending: go to your **domain registrar** (where you bought deelmarkt.com)
  - Find "Nameservers" or "DNS settings"
  - Replace the current nameservers with the two Cloudflare assigned (e.g. `ada.ns.cloudflare.com`, `bob.ns.cloudflare.com`)
  - Save and wait 1–4 hours for propagation
- [x] Verify with: `dig NS deelmarkt.com` — should show Cloudflare nameservers
- [x] Verify with: `curl -sI https://deelmarkt.com` — should return HTTP headers

**DNS Records to add in Cloudflare:**

| Type | Name | Content | Proxy |
|:-----|:-----|:--------|:------|
| A | `@` (deelmarkt.com) | `192.0.2.1` (placeholder until hosting) | Proxied (orange cloud) |
| CNAME | `www` | `deelmarkt.com` | Proxied |

**SSL/TLS settings (Cloudflare dashboard → SSL/TLS):**

- [x] Encryption mode: **Full (strict)**
- [x] Always Use HTTPS: **On**
- [x] Minimum TLS Version: **1.2**
- [x] HSTS: **Enable** (max-age 6 months, include subdomains)

---

## 2. Cloudflare WAF (B-02) — 10 min

Free plan gives: 70 Cloudflare Rules + 5 WAF Rules + DDoS protection. Enough for MVP.

- [x] Dashboard → Security → WAF
- [x] Enable **Cloudflare Managed Ruleset** (free — covers high severity vulnerabilities)
- [ ] ~~OWASP Core Ruleset~~ — **requires Pro ($20/mo), skip until public launch**
- [x] Enable **Bot Fight Mode** (Security → Bots → toggle on — free, common bots only)
- [x] Rate limiting (Security → WAF → Custom rules, uses 1 of your 5 WAF rules):
  - Rule: If requests from same IP > 100/min → Block for 10 min
  - Apply to: `deelmarkt.com/*`

---

## 3. Host AASA + assetlinks.json (B-06/B-07) — 20 min

Once DNS is active, these files need to be served at the correct URLs.

**Option A: Cloudflare Pages (recommended)**

- [ ] Dashboard → Workers & Pages → Create → Pages
- [ ] Connect to GitHub repo → set build output directory to `.well-known`
- [ ] Or: create a simple static site with just the `.well-known/` folder
- [ ] Set custom domain: `deelmarkt.com`
- [ ] Verify: `curl https://deelmarkt.com/.well-known/apple-app-site-association`
  - Must return `Content-Type: application/json`
- [ ] Verify: `curl https://deelmarkt.com/.well-known/assetlinks.json`

**Option B: Cloudflare Worker**

- [x] Dashboard → Workers & Pages → Create → Worker
- [x] Paste this code:

```javascript
export default {
  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === '/.well-known/apple-app-site-association') {
      return new Response(JSON.stringify({
        "applinks": {
          "details": [{
            "appIDs": ["TEAM_ID.nl.deelmarkt.deelmarkt"],
            "components": [
              { "/": "/listings/*" },
              { "/": "/users/*" },
              { "/": "/transactions/*" },
              { "/": "/shipping/*" },
              { "/": "/search" },
              { "/": "/sell" }
            ]
          }]
        }
      }), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    if (url.pathname === '/.well-known/assetlinks.json') {
      return new Response(JSON.stringify([{
        "relation": ["delegate_permission/common.handle_all_urls"],
        "target": {
          "namespace": "android_app",
          "package_name": "nl.deelmarkt.deelmarkt",
          "sha256_cert_fingerprints": ["SIGNING_CERT_SHA256_HERE"]
        }
      }]), {
        headers: { 'Content-Type': 'application/json' }
      });
    }

    return new Response('Not found', { status: 404 });
  }
};
```

- [x] Add route: `deelmarkt.com/.well-known/*` → this worker
- [ ] Replace `TEAM_ID` with your Apple Developer Team ID
- [ ] Replace `SIGNING_CERT_SHA256_HERE` after generating signing key

---

## 4. Cloudinary Account (B-03) — 10 min

- [x] Sign up at [cloudinary.com](https://cloudinary.com) (free tier: 25 credits/mo)
- [x] Note your **Cloud Name**, **API Key**, and **API Secret**
- [x] Store credentials in your password manager (NOT in code/chat)
- [x] Will be moved to Supabase Vault once reso sets up Supabase project
- [x] Test upload: Dashboard → Media Library → Upload any image → confirm transform URL works

---

## 5. Codemagic CI/CD (B-05) — 30 min

**Prerequisites:**
- [ ] Apple Developer account ($99/year) — [developer.apple.com](https://developer.apple.com)
- [ ] Google Play Console ($25 one-time) — [play.google.com/console](https://play.google.com/console)

**Setup:**
- [ ] Sign up at [codemagic.io](https://codemagic.io) (free tier: 500 build min/mo)
- [ ] Connect GitHub repo: `deelmarkt/app`
- [ ] iOS workflow:
  - Build mode: Release
  - Code signing: match Apple certificates (or manual provisioning profile)
  - Distribute to: TestFlight
  - Trigger: push to `dev` branch
- [ ] Android workflow:
  - Build mode: Release
  - Signing: create upload keystore → **save keystore password in password manager**
  - Distribute to: Play Store Internal Testing
  - Trigger: push to `dev` branch
- [ ] Get Android signing cert SHA256 for assetlinks.json:
  ```bash
  keytool -list -v -keystore your-upload-keystore.jks | grep SHA256
  ```
- [ ] Update `.well-known/assetlinks.json` with that SHA256 fingerprint

---

## 6. GitHub Secret Scanning (B-12) — 5 min

- [x] Go to [github.com/deelmarkt/app/settings/security_analysis](https://github.com/deelmarkt/app/settings/security_analysis)
- [x] Enable **Dependency graph**
- [x] Enable **Dependabot alerts**
- [x] Enable **Dependabot security updates**
- [-] Enable **Secret scanning**
- [-] Enable **Push protection** (blocks pushes containing secrets)

---

## 7. Betterstack Uptime Monitoring (B-09) — 15 min

- [ ] Sign up at [betterstack.com](https://betterstack.com) (free tier: 5 monitors)
- [ ] Create monitors:

| Monitor | URL | Check interval |
|:--------|:----|:---------------|
| Website | `https://deelmarkt.com` | 3 min |
| AASA | `https://deelmarkt.com/.well-known/apple-app-site-association` | 10 min |
| Supabase | (add after reso sets up project) | 3 min |

- [ ] Integrations → Slack → connect your team Slack workspace
- [ ] Set alert policy: notify immediately on downtime

---

## 8. PagerDuty (B-10) — 15 min

- [ ] Sign up at [pagerduty.com](https://pagerduty.com) (free tier: up to 5 users)
- [ ] Create service: "DeelMarkt Production"
- [ ] Create escalation policy:

| Severity | Action | Notify |
|:---------|:-------|:-------|
| CRITICAL | Page immediately | All 3 devs (phone call) |
| HIGH | Alert within 5 min | On-call dev (push + Slack) |
| INFO | Log only | Slack channel |

- [ ] Create integration keys for:
  - Betterstack (uptime → PagerDuty)
  - Sentry (errors → PagerDuty) — set up later
  - GitHub Actions (CI failure → PagerDuty INFO) — set up later
- [ ] Store integration keys in password manager

---

## 9. Download Fonts — 5 min

- [ ] Go to [fonts.google.com/specimen/Plus+Jakarta+Sans](https://fonts.google.com/specimen/Plus+Jakarta+Sans)
- [ ] Click "Download family"
- [ ] Extract the zip
- [ ] Copy these files to `assets/fonts/`:
  - `PlusJakartaSans-Regular.ttf`
  - `PlusJakartaSans-Medium.ttf`
  - `PlusJakartaSans-SemiBold.ttf`
  - `PlusJakartaSans-Bold.ttf`
- [ ] Replace the empty placeholder files that are already there
- [ ] Commit: `chore(fonts): add Plus Jakarta Sans font files`

---

## Priority Order

```
1. B-01  Cloudflare DNS          ← BLOCKING: everything depends on this
2. B-12  GitHub secret scanning  ← 5 min, instant security win
3. B-09  Download fonts          ← pizmam needs these for real screens
4. B-02  Cloudflare WAF          ← security baseline
5. B-03  Cloudinary account      ← reso needs for image upload (E01)
6. B-06  Host AASA + assetlinks  ← needs DNS first
7. B-05  Codemagic               ← needs Apple + Google accounts
8. B-09  Betterstack             ← needs DNS first
9. B-10  PagerDuty               ← can set up anytime
```

---

*Delete this file once all tasks are complete.*
