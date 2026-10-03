import type { MetadataRoute } from "next";
import { site } from "@/lib/site";

// Required for a static export: this file is turned into sitemap.xml / robots.txt at build time.
export const dynamic = "force-static";

export default function robots(): MetadataRoute.Robots {
  return { rules: { userAgent: "*", allow: "/" }, sitemap: `${site.url}/sitemap.xml` };
}
