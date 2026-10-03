import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  // The site is plain files in `out/`, so it can be served by Firebase Hosting or any static host.
  output: "export",
  // There is no image server in a static export. The screenshots are already sized and the logos are SVG.
  images: { unoptimized: true },
  poweredByHeader: false,
};

export default nextConfig;
