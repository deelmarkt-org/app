import { describe, it, expect } from "vitest";
import {
  buildListingHtml,
  buildUserHtml,
  buildSearchHtml,
  buildHomeHtml,
  buildSellHtml,
  buildFallbackHtml,
} from "../src/meta";
import type { ListingData, UserData } from "../src/supabase";

const opts = {
  siteUrl: "https://deelmarkt.com",
  cloudinaryCloud: "deelmarkt",
};

const mockListing: ListingData = {
  id: "abc-123",
  title: "Vintage design stoel",
  description: "Prachtige mid-century stoel in goede staat.",
  price_in_cents: 4500,
  condition: "Goed",
  category_name: "Meubels",
  location: "Amsterdam",
  image_urls: [
    "https://res.cloudinary.com/deelmarkt/upload/v1/listings/img1.jpg",
  ],
  seller_display_name: "Jan de Vries",
};

const mockUser: UserData = {
  id: "user-456",
  display_name: "Jan de Vries",
  avatar_url:
    "https://res.cloudinary.com/deelmarkt/upload/v1/avatars/jan.jpg",
  location: "Amsterdam",
  rating_avg: 4.8,
  rating_count: 127,
};

describe("buildListingHtml", () => {
  const html = buildListingHtml(mockListing, opts);

  it("includes OG title with price", () => {
    expect(html).toContain('og:title" content="Vintage design stoel');
    expect(html).toContain("€45,00");
  });

  it("includes OG description", () => {
    expect(html).toContain('og:description"');
    expect(html).toContain("Prachtige mid-century stoel");
  });

  it("includes OG image with Cloudinary transform", () => {
    expect(html).toContain("c_fill,w_1200,h_630,f_auto,q_auto");
  });

  it("includes OG URL", () => {
    expect(html).toContain(
      'og:url" content="https://deelmarkt.com/listings/abc-123"',
    );
  });

  it("includes OG type product", () => {
    expect(html).toContain('og:type" content="product"');
  });

  it("includes Twitter card meta", () => {
    expect(html).toContain('twitter:card" content="summary_large_image"');
  });

  it("includes JSON-LD structured data", () => {
    expect(html).toContain("application/ld+json");
    expect(html).toContain('"@type":"Product"');
    expect(html).toContain('"priceCurrency":"EUR"');
    expect(html).toContain('"price":"45.00"');
  });

  it("includes product price meta tags", () => {
    expect(html).toContain('product:price:amount" content="45.00"');
    expect(html).toContain('product:price:currency" content="EUR"');
  });

  it("includes product condition", () => {
    expect(html).toContain('product:condition" content="Goed"');
  });

  it("includes canonical URL", () => {
    expect(html).toContain(
      'rel="canonical" href="https://deelmarkt.com/listings/abc-123"',
    );
  });

  it("includes noscript fallback", () => {
    expect(html).toContain("<noscript>");
    expect(html).toContain("Bekijk op DeelMarkt");
  });

  it("uses nl locale", () => {
    expect(html).toContain('lang="nl"');
    expect(html).toContain("nl_NL");
  });
});

describe("buildListingHtml — edge cases", () => {
  it("handles listing without images", () => {
    const listing = { ...mockListing, image_urls: [] };
    const html = buildListingHtml(listing, opts);
    expect(html).toContain("Icon-512.png");
  });

  it("handles listing without description", () => {
    const listing = { ...mockListing, description: null };
    const html = buildListingHtml(listing, opts);
    expect(html).toContain("op DeelMarkt");
  });

  it("escapes HTML in title", () => {
    const listing = { ...mockListing, title: 'Stoel <script>alert("x")</script>' };
    const html = buildListingHtml(listing, opts);
    expect(html).not.toContain("<script>");
    expect(html).toContain("&lt;script&gt;");
  });

  it("maps Nieuw condition to NewCondition schema", () => {
    const listing = { ...mockListing, condition: "Nieuw" };
    const html = buildListingHtml(listing, opts);
    expect(html).toContain("NewCondition");
  });
});

describe("buildUserHtml", () => {
  const html = buildUserHtml(mockUser, opts);

  it("includes user name in title", () => {
    expect(html).toContain("Jan de Vries | DeelMarkt");
  });

  it("includes rating in description", () => {
    expect(html).toContain("4.8");
    expect(html).toContain("127");
  });

  it("includes location in description", () => {
    expect(html).toContain("Amsterdam");
  });

  it("includes OG type profile", () => {
    expect(html).toContain('og:type" content="profile"');
  });

  it("includes Person JSON-LD", () => {
    expect(html).toContain('"@type":"Person"');
  });
});

describe("buildSearchHtml", () => {
  it("includes search query in title", () => {
    const html = buildSearchHtml("fiets", opts);
    expect(html).toContain('"fiets" zoeken | DeelMarkt');
  });

  it("handles null query", () => {
    const html = buildSearchHtml(null, opts);
    expect(html).toContain("Zoeken | DeelMarkt");
  });
});

describe("buildHomeHtml", () => {
  const html = buildHomeHtml(opts);

  it("includes site title", () => {
    expect(html).toContain("De eerlijke marktplaats van Nederland");
  });

  it("includes SearchAction JSON-LD", () => {
    expect(html).toContain('"@type":"SearchAction"');
    expect(html).toContain("search_term_string");
  });
});

describe("buildSellHtml", () => {
  it("includes sell page content", () => {
    const html = buildSellHtml(opts);
    expect(html).toContain("Verkoop op DeelMarkt");
    expect(html).toContain("Escrow-bescherming");
  });
});

describe("buildFallbackHtml", () => {
  it("includes correct URL for path", () => {
    const html = buildFallbackHtml("/some/path", opts);
    expect(html).toContain("https://deelmarkt.com/some/path");
  });
});
