import type { MetadataRoute } from "next";
import { site } from "@/lib/site";

// Required for a static export: this file is turned into sitemap.xml / robots.txt at build time.
export const dynamic = "force-static";

const paths = ["", "/support", "/privacy", "/terms", "/cancellation", "/delete-account"];

export default function sitemap(): MetadataRoute.Sitemap {
  return paths.map((path) => ({ url: `${site.url}${path}`, changeFrequency: path === "" ? "weekly" : "yearly", priority: path === "" ? 1 : 0.5 }));
}
