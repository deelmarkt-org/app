/**
 * P-46: Dynamic OG Meta Tags + Crawler Pre-rendering
 *
 * Cloudflare Worker that intercepts crawler requests (WhatsApp, Facebook,
 * Twitter, Google, LinkedIn) and returns HTML with proper Open Graph meta
 * tags. Non-crawler requests pass through to the Flutter web app.
 *
 * Routes handled:
 *   /listings/:id  → listing OG tags (title, price, image, seller)
 *   /users/:id     → user profile OG tags (name, avatar, rating)
 *   /search?q=...  → search results OG tags
 *   /*             → default DeelMarkt OG tags
 *
 * Environment variables (set in Cloudflare dashboard):
 *   SUPABASE_URL         - e.g. https://ehxrhyqhtngwqkguwdiv.supabase.co
 *   SUPABASE_ANON_KEY    - Supabase anon public key
 *   SITE_URL             - e.g. https://deelmarkt.com
 *
 * Deploy: wrangler deploy
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

    if (path.match(/^\/listings\/[\w-]+$/)) {
      return handleListing(path, url, env);
    }

    if (path.match(/^\/users\/[\w-]+$/)) {
      return handleUser(path, url, env);
    }

    if (path.startsWith('/search')) {
      return handleSearch(url, env);
    }

    // Default OG tags for all other pages
    return renderOgHtml({
      ...DEFAULT_OG,
      url: url.toString(),
      siteName: 'DeelMarkt',
    }, env);
  },
};

/**
 * Fetch listing from Supabase and return OG tags.
 */
async function handleListing(path, url, env) {
  const id = path.split('/').pop();

  try {
    const resp = await fetch(
      `${env.SUPABASE_URL}/rest/v1/listings?id=eq.${id}&select=id,title,description,price_cents,category,condition,images,seller:users!seller_id(display_name,avatar_url)`,
      {
        headers: {
          apikey: env.SUPABASE_ANON_KEY,
          Authorization: `Bearer ${env.SUPABASE_ANON_KEY}`,
        },
      }
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

    return renderOgHtml({
      title: `${listing.title} — €${price}`,
      description: listing.description
        ? `${listing.description.substring(0, 160)}${listing.description.length > 160 ? '…' : ''}`
        : `${condition} · Verkocht door ${sellerName} op DeelMarkt`,
      image,
      type: 'product',
      url: url.toString(),
      siteName: 'DeelMarkt',
      locale: 'nl_NL',
      extra: [
        `<meta property="product:price:amount" content="${(listing.price_cents / 100).toFixed(2)}" />`,
        `<meta property="product:price:currency" content="EUR" />`,
        `<meta property="product:condition" content="${condition}" />`,
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
    const resp = await fetch(
      `${env.SUPABASE_URL}/rest/v1/users?id=eq.${id}&select=id,display_name,avatar_url,location,average_rating,review_count`,
      {
        headers: {
          apikey: env.SUPABASE_ANON_KEY,
          Authorization: `Bearer ${env.SUPABASE_ANON_KEY}`,
        },
      }
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
 * Return OG tags for search results page.
 */
async function handleSearch(url, env) {
  const query = url.searchParams.get('q') || '';
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

/**
 * Render a minimal HTML page with OG meta tags.
 *
 * Crawlers parse meta tags and ignore the rest. The <noscript> redirect
 * sends real users (who somehow end up here) to the actual page.
 */
function renderOgHtml(og, env) {
  const siteUrl = env.SITE_URL || 'https://deelmarkt.com';
  const escapedTitle = escapeHtml(og.title || DEFAULT_OG.title);
  const escapedDesc = escapeHtml(og.description || DEFAULT_OG.description);
  const imageUrl = og.image || DEFAULT_OG.image;
  const pageUrl = og.url || siteUrl;
  const extraTags = (og.extra || []).join('\n    ');

  const html = `<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8" />
    <title>${escapedTitle}</title>

    <!-- Open Graph -->
    <meta property="og:title" content="${escapedTitle}" />
    <meta property="og:description" content="${escapedDesc}" />
    <meta property="og:image" content="${imageUrl}" />
    <meta property="og:url" content="${pageUrl}" />
    <meta property="og:type" content="${og.type || 'website'}" />
    <meta property="og:site_name" content="${og.siteName || 'DeelMarkt'}" />
    <meta property="og:locale" content="${og.locale || 'nl_NL'}" />
    <meta property="og:locale:alternate" content="en_US" />

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content="${escapedTitle}" />
    <meta name="twitter:description" content="${escapedDesc}" />
    <meta name="twitter:image" content="${imageUrl}" />

    <!-- WhatsApp / Telegram -->
    <meta property="og:image:width" content="1200" />
    <meta property="og:image:height" content="630" />

    ${extraTags}

    <!-- Redirect non-crawler visitors to the actual app -->
    <meta http-equiv="refresh" content="0;url=${pageUrl}" />
    <link rel="canonical" href="${pageUrl}" />
</head>
<body>
    <p>Doorverwijzen naar <a href="${pageUrl}">${escapedTitle}</a>…</p>
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

/**
 * Escape HTML special characters to prevent XSS in meta tag content.
 */
function escapeHtml(str) {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}
