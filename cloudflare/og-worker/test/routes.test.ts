import { describe, it, expect } from "vitest";
import { matchRoute } from "../src/routes";

describe("matchRoute", () => {
  it("matches listing detail route", () => {
    const url = new URL("https://deelmarkt.com/listings/abc-123");
    expect(matchRoute(url)).toEqual({ kind: "listing", id: "abc-123" });
  });

  it("matches listing with UUID id", () => {
    const url = new URL(
      "https://deelmarkt.com/listings/550e8400-e29b-41d4-a716-446655440000",
    );
    expect(matchRoute(url)).toEqual({
      kind: "listing",
      id: "550e8400-e29b-41d4-a716-446655440000",
    });
  });

  it("matches user profile route", () => {
    const url = new URL("https://deelmarkt.com/users/user-456");
    expect(matchRoute(url)).toEqual({ kind: "user", id: "user-456" });
  });

  it("matches search with query", () => {
    const url = new URL("https://deelmarkt.com/search?q=fiets");
    expect(matchRoute(url)).toEqual({ kind: "search", query: "fiets" });
  });

  it("matches search without query", () => {
    const url = new URL("https://deelmarkt.com/search");
    expect(matchRoute(url)).toEqual({ kind: "search", query: null });
  });

  it("matches home route /", () => {
    const url = new URL("https://deelmarkt.com/");
    expect(matchRoute(url)).toEqual({ kind: "home" });
  });

  it("matches home route /home", () => {
    const url = new URL("https://deelmarkt.com/home");
    expect(matchRoute(url)).toEqual({ kind: "home" });
  });

  it("matches sell route", () => {
    const url = new URL("https://deelmarkt.com/sell");
    expect(matchRoute(url)).toEqual({ kind: "sell" });
  });

  it("returns unknown for unmatched routes", () => {
    const url = new URL("https://deelmarkt.com/settings");
    expect(matchRoute(url)).toEqual({ kind: "unknown" });
  });

  it("does not match nested listing paths", () => {
    const url = new URL("https://deelmarkt.com/listings/abc/edit");
    expect(matchRoute(url)).toEqual({ kind: "unknown" });
  });
});
