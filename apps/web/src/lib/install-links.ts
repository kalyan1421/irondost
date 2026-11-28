import { site } from "@/lib/site";

/**
 * Install attribution. Links like /get?src=ig&c=reel-ironing carry where a visitor came from; the Play Store link passes it on
 * as an install `referrer`, which the app can read once with the Play Install Referrer API.
 * src: ig (Instagram auto-DM), bag (bag tags), rwa (society posters), web (this site's own pages), ref (referral links).
 */

/** Keep only short, URL-safe tokens: anything else in a query string is dropped. */
export function cleanToken(value: string | null | undefined, max = 40): string {
  if (!value) return "";
  const v = value.trim().toLowerCase();
  return /^[a-z0-9_-]+$/.test(v) ? v.slice(0, max) : "";
}

/** The Play Store listing with `referrer=utm_source=<src>&utm_campaign=<c>` added. With neither, the plain listing. */
export function playStoreUrl(src?: string, campaign?: string): string {
  const s = cleanToken(src);
  const c = cleanToken(campaign);
  if (!s && !c) return site.playStoreUrl;
  const referrer = new URLSearchParams();
  if (s) referrer.set("utm_source", s);
  referrer.set("utm_medium", s === "web" ? "website" : "get_page");
  if (c) referrer.set("utm_campaign", c);
  const url = new URL(site.playStoreUrl);
  url.searchParams.set("referrer", referrer.toString());
  return url.toString();
}

/** A /get link for printed material and posts, for example getLink("bag") → /get?src=bag. */
export function getLink(src: string, campaign?: string): string {
  const q = new URLSearchParams({ src });
  if (campaign) q.set("c", campaign);
  return `/get?${q.toString()}`;
}
