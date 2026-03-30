# DeelMarkt OG Worker (P-46)

Cloudflare Worker that serves dynamic Open Graph meta tags for social media previews.

## What it does

When a crawler (WhatsApp, Facebook, Twitter, Google, LinkedIn) visits a DeelMarkt URL,
this worker intercepts the request and returns an HTML page with proper OG meta tags.
Non-crawler visitors are passed through to the Flutter web app unchanged.

## Routes

| URL Pattern | OG Tags | Type |
|-------------|---------|------|
| `/listings/:id` | Title, price, first image, seller name, condition, sold status | `product` |
| `/users/:id` | Display name, avatar, rating, review count, location | `profile` |
| `/transactions/:id` | Listing title, amount, status (Dutch), escrow badge | `website` |
| `/shipping/:id` | Carrier, tracking number, listing title | `website` |
| `/shipping/:id/qr` | Same + "QR-code" suffix | `website` |
| `/shipping/:id/tracking` | Same + "Tracking" suffix | `website` |
| `/shipping/:id/parcel-shops` | Same + "Servicepunten" suffix | `website` |
| `/messages/:id` | Conversation listing title | `website` |
| `/search?q=...` | Search query in title + description | `website` |
| `/*` (other) | Default DeelMarkt branding | `website` |

## Setup

### Prerequisites

- [Wrangler CLI](https://developers.cloudflare.com/workers/wrangler/install-and-update/)
- Cloudflare account with `deelmarkt.com` zone

### Deploy

```bash
cd cloudflare/og-worker

# Set secrets (one-time)
wrangler secret put SUPABASE_URL
# Enter: your Supabase project URL (found in root .env as SUPABASE_PROJECT_ID → https://<project-id>.supabase.co)

wrangler secret put SUPABASE_ANON_KEY
# Enter: your Supabase anon key (found in root .env as SUPABASE_ANON_PUBLIC)

# Deploy
wrangler deploy
```

### Local development

```bash
cd cloudflare/og-worker
wrangler dev
# Worker runs at http://localhost:8787
# Test crawlers:
# curl -H "User-Agent: WhatsApp" http://localhost:8787/listings/test-id
# curl -H "User-Agent: Twitterbot" http://localhost:8787/users/test-id
# curl -H "User-Agent: facebookexternalhit" http://localhost:8787/transactions/test-id
# curl -H "User-Agent: LinkedInBot" http://localhost:8787/shipping/test-id/tracking
```

## How it works

1. Request arrives at Cloudflare edge
2. Worker checks `User-Agent` against known crawler patterns
3. If crawler: fetch data from Supabase REST API → return HTML with OG tags
4. If not crawler: `fetch(request)` passes through to origin (Flutter web app)

## Caching

- OG responses are cached for 1 hour at browser level, 24 hours at CDN level
- `X-Robots-Tag: noindex` prevents search engines from indexing the OG stub pages

## OG image

The default OG image (`og-default.png`) should be a 1200x630px branded image.
Place it in `web/` so it's served at `https://deelmarkt.com/og-default.png`.
