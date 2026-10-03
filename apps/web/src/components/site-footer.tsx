import { Mail, Phone } from "lucide-react";
import Link from "next/link";
import { legalPages } from "@/lib/legal";
import { site } from "@/lib/site";
import { BrandLogo } from "./brand-logo";

export function SiteFooter() {
  return (
    <footer className="on-dark bg-ink text-white">
      <div className="mx-auto grid max-w-6xl gap-10 px-4 py-14 sm:px-6 md:grid-cols-[1.4fr_1fr_1fr]">
        <div>
          <BrandLogo reverse height={36} />
          <p className="mt-4 max-w-xs text-white/80">
            Ironing, washing and dry cleaning, picked up from and delivered to your door in {site.area}.
          </p>
        </div>

        <nav aria-label="Policies and help">
          <h2 className="font-display text-lg font-semibold">Help and policies</h2>
          <ul className="mt-4 space-y-2.5">
            <li>
              <Link href="/support" className="text-white/80 hover:text-white">
                Support
              </Link>
            </li>
            {legalPages.map((p) => (
              <li key={p.slug}>
                <Link href={`/${p.slug}`} className="text-white/80 hover:text-white">
                  {p.label}
                </Link>
              </li>
            ))}
            <li>
              <Link href="/delete-account" className="text-white/80 hover:text-white">
                Delete your account
              </Link>
            </li>
          </ul>
        </nav>

        <div>
          <h2 className="font-display text-lg font-semibold">Talk to us</h2>
          <ul className="mt-4 space-y-3">
            <li>
              <a href={`tel:${site.phone.tel}`} className="inline-flex items-center gap-2.5 text-white/80 hover:text-white">
                <Phone aria-hidden className="size-4" />
                {site.phone.display}
              </a>
            </li>
            <li>
              <a href={`mailto:${site.email}`} className="inline-flex items-center gap-2.5 break-all text-white/80 hover:text-white">
                <Mail aria-hidden className="size-4 shrink-0" />
                {site.email}
              </a>
            </li>
          </ul>
        </div>
      </div>
      <div className="border-t border-white/15">
        <p className="mx-auto max-w-6xl px-4 py-5 text-sm text-white/70 sm:px-6">
          © {new Date().getFullYear()} {site.company}. IronDost is its doorstep laundry service.
        </p>
      </div>
    </footer>
  );
}
