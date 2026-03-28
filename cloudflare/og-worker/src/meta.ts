/**
 * P-46: HTML meta tag generation for crawlers.
 * Generates pre-rendered HTML with OG/Twitter meta tags and JSON-LD structured data.
 *
 * Design system alignment:
 * - Brand colours from tokens.md: primary #F15A24, secondary #1E4F7A
 * - Cloudinary image transforms per PLAN-frontend-launch.md
 * - Dutch (NL) as primary language, English (EN) fallback
 */

import { ListingData, UserData } from "./supabase.ts";

/** Format cents to Euro display: €12,50 (Dutch convention per tokens.md) */
function formatPrice(cents: number): string {
  const euros = (cents / 100).toFixed(2).replace(".", ",");
  return `\u20AC${euros}`;
}

/** Escape HTML entities to prevent XSS in meta content */
function escapeHtml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/"/g, "&quot;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;");
}

/** Truncate text to maxLen, appending ellipsis if needed */
function truncate(text: string, maxLen: number): string {
  if (text.length <= maxLen) return text;
  return text.slice(0, maxLen - 1) + "\u2026";
}

/**
 * Build Cloudinary thumbnail URL for OG image.
 * Transform: 1200x630 fill for OG (Facebook/LinkedIn optimal size).
 */
function ogImageUrl(imageUrl: string, cloudinaryCloud: string): string {
  if (imageUrl.includes("res.cloudinary.com")) {
    return imageUrl.replace(
      "/upload/",
      "/upload/c_fill,w_1200,h_630,f_auto,q_auto/",
    );
  }
  // Fallback: return as-is for non-Cloudinary images
  return imageUrl;
}

interface MetaOptions {
  siteUrl: string;
  cloudinaryCloud: string;
}

/** Build full pre-rendered HTML page for a listing */
export function buildListingHtml(
  listing: ListingData,
  opts: MetaOptions,
): string {
  const title = escapeHtml(truncate(listing.title, 60));
  const price = formatPrice(listing.price_in_cents);
  const description = escapeHtml(
    truncate(
      listing.description
        ? `${price} \u2014 ${listing.description}`
        : `${price} op DeelMarkt`,
      160,
    ),
  );
  const url = `${opts.siteUrl}/listings/${listing.id}`;
  const image =
    listing.image_urls.length > 0
      ? ogImageUrl(listing.image_urls[0], opts.cloudinaryCloud)
      : `${opts.siteUrl}/icons/Icon-512.png`;
  const seller = listing.seller_display_name
    ? escapeHtml(listing.seller_display_name)
    : "DeelMarkt verkoper";
  const condition = listing.condition
    ? escapeHtml(listing.condition)
    : undefined;
  const location = listing.location
    ? escapeHtml(listing.location)
    : undefined;

  // JSON-LD structured data (Schema.org Product)
  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Product",
    name: listing.title,
    description: listing.description ?? undefined,
    image:
      listing.image_urls.length > 0
        ? listing.image_urls.map((u) =>
            ogImageUrl(u, opts.cloudinaryCloud),
          )
        : undefined,
    offers: {
      "@type": "Offer",
      price: (listing.price_in_cents / 100).toFixed(2),
      priceCurrency: "EUR",
      availability: "https://schema.org/InStock",
      url,
      seller: {
        "@type": "Person",
        name: listing.seller_display_name ?? "DeelMarkt verkoper",
      },
    },
    ...(condition
      ? {
          itemCondition:
            condition.toLowerCase() === "nieuw"
              ? "https://schema.org/NewCondition"
              : "https://schema.org/UsedCondition",
        }
      : {}),
  };

  return buildHtmlShell({
    title: `${title} \u2014 ${price} | DeelMarkt`,
    description,
    url,
    image,
    type: "product",
    jsonLd: JSON.stringify(jsonLd),
    extra: [
      `<meta property="product:price:amount" content="${(listing.price_in_cents / 100).toFixed(2)}">`,
      `<meta property="product:price:currency" content="EUR">`,
      ...(condition
        ? [
            `<meta property="product:condition" content="${condition}">`,
          ]
        : []),
      ...(location
        ? [
            `<meta property="og:locale" content="nl_NL">`,
          ]
        : []),
    ],
  });
}

/** Build pre-rendered HTML page for a user profile */
export function buildUserHtml(
  user: UserData,
  opts: MetaOptions,
): string {
  const name = escapeHtml(truncate(user.display_name, 60));
  const ratingText =
    user.rating_avg !== null
      ? ` \u2605 ${user.rating_avg.toFixed(1)} (${user.rating_count})`
      : "";
  const locationText = user.location ? ` \u2014 ${escapeHtml(user.location)}` : "";
  const description = escapeHtml(
    truncate(`${name}${ratingText}${locationText} op DeelMarkt`, 160),
  );
  const url = `${opts.siteUrl}/users/${user.id}`;
  const image = user.avatar_url
    ? ogImageUrl(user.avatar_url, opts.cloudinaryCloud)
    : `${opts.siteUrl}/icons/Icon-512.png`;

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "Person",
    name: user.display_name,
    url,
    ...(user.avatar_url ? { image: user.avatar_url } : {}),
    ...(user.location
      ? {
          address: {
            "@type": "PostalAddress",
            addressLocality: user.location,
            addressCountry: "NL",
          },
        }
      : {}),
  };

  return buildHtmlShell({
    title: `${name} | DeelMarkt`,
    description,
    url,
    image,
    type: "profile",
    jsonLd: JSON.stringify(jsonLd),
  });
}

/** Build pre-rendered HTML for the search page */
export function buildSearchHtml(
  query: string | null,
  opts: MetaOptions,
): string {
  const q = query ? escapeHtml(truncate(query, 60)) : null;
  const title = q
    ? `"${q}" zoeken | DeelMarkt`
    : "Zoeken | DeelMarkt";
  const description = q
    ? `Bekijk resultaten voor "${q}" op DeelMarkt \u2014 de eerlijke marktplaats van Nederland.`
    : "Zoek tweedehands spullen op DeelMarkt \u2014 de eerlijke marktplaats van Nederland.";
  const url = q
    ? `${opts.siteUrl}/search?q=${encodeURIComponent(query!)}`
    : `${opts.siteUrl}/search`;

  return buildHtmlShell({
    title,
    description,
    url,
    image: `${opts.siteUrl}/icons/Icon-512.png`,
    type: "website",
  });
}

/** Build pre-rendered HTML for the home page */
export function buildHomeHtml(opts: MetaOptions): string {
  return buildHtmlShell({
    title: "DeelMarkt \u2014 De eerlijke marktplaats van Nederland",
    description:
      "Koop en verkoop tweedehands met vertrouwen. Beschermd met escrow, iDEAL betaling, en geverifieerde verkopers.",
    url: opts.siteUrl,
    image: `${opts.siteUrl}/icons/Icon-512.png`,
    type: "website",
    jsonLd: JSON.stringify({
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: "DeelMarkt",
      url: opts.siteUrl,
      description:
        "De eerlijke marktplaats van Nederland. Koop en verkoop tweedehands met vertrouwen.",
      potentialAction: {
        "@type": "SearchAction",
        target: {
          "@type": "EntryPoint",
          urlTemplate: `${opts.siteUrl}/search?q={search_term_string}`,
        },
        "query-input": "required name=search_term_string",
      },
    }),
  });
}

/** Build pre-rendered HTML for the sell page */
export function buildSellHtml(opts: MetaOptions): string {
  return buildHtmlShell({
    title: "Verkoop op DeelMarkt \u2014 Veilig en eerlijk",
    description:
      "Plaats je advertentie op DeelMarkt. Escrow-bescherming, iDEAL betaling, en gratis verzendlabels.",
    url: `${opts.siteUrl}/sell`,
    image: `${opts.siteUrl}/icons/Icon-512.png`,
    type: "website",
  });
}

/** Build a generic fallback page */
export function buildFallbackHtml(
  path: string,
  opts: MetaOptions,
): string {
  return buildHtmlShell({
    title: "DeelMarkt \u2014 De eerlijke marktplaats van Nederland",
    description:
      "Koop en verkoop tweedehands met vertrouwen. Beschermd met escrow, iDEAL betaling, en geverifieerde verkopers.",
    url: `${opts.siteUrl}${path}`,
    image: `${opts.siteUrl}/icons/Icon-512.png`,
    type: "website",
  });
}

// --- Internal HTML shell builder ---

interface ShellOptions {
  title: string;
  description: string;
  url: string;
  image: string;
  type: string;
  jsonLd?: string;
  extra?: string[];
}

function buildHtmlShell(opts: ShellOptions): string {
  const extraTags = opts.extra ? opts.extra.join("\n    ") : "";

  return `<!DOCTYPE html>
<html lang="nl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>${opts.title}</title>
    <meta name="description" content="${opts.description}">

    <!-- Open Graph -->
    <meta property="og:title" content="${opts.title}">
    <meta property="og:description" content="${opts.description}">
    <meta property="og:url" content="${opts.url}">
    <meta property="og:image" content="${opts.image}">
    <meta property="og:type" content="${opts.type}">
    <meta property="og:site_name" content="DeelMarkt">
    <meta property="og:locale" content="nl_NL">
    <meta property="og:locale:alternate" content="en_GB">

    <!-- Twitter Card -->
    <meta name="twitter:card" content="summary_large_image">
    <meta name="twitter:title" content="${opts.title}">
    <meta name="twitter:description" content="${opts.description}">
    <meta name="twitter:image" content="${opts.image}">

    ${extraTags}

    ${opts.jsonLd ? `<script type="application/ld+json">${opts.jsonLd}</script>` : ""}

    <!-- Canonical URL -->
    <link rel="canonical" href="${opts.url}">

    <!-- Theme colour (design system: secondary #1E4F7A) -->
    <meta name="theme-color" content="#1E4F7A">
</head>
<body>
    <noscript>
        <h1>${opts.title}</h1>
        <p>${opts.description}</p>
        <p><a href="${opts.url}">Bekijk op DeelMarkt</a></p>
    </noscript>
</body>
</html>`;
}
