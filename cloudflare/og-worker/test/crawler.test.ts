import { describe, it, expect } from "vitest";
import { isCrawler } from "../src/crawler";

describe("isCrawler", () => {
  it("detects Googlebot", () => {
    expect(
      isCrawler(
        "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)",
      ),
    ).toBe(true);
  });

  it("detects Bingbot", () => {
    expect(
      isCrawler(
        "Mozilla/5.0 (compatible; bingbot/2.0; +http://www.bing.com/bingbot.htm)",
      ),
    ).toBe(true);
  });

  it("detects Facebook external hit", () => {
    expect(isCrawler("facebookexternalhit/1.1")).toBe(true);
  });

  it("detects Twitter bot", () => {
    expect(isCrawler("Twitterbot/1.0")).toBe(true);
  });

  it("detects LinkedIn bot", () => {
    expect(isCrawler("LinkedInBot/1.0")).toBe(true);
  });

  it("detects WhatsApp", () => {
    expect(isCrawler("WhatsApp/2.23.20.0")).toBe(true);
  });

  it("detects Telegram bot", () => {
    expect(isCrawler("TelegramBot (like TwitterBot)")).toBe(true);
  });

  it("detects Slack bot", () => {
    expect(isCrawler("Slackbot-LinkExpanding 1.0")).toBe(true);
  });

  it("detects Discord bot", () => {
    expect(isCrawler("Mozilla/5.0 (compatible; Discordbot/2.0)")).toBe(true);
  });

  it("returns false for regular Chrome browser", () => {
    expect(
      isCrawler(
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36",
      ),
    ).toBe(false);
  });

  it("returns false for mobile Safari", () => {
    expect(
      isCrawler(
        "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 Safari/604.1",
      ),
    ).toBe(false);
  });

  it("returns false for empty user agent", () => {
    expect(isCrawler("")).toBe(false);
  });

  it("is case-insensitive", () => {
    expect(isCrawler("GOOGLEBOT")).toBe(true);
    expect(isCrawler("GoogleBot/2.1")).toBe(true);
  });
});
