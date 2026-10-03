import type { Metadata } from "next";
import { Figtree, Geist_Mono, Outfit } from "next/font/google";
import { Providers } from "@/components/providers";
import "./globals.css";

const figtree = Figtree({ variable: "--font-figtree", subsets: ["latin"] });
const geistMono = Geist_Mono({ variable: "--font-geist-mono", subsets: ["latin"] });
const outfit = Outfit({ variable: "--font-outfit", subsets: ["latin"] });

export const metadata: Metadata = {
  title: { default: "IronDost Admin", template: "%s · IronDost Admin" },
  description: "Operations console for IronDost doorstep ironing and laundry.",
  robots: { index: false, follow: false },
};

export default function RootLayout({ children }: LayoutProps<"/">) {
  return (
    <html lang="en" suppressHydrationWarning className={`${figtree.variable} ${geistMono.variable} ${outfit.variable} h-full antialiased`}>
      <body className="min-h-full bg-background">
        <Providers>{children}</Providers>
      </body>
    </html>
  );
}
