/**
 * P-46: Sitemap generation Edge Function.
 * Generates XML sitemaps for crawlable listing and user profile URLs.
 *
 * Routes:
 *   GET /functions/v1/sitemap            → sitemap index
 *   GET /functions/v1/sitemap?type=pages → static pages sitemap
 *   GET /functions/v1/sitemap?type=listings&page=1 → listings sitemap (paginated)
 *
 * Per PLAN-frontend-launch.md: sitemap generation via Edge Function for crawlable listing URLs.
 */

import "@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

const SITE_URL = Deno.env.get("SITE_URL") ?? "https://deelmarkt.com";
const LISTINGS_PER_PAGE = 1000;

const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const supabase = createClient(supabaseUrl, serviceRoleKey);

Deno.serve(async (req: Request) => {
  if (req.method !== "GET") {
    return new Response("Method not allowed", { status: 405 });
  }

  const url = new URL(req.url);
  const type = url.searchParams.get("type");

  try {
    if (type === "pages") {
      return xmlResponse(await buildStaticSitemap());
    }

    if (type === "listings") {
      const page = parseInt(url.searchParams.get("page") ?? "1", 10);
      return xmlResponse(await buildListingsSitemap(page));
    }

    // Default: sitemap index
    return xmlResponse(await buildSitemapIndex());
  } catch (err) {
    console.error("Sitemap generation error:", err);
    return new Response("Internal server error", { status: 500 });
  }
});

/** Build sitemap index pointing to individual sitemaps. */
async function buildSitemapIndex(): Promise<string> {
  // Count total listings to determine number of paginated sitemaps
  const { count, error } = await supabase
    .from("listings")
    .select("id", { count: "exact", head: true })
    .eq("status", "active");

  if (error) throw error;

  const totalListings = count ?? 0;
  const totalPages = Math.max(1, Math.ceil(totalListings / LISTINGS_PER_PAGE));
  const now = new Date().toISOString().split("T")[0];

  const sitemaps = [
    `  <sitemap>
    <loc>${SITE_URL}/functions/v1/sitemap?type=pages</loc>
    <lastmod>${now}</lastmod>
  </sitemap>`,
  ];

  for (let page = 1; page <= totalPages; page++) {
    sitemaps.push(`  <sitemap>
    <loc>${SITE_URL}/functions/v1/sitemap?type=listings&amp;page=${page}</loc>
    <lastmod>${now}</lastmod>
  </sitemap>`);
  }

  return `<?xml version="1.0" encoding="UTF-8"?>
<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${sitemaps.join("\n")}
</sitemapindex>`;
}

/** Build sitemap for static pages. */
async function buildStaticSitemap(): Promise<string> {
  const now = new Date().toISOString().split("T")[0];

  const pages = [
    { loc: "/", changefreq: "daily", priority: "1.0" },
    { loc: "/search", changefreq: "daily", priority: "0.8" },
    { loc: "/sell", changefreq: "monthly", priority: "0.6" },
  ];

  const urls = pages
    .map(
      (p) => `  <url>
    <loc>${SITE_URL}${p.loc}</loc>
    <lastmod>${now}</lastmod>
    <changefreq>${p.changefreq}</changefreq>
    <priority>${p.priority}</priority>
  </url>`,
    )
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>`;
}

/** Build paginated listings sitemap. */
async function buildListingsSitemap(page: number): Promise<string> {
  const offset = (page - 1) * LISTINGS_PER_PAGE;

  const { data: listings, error } = await supabase
    .from("listings")
    .select("id, updated_at")
    .eq("status", "active")
    .order("updated_at", { ascending: false })
    .range(offset, offset + LISTINGS_PER_PAGE - 1);

  if (error) throw error;

  const urls = (listings ?? [])
    .map(
      (l: { id: string; updated_at: string }) => `  <url>
    <loc>${SITE_URL}/listings/${l.id}</loc>
    <lastmod>${l.updated_at.split("T")[0]}</lastmod>
    <changefreq>weekly</changefreq>
    <priority>0.7</priority>
  </url>`,
    )
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
${urls}
</urlset>`;
}

/** Return XML response with correct headers. */
function xmlResponse(body: string): Response {
  return new Response(body, {
    status: 200,
    headers: {
      "Content-Type": "application/xml; charset=utf-8",
      "Cache-Control": "public, s-maxage=3600, stale-while-revalidate=600",
    },
  });
}
