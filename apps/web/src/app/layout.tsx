import type { Metadata } from "next";
import { Figtree, Outfit } from "next/font/google";
import { SiteFooter } from "@/components/site-footer";
import { SiteHeader } from "@/components/site-header";
import { TextReveal } from "@/components/text-reveal";
import { site } from "@/lib/site";
import "./globals.css";

const figtree = Figtree({ variable: "--font-figtree", subsets: ["latin"] });
const outfit = Outfit({ variable: "--font-outfit", subsets: ["latin"] });

export const metadata: Metadata = {
  metadataBase: new URL(site.url),
  title: { default: `${site.name}: laundry, ironing and dry cleaning at your door`, template: `%s · ${site.name}` },
  description: site.description,
  openGraph: {
    type: "website",
    siteName: site.name,
    title: `${site.name}: ${site.tagline}`,
    description: site.description,
    locale: "en_IN",
  },
  twitter: { card: "summary_large_image" },
  // Google Search Console ownership (two verification tokens issued for irondost.in, 19 Nov 2026).
  verification: {
    google: ["iqO5h0V3_QcAoFY8ITwJ32k0a4QtM0ej7kVWyX_EMxk", "ljB4b5sDZWvBPeJGzZrC0sh20hXUXCMoaGjWw_Inwh0"],
  },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" className={`${figtree.variable} ${outfit.variable} antialiased`}>
      <body className="flex min-h-screen flex-col">
        <a
          href="#main"
          className="sr-only focus:not-sr-only focus:fixed focus:left-4 focus:top-4 focus:z-50 focus:rounded-lg focus:bg-royal focus:px-4 focus:py-2 focus:text-white"
        >
          Skip to content
        </a>
        <SiteHeader />
        <main id="main" className="flex-1">
          {children}
        </main>
        <SiteFooter />
        <TextReveal />
      </body>
    </html>
  );
}
