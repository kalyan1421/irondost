import { Smartphone } from "lucide-react";
import { site } from "@/lib/site";

const base =
  "inline-flex min-h-14 items-center gap-3 rounded-2xl px-5 py-3 text-left font-semibold transition-colors";

type Props = {
  onDark?: boolean;
  /** The Play Store link to use, for example with an install referrer from lib/install-links. Defaults to the plain listing. */
  playUrl?: string;
  /** Put the App Store button first (iPhone visitors). */
  appleFirst?: boolean;
};

/** Google Play always links to the live listing. The App Store button says "coming soon" until a link is configured. */
export function StoreButtons({ onDark = false, playUrl = site.playStoreUrl, appleFirst = false }: Props) {
  const solid = onDark ? "bg-white text-ink hover:bg-mist" : "bg-ink text-white hover:bg-royal";
  const quiet = onDark ? "border border-white/40 text-white" : "border border-ring text-muted";
  const play = (
    <a key="play" href={playUrl} className={`${base} ${solid}`}>
      <Smartphone aria-hidden className="size-6" />
      <span>
        <span className="block text-xs font-medium opacity-80">Get it on</span>
        <span className="block text-lg leading-tight">Google Play</span>
      </span>
    </a>
  );
  const apple = site.appStoreUrl ? (
    <a key="apple" href={site.appStoreUrl} className={`${base} ${solid}`}>
      <Smartphone aria-hidden className="size-6" />
      <span>
        <span className="block text-xs font-medium opacity-80">Download on the</span>
        <span className="block text-lg leading-tight">App Store</span>
      </span>
    </a>
  ) : (
    <p key="apple" className={`${base} ${quiet}`}>
      <Smartphone aria-hidden className="size-6" />
      <span>
        <span className="block text-xs font-medium">iPhone</span>
        <span className="block text-lg leading-tight">Coming soon</span>
      </span>
    </p>
  );
  return <div className="flex flex-wrap gap-3">{appleFirst ? [apple, play] : [play, apple]}</div>;
}
