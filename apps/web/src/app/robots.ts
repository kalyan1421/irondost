import type { MetadataRoute } from "next";
import { site } from "@/lib/site";

// Required for a static export: this file is turned into sitemap.xml / robots.txt at build time.
export const dynamic = "force-static";

/**
 * Everything is public. Search and AI answer crawlers are named explicitly so that a later blanket rule
 * cannot shut them out by accident: being quoted by answer engines is the point of the guides.
 */
const answerBots = [
  "Googlebot",
  "Bingbot",
  "Google-Extended",
  "Applebot",
  "Applebot-Extended",
  "OAI-SearchBot",
  "GPTBot",
  "ChatGPT-User",
  "ClaudeBot",
  "Claude-SearchBot",
  "Claude-User",
  "PerplexityBot",
  "Perplexity-User",
];

export default function robots(): MetadataRoute.Robots {
  return {
    rules: [{ userAgent: answerBots, allow: "/" }, { userAgent: "*", allow: "/" }],
    sitemap: `${site.url}/sitemap.xml`,
  };
}
