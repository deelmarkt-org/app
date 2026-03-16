# Deep Link Configuration Files

These files must be served at `https://deelmarkt.com/.well-known/` for deep linking to work.

## Files

| File | URL | Purpose |
|:-----|:----|:--------|
| `apple-app-site-association` | `/.well-known/apple-app-site-association` | iOS Universal Links |
| `assetlinks.json` | `/.well-known/assetlinks.json` | Android App Links |

## Setup

### Option A: Cloudflare Pages (recommended)
1. Create a Cloudflare Pages project pointing to the `.well-known/` directory
2. Set custom domain to `deelmarkt.com`

### Option B: Cloudflare Worker
Deploy the worker in `cloudflare-worker.js` to serve these files.

## Before App Store Submission
- [ ] Replace `TEAM_ID` in AASA with your Apple Developer Team ID
- [ ] Replace `SIGNING_CERT_SHA256_HERE` in assetlinks.json with your signing certificate fingerprint
  - Get it with: `keytool -list -v -keystore your-keystore.jks | grep SHA256`
- [ ] Verify AASA: `curl -I https://deelmarkt.com/.well-known/apple-app-site-association`
  - Must return `Content-Type: application/json` (NOT `application/pkcs7-mime`)
- [ ] Verify assetlinks: `curl https://deelmarkt.com/.well-known/assetlinks.json`
- [ ] Test with Apple's validator: https://search.developer.apple.com/appsearch-validation-tool/
