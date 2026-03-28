/**
 * P-46: Lightweight Supabase REST client for fetching listing/user data.
 * Used by the Cloudflare Worker to build OG meta tags from real data.
 */

export interface ListingData {
  id: string;
  title: string;
  description: string | null;
  price_in_cents: number;
  condition: string | null;
  category_name: string | null;
  location: string | null;
  image_urls: string[];
  seller_display_name: string | null;
}

export interface UserData {
  id: string;
  display_name: string;
  avatar_url: string | null;
  location: string | null;
  rating_avg: number | null;
  rating_count: number;
}

/**
 * Fetch listing data from Supabase REST API.
 * Uses the anon key — only reads public listing data (RLS enforced).
 */
export async function fetchListing(
  supabaseUrl: string,
  anonKey: string,
  listingId: string,
): Promise<ListingData | null> {
  const url = `${supabaseUrl}/rest/v1/listings?id=eq.${encodeURIComponent(listingId)}&select=id,title,description,price_in_cents,condition,category_name,location,image_urls,seller_display_name&limit=1`;

  const res = await fetch(url, {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${anonKey}`,
      Accept: "application/json",
    },
  });

  if (!res.ok) return null;

  const rows: ListingData[] = await res.json();
  return rows.length > 0 ? rows[0] : null;
}

/**
 * Fetch user profile data from Supabase REST API.
 */
export async function fetchUser(
  supabaseUrl: string,
  anonKey: string,
  userId: string,
): Promise<UserData | null> {
  const url = `${supabaseUrl}/rest/v1/profiles?id=eq.${encodeURIComponent(userId)}&select=id,display_name,avatar_url,location,rating_avg,rating_count&limit=1`;

  const res = await fetch(url, {
    headers: {
      apikey: anonKey,
      Authorization: `Bearer ${anonKey}`,
      Accept: "application/json",
    },
  });

  if (!res.ok) return null;

  const rows: UserData[] = await res.json();
  return rows.length > 0 ? rows[0] : null;
}
