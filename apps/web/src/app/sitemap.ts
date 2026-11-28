import type { MetadataRoute } from "next";
import { areaPages } from "@/lib/areas";
import { posts } from "@/lib/posts";
import { site } from "@/lib/site";

// Required for a static export: this file is turned into sitemap.xml / robots.txt at build time.
export const dynamic = "force-static";

const paths = ["", "/laundry", "/get", "/prices", "/support", "/blog", "/privacy", "/terms", "/cancellation", "/delete-account"];

export default function sitemap(): MetadataRoute.Sitemap {
  const pages: MetadataRoute.Sitemap = paths.map((path) => ({ url: `${site.url}${path}`, changeFrequency: path === "" || path === "/laundry" || path === "/get" ? "weekly" : "yearly", priority: path === "" ? 1 : path === "/laundry" ? 0.9 : 0.5 }));
  const articles: MetadataRoute.Sitemap = posts.map((p) => ({ url: `${site.url}/blog/${p.slug}`, lastModified: p.updated, changeFrequency: "monthly", priority: 0.7 }));
  const areas: MetadataRoute.Sitemap = areaPages.map((a) => ({ url: `${site.url}/laundry/${a.slug}`, changeFrequency: "monthly", priority: 0.8 }));
  return [...pages, ...areas, ...articles];
}
