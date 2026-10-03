import { Menu } from "lucide-react";
import Link from "next/link";
import { BrandLogo } from "./brand-logo";

const links = [
  { href: "/#how-it-works", label: "How it works" },
  { href: "/#services", label: "Services" },
  { href: "/#faq", label: "Questions" },
  { href: "/support", label: "Support" },
];

export function SiteHeader() {
  return (
    <header className="sticky top-0 z-40 border-b border-ring bg-white/95 backdrop-blur">
      <div className="mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6">
        <Link href="/" aria-label="IronDost home" className="shrink-0">
          <BrandLogo height={34} />
        </Link>

        <nav aria-label="Main" className="hidden items-center gap-7 md:flex">
          {links.map((l) => (
            <Link key={l.href} href={l.href} className="font-medium text-ink hover:text-royal">
              {l.label}
            </Link>
          ))}
        </nav>

        <div className="flex items-center gap-2">
          <Link
            href="/#download"
            className="rounded-xl bg-royal px-4 py-2.5 font-semibold text-white hover:bg-royal-dark"
          >
            Get the app
          </Link>
          {/* No JavaScript needed: a details element opens and closes the menu. */}
          <details className="relative md:hidden">
            <summary
              aria-label="Menu"
              className="flex size-11 cursor-pointer items-center justify-center rounded-xl border border-ring text-ink"
            >
              <Menu aria-hidden className="size-5" />
            </summary>
            <nav
              aria-label="Main"
              className="absolute right-0 top-14 flex w-56 flex-col rounded-2xl border border-ring bg-white p-2 shadow-lg"
            >
              {links.map((l) => (
                <Link key={l.href} href={l.href} className="rounded-xl px-4 py-3 font-medium text-ink hover:bg-mist">
                  {l.label}
                </Link>
              ))}
            </nav>
          </details>
        </div>
      </div>
    </header>
  );
}
