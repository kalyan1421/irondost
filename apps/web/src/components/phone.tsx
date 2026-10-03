import Image from "next/image";

const screens = {
  home: "/screens/home.webp",
  items: "/screens/items.webp",
  pickup: "/screens/pickup.webp",
  tracking: "/screens/tracking.webp",
  offers: "/screens/offers.webp",
} as const;

/** A screenshot of the app in a phone frame. The screenshots are 540 x 1173. */
export function Phone({
  screen,
  alt,
  className = "",
  priority = false,
}: {
  screen: keyof typeof screens;
  alt: string;
  className?: string;
  priority?: boolean;
}) {
  return (
    <div className={`overflow-hidden rounded-[2.4rem] border-[7px] border-ink bg-ink shadow-2xl shadow-ink/30 ${className}`}>
      <Image
        src={screens[screen]}
        alt={alt}
        width={540}
        height={1173}
        sizes="(min-width: 1024px) 280px, 60vw"
        priority={priority}
        className="block h-auto w-full rounded-[1.8rem]"
      />
    </div>
  );
}
