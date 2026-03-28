/**
 * P-46: Cloudflare Worker — Dynamic OG meta tags + crawler pre-rendering.
 *
 * Strategy (per PLAN-frontend-launch.md §SEO Strategy):
 * - Detect crawler user-agents (Googlebot, Bingbot, Facebook, Twitter, etc.)
 * - For crawlers: fetch listing/user data from Supabase, inject OG meta tags
 *   into a pre-rendered HTML shell with JSON-LD structured data
 * - For non-crawlers: pass through to Flutter SPA (origin server)
 *
 * Deployed on Cloudflare (belengaz ownership per CLAUDE.md §Developer Roles).
 */

import { isCrawler } from "./crawler.ts";
import { matchRoute } from "./routes.ts";
import { fetchListing, fetchUser } from "./supabase.ts";
import {
  buildListingHtml,
  buildUserHtml,
  buildSearchHtml,
  buildHomeHtml,
  buildSellHtml,
  buildFallbackHtml,
} from "./meta.ts";

export interface Env {
  SUPABASE_URL: string;
  SUPABASE_ANON_KEY: string;
  SITE_URL: string;
  CLOUDINARY_CLOUD: string;
}

export default {
  async fetch(
    request: Request,
    env: Env,
  ): Promise<Response> {
    const userAgent = request.headers.get("User-Agent") ?? "";

    // Non-crawlers get the standard Flutter SPA shell from origin
    if (!isCrawler(userAgent)) {
      return fetch(request);
    }

    const url = new URL(request.url);
    const route = matchRoute(url);
    const opts = {
      siteUrl: env.SITE_URL,
      cloudinaryCloud: env.CLOUDINARY_CLOUD,
    };

    let html: string;

    switch (route.kind) {
      case "listing": {
        const listing = await fetchListing(
          env.SUPABASE_URL,
          env.SUPABASE_ANON_KEY,
          route.id,
        );
        if (listing) {
          html = buildListingHtml(listing, opts);
        } else {
          // Listing not found — serve fallback with generic meta
          html = buildFallbackHtml(url.pathname, opts);
        }
        break;
      }

      case "user": {
        const user = await fetchUser(
          env.SUPABASE_URL,
          env.SUPABASE_ANON_KEY,
          route.id,
        );
        if (user) {
          html = buildUserHtml(user, opts);
        } else {
          html = buildFallbackHtml(url.pathname, opts);
        }
        break;
      }

      case "search":
        html = buildSearchHtml(route.query, opts);
        break;

      case "home":
        html = buildHomeHtml(opts);
        break;

      case "sell":
        html = buildSellHtml(opts);
        break;

      default:
        html = buildFallbackHtml(url.pathname, opts);
        break;
    }

    return new Response(html, {
      status: 200,
      headers: {
        "Content-Type": "text/html; charset=utf-8",
        "Cache-Control": "public, s-maxage=300, stale-while-revalidate=60",
        "X-Robots-Tag": "index, follow",
      },
    });
  },
};
