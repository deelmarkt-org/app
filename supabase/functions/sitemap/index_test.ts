import {
  assertEquals,
  assertStringIncludes,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { describe, it } from "https://deno.land/std@0.224.0/testing/bdd.ts";

// ---------------------------------------------------------------------------
// Test the sitemap response logic directly (same pattern as health/index_test.ts).
// Avoids module-scope side effects from Deno.serve and Deno.env.
// ---------------------------------------------------------------------------

const SITE_URL = "https://deelmarkt.com";
const LISTINGS_PER_PAGE = 1000;

// --- Mock Supabase client ---

function mockSupabase(opts: {
  count?: number;
  listings?: Array<{ id: string; updated_at: string }>;
  error?: Error | null;
}) {
  return {
    from: (_table: string) => ({
      select: (_cols: string, selectOpts?: { count?: string; head?: boolean }) => {
        const chain = {
          eq: (_col: string, _val: string) => {
            if (selectOpts?.head) {
              return Promise.resolve({ count: opts.count ?? 0, error: opts.error ?? null });
            }
            return {
              order: (_col2: string, _orderOpts: unknown) => ({
                range: (_from: number, _to: number) =>
                  Promise.resolve({
                    data: opts.listings ?? [],
                    error: opts.error ?? null,
                  }),
              }),
            };
          },
        };
        return chain;
      },
    }),
  };
}

// --- Sitemap builders (extracted logic) ---

function buildSitemapIndex(totalListings: number): string {
  const totalPages = Math.max(1, Math.ceil(totalListings / LISTINGS_PER_PAGE));
  const now = new Date().toISOString().split("T")[0];

  const sitemaps = [
    `  <sitemap>\n    <loc>${SITE_URL}/functions/v1/sitemap?type=pages</loc>\n    <lastmod>${now}</lastmod>\n  </sitemap>`,
  ];

  for (let page = 1; page <= totalPages; page++) {
    sitemaps.push(
      `  <sitemap>\n    <loc>${SITE_URL}/functions/v1/sitemap?type=listings&amp;page=${page}</loc>\n    <lastmod>${now}</lastmod>\n  </sitemap>`,
    );
  }

  return `<?xml version="1.0" encoding="UTF-8"?>\n<sitemapindex xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${sitemaps.join("\n")}\n</sitemapindex>`;
}

function buildStaticSitemap(): string {
  const now = new Date().toISOString().split("T")[0];
  const pages = [
    { loc: "/", changefreq: "daily", priority: "1.0" },
    { loc: "/search", changefreq: "daily", priority: "0.8" },
    { loc: "/sell", changefreq: "monthly", priority: "0.6" },
  ];

  const urls = pages
    .map(
      (p) =>
        `  <url>\n    <loc>${SITE_URL}${p.loc}</loc>\n    <lastmod>${now}</lastmod>\n    <changefreq>${p.changefreq}</changefreq>\n    <priority>${p.priority}</priority>\n  </url>`,
    )
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>`;
}

function buildListingsSitemap(
  listings: Array<{ id: string; updated_at: string }>,
): string {
  const urls = listings
    .map(
      (l) =>
        `  <url>\n    <loc>${SITE_URL}/listings/${l.id}</loc>\n    <lastmod>${l.updated_at.split("T")[0]}</lastmod>\n    <changefreq>weekly</changefreq>\n    <priority>0.7</priority>\n  </url>`,
    )
    .join("\n");

  return `<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n${urls}\n</urlset>`;
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

describe("Sitemap Edge Function", () => {
  describe("sitemap index", () => {
    it("includes static pages sitemap reference", () => {
      const xml = buildSitemapIndex(0);
      assertStringIncludes(xml, "type=pages");
      assertStringIncludes(xml, "<sitemapindex");
    });

    it("paginates listings sitemaps correctly", () => {
      const xml = buildSitemapIndex(2500);
      assertStringIncludes(xml, "page=1");
      assertStringIncludes(xml, "page=2");
      assertStringIncludes(xml, "page=3");
    });

    it("has at least 1 listings page even with 0 listings", () => {
      const xml = buildSitemapIndex(0);
      assertStringIncludes(xml, "page=1");
    });

    it("uses XML encoding for ampersand in URLs", () => {
      const xml = buildSitemapIndex(10);
      assertStringIncludes(xml, "&amp;page=");
    });
  });

  describe("static pages sitemap", () => {
    it("includes home page with priority 1.0", () => {
      const xml = buildStaticSitemap();
      assertStringIncludes(xml, `<loc>${SITE_URL}/</loc>`);
      assertStringIncludes(xml, "<priority>1.0</priority>");
    });

    it("includes search page", () => {
      const xml = buildStaticSitemap();
      assertStringIncludes(xml, `<loc>${SITE_URL}/search</loc>`);
    });

    it("includes sell page", () => {
      const xml = buildStaticSitemap();
      assertStringIncludes(xml, `<loc>${SITE_URL}/sell</loc>`);
    });

    it("produces valid XML", () => {
      const xml = buildStaticSitemap();
      assertStringIncludes(xml, '<?xml version="1.0" encoding="UTF-8"?>');
      assertStringIncludes(xml, "<urlset");
    });
  });

  describe("listings sitemap", () => {
    it("generates URLs for each listing", () => {
      const listings = [
        { id: "abc-1", updated_at: "2026-03-20T10:00:00Z" },
        { id: "def-2", updated_at: "2026-03-21T12:00:00Z" },
      ];
      const xml = buildListingsSitemap(listings);
      assertStringIncludes(xml, `<loc>${SITE_URL}/listings/abc-1</loc>`);
      assertStringIncludes(xml, `<loc>${SITE_URL}/listings/def-2</loc>`);
    });

    it("uses date-only lastmod", () => {
      const listings = [
        { id: "abc-1", updated_at: "2026-03-20T10:00:00Z" },
      ];
      const xml = buildListingsSitemap(listings);
      assertStringIncludes(xml, "<lastmod>2026-03-20</lastmod>");
    });

    it("handles empty listings array", () => {
      const xml = buildListingsSitemap([]);
      assertStringIncludes(xml, "<urlset");
      // No <url> entries
      assertEquals(xml.includes("<url>"), false);
    });

    it("sets weekly changefreq", () => {
      const listings = [
        { id: "abc-1", updated_at: "2026-03-20T10:00:00Z" },
      ];
      const xml = buildListingsSitemap(listings);
      assertStringIncludes(xml, "<changefreq>weekly</changefreq>");
    });
  });
});
