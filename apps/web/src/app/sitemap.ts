import type { MetadataRoute } from "next";
import { posts } from "@/lib/posts";
import { site } from "@/lib/site";

// Required for a static export: this file is turned into sitemap.xml / robots.txt at build time.
export const dynamic = "force-static";

const paths = ["", "/prices", "/support", "/blog", "/privacy", "/terms", "/cancellation", "/delete-account"];

export default function sitemap(): MetadataRoute.Sitemap {
  const pages: MetadataRoute.Sitemap = paths.map((path) => ({ url: `${site.url}${path}`, changeFrequency: path === "" ? "weekly" : "yearly", priority: path === "" ? 1 : 0.5 }));
  const articles: MetadataRoute.Sitemap = posts.map((p) => ({ url: `${site.url}/blog/${p.slug}`, lastModified: p.updated, changeFrequency: "monthly", priority: 0.7 }));
  return [...pages, ...articles];
}
