"use client";

import { usePathname } from "next/navigation";
import { useEffect } from "react";

/**
 * Text reveal on scroll. Headings, lead paragraphs and anything marked `data-reveal` rise out of a mask as they
 * enter the viewport. The page is fully visible without JavaScript and with reduced motion: elements are only
 * hidden (class `reveal-ready`) by this script, right before it starts watching them, and anything already on
 * screen is revealed at once. The homepage journey animates its own copy and is left alone.
 */
const SELECTOR = "main h1, main h2, main h3, main [data-reveal]";

export function TextReveal() {
  const pathname = usePathname();

  useEffect(() => {
    if (matchMedia("(prefers-reduced-motion: reduce)").matches || !("IntersectionObserver" in window)) return;
    const els = [...document.querySelectorAll<HTMLElement>(SELECTOR)].filter(
      // Skip the journey (it animates its own copy) and text inside a card that already reveals as a whole.
      (el) => !el.closest(".journey-stage, [data-no-reveal]") && !el.parentElement?.closest("[data-reveal]"),
    );
    const io = new IntersectionObserver(
      (entries) => {
        for (const e of entries) {
          if (!e.isIntersecting) continue;
          e.target.classList.add("is-revealed");
          io.unobserve(e.target);
        }
      },
      { rootMargin: "0px 0px -8% 0px", threshold: 0.1 },
    );
    els.forEach((el) => {
      const r = el.getBoundingClientRect();
      if (r.top < innerHeight && r.bottom > 0) return; // already visible: never hide it
      el.classList.add("reveal-ready");
      // Stagger siblings in the same grid or list a little.
      const i = el.parentElement ? [...el.parentElement.children].indexOf(el) : 0;
      el.style.setProperty("--reveal-delay", `${Math.min(i, 5) * 70}ms`);
      io.observe(el);
    });
    return () => {
      io.disconnect();
      els.forEach((el) => el.classList.remove("reveal-ready", "is-revealed"));
    };
  }, [pathname]);

  return null;
}
