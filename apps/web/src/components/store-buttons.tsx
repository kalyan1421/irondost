import { Smartphone } from "lucide-react";
import { site } from "@/lib/site";

const base =
  "inline-flex min-h-14 items-center gap-3 rounded-2xl px-5 py-3 text-left font-semibold transition-colors";

/** Google Play always links to the live listing. The App Store button says "coming soon" until a link is configured. */
export function StoreButtons({ onDark = false }: { onDark?: boolean }) {
  const solid = onDark ? "bg-white text-ink hover:bg-mist" : "bg-ink text-white hover:bg-royal";
  const quiet = onDark ? "border border-white/40 text-white" : "border border-ring text-muted";
  return (
    <div className="flex flex-wrap gap-3">
      <a href={site.playStoreUrl} className={`${base} ${solid}`}>
        <Smartphone aria-hidden className="size-6" />
        <span>
          <span className="block text-xs font-medium opacity-80">Get it on</span>
          <span className="block text-lg leading-tight">Google Play</span>
        </span>
      </a>
      {site.appStoreUrl ? (
        <a href={site.appStoreUrl} className={`${base} ${solid}`}>
          <Smartphone aria-hidden className="size-6" />
          <span>
            <span className="block text-xs font-medium opacity-80">Download on the</span>
            <span className="block text-lg leading-tight">App Store</span>
          </span>
        </a>
      ) : (
        <p className={`${base} ${quiet}`}>
          <Smartphone aria-hidden className="size-6" />
          <span>
            <span className="block text-xs font-medium">iPhone</span>
            <span className="block text-lg leading-tight">Coming soon</span>
          </span>
        </p>
      )}
    </div>
  );
}
