/**
 * P-46: Route matching for dynamic OG meta tags.
 * Maps URL paths to route types for meta tag generation.
 */

export type RouteType =
  | { kind: "listing"; id: string }
  | { kind: "user"; id: string }
  | { kind: "search"; query: string | null }
  | { kind: "home" }
  | { kind: "sell" }
  | { kind: "unknown" };

/**
 * Parse a URL path into a typed route for OG tag generation.
 */
export function matchRoute(url: URL): RouteType {
  const path = url.pathname;

  // /listings/:id
  const listingMatch = path.match(/^\/listings\/([a-zA-Z0-9_-]+)$/);
  if (listingMatch) {
    return { kind: "listing", id: listingMatch[1] };
  }

  // /users/:id
  const userMatch = path.match(/^\/users\/([a-zA-Z0-9_-]+)$/);
  if (userMatch) {
    return { kind: "user", id: userMatch[1] };
  }

  // /search?q=...
  if (path === "/search") {
    return { kind: "search", query: url.searchParams.get("q") };
  }

  // / or /home
  if (path === "/" || path === "/home") {
    return { kind: "home" };
  }

  // /sell
  if (path === "/sell") {
    return { kind: "sell" };
  }

  return { kind: "unknown" };
}
