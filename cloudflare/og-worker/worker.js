/**
 * P-46: Dynamic OG Meta Tags + Crawler Pre-rendering
 *
 * Cloudflare Worker that intercepts crawler requests (WhatsApp, Facebook,
 * Twitter, Google, LinkedIn) and returns HTML with proper Open Graph meta
 * tags. Non-crawler requests pass through to the Flutter web app.
 *
 * Routes handled:
 *   /listings/:id       → listing OG tags (title, price, image, seller)
 *   /users/:id          → user profile OG tags (name, avatar, rating)
 *   /transactions/:id   → transaction OG tags (status, amount)
 *   /shipping/:id/*     → shipping OG tags (carrier, tracking)
 *   /messages/:id       → conversation OG tags (listing context)
 *   /search?q=...       → search results OG tags
 *   /*                  → default DeelMarkt OG tags
 *
 * Environment variables (set via wrangler secret put):
 *   SUPABASE_URL         - e.g. https://ehxrhyqhtngwqkguwdiv.supabase.co
 *   SUPABASE_ANON_KEY    - Supabase anon public key
 *
 * Environment variables (set in wrangler.toml [vars]):
 *   SITE_URL             - e.g. https://deelmarkt.com
 *
 * Deploy: cd cloudflare/og-worker && wrangler deploy
 * Reference: CLAUDE.md §9, docs/SPRINT-PLAN.md P-46
 */

const CRAWLER_UA_PATTERNS = [
  'facebookexternalhit',
  'Facebot',
  'Twitterbot',
  'WhatsApp',
  'LinkedInBot',
  'Googlebot',
  'bingbot',
  'Slackbot',
  'TelegramBot',
  'Discordbot',
  'Pinterest',
  'Applebot',
];

const DEFAULT_OG = {
  title: 'DeelMarkt — De eerlijke marktplaats van Nederland',
  description: 'Koop en verkoop tweedehands met vertrouwen. Escrow-betalingen, gratis verzending via PostNL & DHL, en ingebouwde oplichtersbescherming.',
  image: 'https://deelmarkt.com/og-default.png',
  type: 'website',
  locale: 'nl_NL',
};

export default {
  async fetch(request, env) {
    // Validate required environment variables
    if (!env.SUPABASE_URL || !env.SUPABASE_ANON_KEY) {
      console.error('[og-worker] Missing SUPABASE_URL or SUPABASE_ANON_KEY');
      return fetch(request);
    }

    const url = new URL(request.url);
    const ua = request.headers.get('user-agent') || '';

    // Only intercept crawlers — pass everything else through
    const isCrawler = CRAWLER_UA_PATTERNS.some(
      (pattern) => ua.toLowerCase().includes(pattern.toLowerCase())
    );

    if (!isCrawler) {
      return fetch(request);
    }

    // Route to appropriate OG handler
    const path = url.pathname;
    const defaultFallback = { ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' };

    if (path.match(/^\/listings\/[\w-]+$/)) {
      return handleListing(path, url, env);
    }

    if (path.match(/^\/users\/[\w-]+$/)) {
      return handleUser(path, url, env);
    }

    if (path.match(/^\/transactions\/[\w-]+$/)) {
      return handleTransaction(path, url, env);
    }

    if (path.match(/^\/shipping\/[\w-]+(\/.*)?$/)) {
      return handleShipping(path, url, env);
    }

    if (path.match(/^\/messages\/[\w-]+$/)) {
      return handleMessages(path, url, env);
    }

    if (path === '/search' || path.startsWith('/search?')) {
      return handleSearch(url, env);
    }

    // Default OG tags for all other pages
    return renderOgHtml(defaultFallback, env);
  },
};

// ---------------------------------------------------------------------------
// Supabase fetch helper
// ---------------------------------------------------------------------------

async function supabaseFetch(env, query) {
  return fetch(`${env.SUPABASE_URL}/rest/v1/${query}`, {
    headers: {
      apikey: env.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${env.SUPABASE_ANON_KEY}`,
    },
  });
}

// ---------------------------------------------------------------------------
// Route handlers
// ---------------------------------------------------------------------------

/**
 * Fetch listing from Supabase and return OG tags.
 */
async function handleListing(path, url, env) {
  const id = path.split('/').pop();

  try {
    const resp = await supabaseFetch(
      env,
      `listings?id=eq.${encodeURIComponent(id)}&select=id,title,description,price_cents,category,condition,images,is_sold,seller:users!seller_id(display_name,avatar_url)`
    );

    if (!resp.ok) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const listings = await resp.json();
    if (!listings || listings.length === 0) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const listing = listings[0];
    const price = (listing.price_cents / 100).toFixed(2).replace('.', ',');
    const image = listing.images?.[0] || DEFAULT_OG.image;
    const sellerName = listing.seller?.display_name || 'Verkoper';
    const condition = listing.condition || '';
    const soldPrefix = listing.is_sold ? '(VERKOCHT) ' : '';

    return renderOgHtml({
      title: `${soldPrefix}${listing.title} — €${price}`,
      description: listing.description
        ? truncateUtf8(listing.description, 155)
        : `${condition} · Verkocht door ${sellerName} op DeelMarkt`,
      image,
      type: 'product',
      url: url.toString(),
      siteName: 'DeelMarkt',
      locale: 'nl_NL',
      extra: [
        `<meta property="product:price:amount" content="${escapeHtml((listing.price_cents / 100).toFixed(2))}" />`,
        `<meta property="product:price:currency" content="EUR" />`,
        `<meta property="product:condition" content="${escapeHtml(condition)}" />`,
      ],
    }, env);
  } catch (err) {
    console.error(`[og-worker] Listing fetch failed: ${err.message}`);
    return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
  }
}

/**
 * Fetch user profile from Supabase and return OG tags.
 */
async function handleUser(path, url, env) {
  const id = path.split('/').pop();

  try {
    const resp = await supabaseFetch(
      env,
      `users?id=eq.${encodeURIComponent(id)}&select=id,display_name,avatar_url,location,average_rating,review_count`
    );

    if (!resp.ok) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const users = await resp.json();
    if (!users || users.length === 0) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const user = users[0];
    const rating = user.average_rating ? `★ ${user.average_rating.toFixed(1)}` : '';
    const reviews = user.review_count ? `${user.review_count} beoordelingen` : '';
    const location = user.location || '';

    return renderOgHtml({
      title: `${user.display_name} op DeelMarkt`,
      description: [rating, reviews, location].filter(Boolean).join(' · ') || `Bekijk het profiel van ${user.display_name} op DeelMarkt`,
      image: user.avatar_url || DEFAULT_OG.image,
      type: 'profile',
      url: url.toString(),
      siteName: 'DeelMarkt',
      locale: 'nl_NL',
    }, env);
  } catch (err) {
    console.error(`[og-worker] User fetch failed: ${err.message}`);
    return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
  }
}

/**
 * Fetch transaction from Supabase and return OG tags.
 */
async function handleTransaction(path, url, env) {
  const id = path.split('/').pop();

  try {
    const resp = await supabaseFetch(
      env,
      `transactions?id=eq.${encodeURIComponent(id)}&select=id,status,total_amount_cents,listing:listings!listing_id(title,images)`
    );

    if (!resp.ok) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const transactions = await resp.json();
    if (!transactions || transactions.length === 0) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const txn = transactions[0];
    const statusNl = {
      created: 'Aangemaakt',
      payment_pending: 'Betaling in behandeling',
      paid: 'Betaald',
      shipped: 'Verzonden',
      delivered: 'Bezorgd',
      confirmed: 'Bevestigd',
      released: 'Uitbetaald',
      disputed: 'Geschil',
      refunded: 'Terugbetaald',
    };
    const status = statusNl[txn.status] || txn.status;
    const price = (txn.total_amount_cents / 100).toFixed(2).replace('.', ',');
    const listingTitle = txn.listing?.title || 'Transactie';
    const image = txn.listing?.images?.[0] || DEFAULT_OG.image;

    return renderOgHtml({
      title: `${listingTitle} — €${price} (${status})`,
      description: `Transactie op DeelMarkt · Status: ${status} · Beschermd door escrow`,
      image,
      type: 'website',
      url: url.toString(),
      siteName: 'DeelMarkt',
      locale: 'nl_NL',
    }, env);
  } catch (err) {
    console.error(`[og-worker] Transaction fetch failed: ${err.message}`);
    return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
  }
}

/**
 * Fetch shipping info from Supabase and return OG tags.
 * Handles /shipping/:id, /shipping/:id/qr, /shipping/:id/tracking, /shipping/:id/parcel-shops
 */
async function handleShipping(path, url, env) {
  const segments = path.split('/').filter(Boolean);
  const id = segments[1]; // /shipping/:id/...

  if (!id) {
    return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
  }

  try {
    const resp = await supabaseFetch(
      env,
      `shipping_labels?transaction_id=eq.${encodeURIComponent(id)}&select=id,carrier,tracking_number,transaction:transactions!transaction_id(listing:listings!listing_id(title,images))`
    );

    if (!resp.ok) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const labels = await resp.json();
    if (!labels || labels.length === 0) {
      return renderOgHtml({
        title: 'Verzending — DeelMarkt',
        description: 'Volg je pakket op DeelMarkt. Veilige verzending via PostNL & DHL.',
        image: DEFAULT_OG.image,
        type: 'website',
        url: url.toString(),
        siteName: 'DeelMarkt',
        locale: 'nl_NL',
      }, env);
    }

    const label = labels[0];
    const carrier = (label.carrier || '').toUpperCase();
    const listingTitle = label.transaction?.listing?.title || 'Pakket';
    const image = label.transaction?.listing?.images?.[0] || DEFAULT_OG.image;
    const subpage = segments[2] || '';
    const subpageNl = {
      qr: 'QR-code',
      tracking: 'Tracking',
      'parcel-shops': 'Servicepunten',
    };
    const suffix = subpageNl[subpage] ? ` — ${subpageNl[subpage]}` : '';

    return renderOgHtml({
      title: `${listingTitle} · ${carrier} verzending${suffix}`,
      description: `Volg je ${carrier} pakket op DeelMarkt. Tracking: ${label.tracking_number || 'beschikbaar na verzending'}.`,
      image,
      type: 'website',
      url: url.toString(),
      siteName: 'DeelMarkt',
      locale: 'nl_NL',
    }, env);
  } catch (err) {
    console.error(`[og-worker] Shipping fetch failed: ${err.message}`);
    return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
  }
}

/**
 * Fetch conversation context from Supabase and return OG tags.
 */
async function handleMessages(path, url, env) {
  const id = path.split('/').pop();

  try {
    const resp = await supabaseFetch(
      env,
      `conversations?id=eq.${encodeURIComponent(id)}&select=id,listing_title,listing_image_url`
    );

    if (!resp.ok) {
      return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
    }

    const conversations = await resp.json();
    if (!conversations || conversations.length === 0) {
      return renderOgHtml({
        title: 'Berichten — DeelMarkt',
        description: 'Stuur berichten op DeelMarkt. Veilig chatten met ingebouwde oplichtersbescherming.',
        image: DEFAULT_OG.image,
        type: 'website',
        url: url.toString(),
        siteName: 'DeelMarkt',
        locale: 'nl_NL',
      }, env);
    }

    const conv = conversations[0];

    return renderOgHtml({
      title: `Chat over "${conv.listing_title || 'artikel'}" — DeelMarkt`,
      description: 'Veilig chatten op DeelMarkt met ingebouwde oplichtersbescherming.',
      image: conv.listing_image_url || DEFAULT_OG.image,
      type: 'website',
      url: url.toString(),
      siteName: 'DeelMarkt',
      locale: 'nl_NL',
    }, env);
  } catch (err) {
    console.error(`[og-worker] Messages fetch failed: ${err.message}`);
    return renderOgHtml({ ...DEFAULT_OG, url: url.toString(), siteName: 'DeelMarkt' }, env);
  }
}

/**
 * Return OG tags for search results page.
 */
async function handleSearch(url, env) {
  const query = escapeHtml(url.searchParams.get('q') || '');
  const title = query
    ? `"${query}" — Zoekresultaten op DeelMarkt`
    : 'Zoeken op DeelMarkt';
  const description = query
    ? `Bekijk tweedehands "${query}" op DeelMarkt. Veilig kopen met escrow-bescherming.`
    : 'Zoek tweedehands artikelen op DeelMarkt. Veilig kopen en verkopen met escrow-bescherming.';

  return renderOgHtml({
    title,
    description,
    image: DEFAULT_OG.image,
    type: 'website',
    url: url.toString(),
    siteName: 'DeelMarkt',
    locale: 'nl_NL',
  }, env);
}

// ---------------------------------------------------------------------------
// OG HTML renderer
// ---------------------------------------------------------------------------

/**
 * Render a minimal HTML page with OG meta tags.
 *
 * Crawlers parse meta tags and ignore the rest. The meta refresh redirect
 * sends real users (who somehow end up here) to the actual page.
 */
function renderOgHtml(og, env) {
  const siteUrl = env.SITE_URL || 'https://deelmarkt.com';
  const escapedTitle = escapeHtml(og.title || DEFAULT_OG.title);
  const escapedDesc = escapeHtml(og.description || DEFAULT_OG.description);
  const escapedImage = escapeHtml(og.image || DEFAULT_OG.image);
  const escapedUrl = escapeHtml(og.url || siteUrl);
  const extraTags = (og.extra || []).join('\n    ');

  const html = `<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8" />
    <title>${escapedTitle}</title>

    <!-- Open Graph -->
    <meta property="og:title" content="${escapedTitle}" />
    <meta property="og:description" content="${escapedDesc}" />
    <meta property="og:image" content="${escapedImage}" />
    <meta property="og:url" content="${escapedUrl}" />
    <meta property="og:type" content="${escapeHtml(og.type || 'website')}" />
    <meta property="og:site_name" content="${escapeHtml(og.siteName || 'DeelMarkt')}" />
    <meta property="og:locale" content="${escapeHtml(og.locale || 'nl_NL')}" />
    <meta property="og:locale:alternate" content="en_US" />

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="${escapedTitle}" />
    <meta name="twitter:description" content="${escapedDesc}" />
    <meta name="twitter:image" content="${escapedImage}" />

    <!-- WhatsApp / Telegram -->
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />

    ${extraTags}

    <!-- Redirect non-crawler visitors to the actual app -->
    <meta http-equiv="refresh" content="0;url=${escapedUrl}" />
    <link rel="canonical" href="${escapedUrl}" />
</head>
<body>
    <p>Doorverwijzen naar <a href="${escapedUrl}">${escapedTitle}</a>…</p>
</body>
</html>`;

  return new Response(html, {
    status: 200,
    headers: {
      'Content-Type': 'text/html;charset=UTF-8',
      'Cache-Control': 'public, max-age=3600, s-maxage=86400',
      'X-Robots-Tag': 'noindex',
    },
  });
}

// ---------------------------------------------------------------------------
// Utilities
// ---------------------------------------------------------------------------

/**
 * Escape HTML special characters to prevent XSS in meta tag content.
 */
function escapeHtml(str) {
  if (typeof str !== 'string') return '';
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * Truncate a UTF-8 string safely without breaking multi-byte characters.
 * Adds ellipsis if truncated.
 */
function truncateUtf8(str, maxLen) {
  if (!str || str.length <= maxLen) return str;
  // Use Array.from to handle multi-byte characters (emoji, accented chars)
  const chars = Array.from(str);
  if (chars.length <= maxLen) return str;
  return chars.slice(0, maxLen).join('') + '…';
}
