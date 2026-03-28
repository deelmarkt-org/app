/**
 * P-46: Crawler detection for pre-rendering.
 * Matches known bot user-agents that need pre-rendered HTML with OG meta tags.
 */

const CRAWLER_PATTERNS = [
  "googlebot",
  "bingbot",
  "slurp",        // Yahoo
  "duckduckbot",
  "baiduspider",
  "yandexbot",
  "facebot",      // Facebook
  "facebookexternalhit",
  "twitterbot",
  "linkedinbot",
  "whatsapp",
  "telegrambot",
  "slackbot",
  "discordbot",
  "pinterest",
  "applebot",
  "semrushbot",
  "ahrefsbot",
  "mj12bot",
  "dotbot",
];

/**
 * Check if a User-Agent string belongs to a known crawler/bot.
 */
export function isCrawler(userAgent: string): boolean {
  if (!userAgent) return false;
  const ua = userAgent.toLowerCase();
  return CRAWLER_PATTERNS.some((pattern) => ua.includes(pattern));
}
