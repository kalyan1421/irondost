"use client";

import { useEffect, useRef, type ReactNode } from "react";
import { PressBoard } from "./press-board";
import { StoreButtons } from "@/components/store-buttons";

/**
 * The homepage journey: one continuous camera move through the story the owner asked for
 * (a suit or saree dry-cleaned properly, the app, pickup and delivery, then what it costs).
 *
 * One sticky stage holds every scene at once. Scroll drives a single number; each scene's photo keeps a slow
 * push-in and dissolves into the next while the push-in carries on, so there is no cut and no pinned block.
 * Copy fades in and out over its scene. With reduced motion the push-in stops; scenes still change by opacity.
 */

type Scene = {
  id: string;
  /** Share of the scroll this scene gets. The peak gets the most. */
  weight: number;
  /** Desktop (16:9) and phone (portrait) crops under /redesign. Omit for a plain backdrop. */
  img?: string;
  alt?: string;
  /** Where the copy sits: left column over a light scrim, or the full stage for the custom layouts. */
  layout: "left" | "right" | "press" | "app";
  /** Direction of the slow pan in percent, so consecutive scenes feel like one move. */
  pan?: [number, number];
  /** Camera zoom: how far the photo pushes in over the scene, and the detail it pushes towards (CSS transform-origin). */
  zoom?: { to: number; focus: string };
  copy: ReactNode;
};

/** Default push-in when a scene names no zoom. */
const ZOOM = { to: 1.12, focus: "55% 50%" };
/** Extra push the outgoing photo gets while it dissolves, so each change reads as the camera moving through. */
const ZOOM_THROUGH = 0.1;

const hours = ["7 to 11 am", "11 am to 4 pm", "4 to 8 pm"];

const scenes: Scene[] = [
  {
    id: "ready",
    zoom: { to: 1.24, focus: "74% 58%" },
    weight: 1.05,
    img: "hero-suit-cover",
    alt: "A charcoal suit and a maroon silk saree with a gold zari border, each on a hanger in a clear cover, beside a window.",
    layout: "left",
    pan: [1.5, 0],
    copy: (
      <>
        <p className="journey-kicker">Ironing · Wash and iron · Dry cleaning · LB Nagar, Hyderabad</p>
        <h1 className="journey-title">
          Your best suit and silk saree, <span className="text-royal">dry-cleaned properly.</span>
        </h1>
        <p className="journey-body">
          IronDost picks up from your door and brings everything back pressed, usually the next day. You book in the app in a minute.
        </p>
        <a href="#book" className="journey-cta">
          Book a pickup
        </a>
      </>
    ),
  },
  {
    id: "suit",
    zoom: { to: 1.26, focus: "46% 40%" },
    weight: 1,
    img: "suit-steam",
    alt: "Hands pressing the lapel of a navy suit jacket with a steam iron on a padded pressing table.",
    layout: "right",
    pan: [-1.5, 0],
    copy: (
      <>
        <h2 className="journey-title">Suits pressed the way a tailor would.</h2>
        <p className="journey-body">Lapels, collar and cuffs by hand, with steam. Then onto a hanger and into a cover, so nothing creases on the way back.</p>
      </>
    ),
  },
  {
    id: "saree",
    zoom: { to: 1.22, focus: "52% 72%" },
    weight: 1,
    img: "saree-zari",
    alt: "Hands folding a maroon silk saree on tissue paper with the gold zari border turned inside.",
    layout: "left",
    pan: [1.2, -0.6],
    copy: (
      <>
        <h2 className="journey-title">Silk sarees, folded with the zari inside.</h2>
        <p className="journey-body">
          Show us every stain when you hand it over. We will try to remove it, and we will tell you honestly if something does not come out.
        </p>
      </>
    ),
  },
  {
    id: "press",
    weight: 2.1,
    layout: "press",
    copy: (
      <>
        <h2 className="journey-title">Press this one yourself.</h2>
        <p className="journey-body">Drag across the jacket. It is the only one you will ever have to press.</p>
      </>
    ),
  },
  {
    id: "app",
    zoom: { to: 1.08, focus: "60% 50%" },
    weight: 1.1,
    img: "app-table",
    alt: "A quiet side table by a window with a cup of chai and a plant.",
    layout: "app",
    pan: [-1, 0],
    copy: (
      <>
        <h2 className="journey-title">Book on iPhone or Android.</h2>
        <p className="journey-body">Choose your clothes, pick a time, confirm. A rough count is fine: your partner checks it with you at the door.</p>
        <div className="mt-6">
          <StoreButtons />
        </div>
      </>
    ),
  },
  {
    id: "pickup",
    zoom: { to: 1.2, focus: "58% 48%" },
    weight: 1,
    img: "doorstep-handover",
    alt: "A cloth bag of clothes handed over at an apartment door.",
    layout: "left",
    pan: [1.6, 0],
    copy: (
      <>
        <h2 className="journey-title">Pick a window. We are at your door.</h2>
        <ul className="mt-6 flex flex-wrap gap-2.5" aria-label="Pickup windows, every day">
          {hours.map((h) => (
            <li key={h} className="rounded-full bg-ink px-4 py-2 text-base font-semibold text-white">
              {h}
            </li>
          ))}
        </ul>
        <p className="journey-body">Every day of the week. Your partner counts the clothes with you before anything leaves.</p>
      </>
    ),
  },
  {
    id: "delivery",
    zoom: { to: 1.16, focus: "50% 45%" },
    weight: 1,
    img: "delivery-door",
    alt: "A suit in a clear cover and a sealed bundle of pressed clothes handed back at the door.",
    layout: "left",
    pan: [-1.4, 0],
    copy: (
      <>
        <h2 className="journey-title">Back at your door, usually the next day.</h2>
        <p className="journey-body">Track every step in the app. Pay online with UPI, card or netbanking, or in cash when it arrives.</p>
      </>
    ),
  },
  {
    id: "cost",
    zoom: { to: 1.14, focus: "55% 55%" },
    weight: 1.15,
    img: "finished-bed",
    alt: "Pressed shirts, a folded silk saree and a suit in its cover laid out on a bed, ready to wear.",
    layout: "left",
    pan: [0.8, 0.4],
    copy: (
      <>
        <h2 className="journey-title">And what it costs?</h2>
        <p className="journey-body">
          Every price is in the app, per piece, before you confirm. The total changes only if the count at your door is different.
        </p>
        <a href="/prices" className="mt-4 inline-block font-semibold text-royal underline underline-offset-4">
          See the rate card
        </a>
        <a href="#book" className="journey-cta">
          Book a pickup
        </a>
      </>
    ),
  },
];

const total = scenes.reduce((s, x) => s + x.weight, 0);
const starts = scenes.reduce<number[]>((acc, s, i) => [...acc, i === 0 ? 0 : acc[i - 1] + scenes[i - 1].weight], []);
/** Half-width of each dissolve, in scene units. */
const DISSOLVE = 0.22;

const smooth = (t: number) => {
  const x = Math.min(1, Math.max(0, t));
  return x * x * (3 - 2 * x);
};

export function Journey({ phones }: { phones: ReactNode }) {
  const rootRef = useRef<HTMLDivElement>(null);
  const layerRefs = useRef<(HTMLDivElement | null)[]>([]);
  const copyRefs = useRef<(HTMLDivElement | null)[]>([]);
  const railRef = useRef<HTMLSpanElement>(null);

  useEffect(() => {
    const root = rootRef.current!;
    const reduce = matchMedia("(prefers-reduced-motion: reduce)");
    let raf = 0;
    let target = 0;
    let shown = -1;

    const frame = () => {
      raf = 0;
      // Ease towards the scroll position so wheel steps read as one glide.
      const u = shown < 0 || reduce.matches ? target : shown + (target - shown) * 0.18;
      shown = Math.abs(u - target) < 0.0005 ? target : u;
      scenes.forEach((s, i) => {
        const a = starts[i];
        const b = a + s.weight;
        const fadeIn = i === 0 ? 1 : smooth((shown - (a - DISSOLVE)) / (2 * DISSOLVE));
        const fadeOut = i === scenes.length - 1 ? 1 : 1 - smooth((shown - (b - DISSOLVE)) / (2 * DISSOLVE));
        const o = Math.min(fadeIn, fadeOut);
        const layer = layerRefs.current[i];
        if (layer) {
          layer.style.opacity = o.toFixed(3);
          layer.style.visibility = o > 0.001 ? "visible" : "hidden";
          const local = (shown - (a - DISSOLVE)) / (s.weight + 2 * DISSOLVE);
          const k = Math.min(1, Math.max(0, local));
          if (!reduce.matches) {
            const [px, py] = s.pan ?? [0, 0];
            const z = s.zoom ?? ZOOM;
            // Ease in and out so the push starts and settles gently; the dissolve adds a final push-through.
            const through = i === scenes.length - 1 ? 0 : ZOOM_THROUGH * (1 - fadeOut);
            layer.style.setProperty("--scale", (1.02 + (z.to - 1.02) * smooth(k) + through).toFixed(4));
            layer.style.setProperty("--focus", z.focus);
            layer.style.setProperty("--x", `${(px * (k - 0.5) * 2).toFixed(3)}%`);
            layer.style.setProperty("--y", `${(py * (k - 0.5) * 2).toFixed(3)}%`);
          } else {
            layer.style.setProperty("--scale", "1");
            layer.style.setProperty("--x", "0%");
            layer.style.setProperty("--y", "0%");
          }
        }
        const copy = copyRefs.current[i];
        if (copy) {
          const cin = i === 0 ? 1 : smooth((shown - (a - 0.02)) / 0.2);
          const cout = i === scenes.length - 1 ? 1 : 1 - smooth((shown - (b - 0.2)) / 0.18);
          const c = Math.min(cin, cout);
          copy.style.opacity = c.toFixed(3);
          copy.style.transform = reduce.matches ? "none" : `translateY(${((1 - cin) * 24 - (1 - cout) * 24).toFixed(1)}px)`;
          copy.style.visibility = c > 0.01 ? "visible" : "hidden";
          copy.inert = c < 0.5;
        }
      });
      if (railRef.current) railRef.current.style.transform = `scaleY(${(shown / total).toFixed(4)})`;
      if (shown !== target) raf = requestAnimationFrame(frame);
    };
    const measure = () => {
      const r = root.getBoundingClientRect();
      const run = root.offsetHeight - innerHeight;
      target = Math.min(total, Math.max(0, (-r.top / Math.max(1, run)) * total));
      if (!raf) raf = requestAnimationFrame(frame);
    };
    measure();
    addEventListener("scroll", measure, { passive: true });
    addEventListener("resize", measure);
    return () => {
      removeEventListener("scroll", measure);
      removeEventListener("resize", measure);
      cancelAnimationFrame(raf);
    };
  }, []);

  return (
    <div ref={rootRef} className="journey relative" style={{ height: `${(total + 1) * 100}svh` }}>
      <div className="journey-stage sticky top-0 h-svh overflow-hidden bg-[#f4f1ec]">
        {scenes.map((s, i) => (
          <div
            key={s.id}
            ref={(el) => {
              layerRefs.current[i] = el;
            }}
            className="journey-layer absolute inset-0"
            style={{ opacity: i === 0 ? 1 : 0, visibility: i === 0 ? "visible" : "hidden" }}
          >
            {s.img ? (
              <picture>
                <source media="(max-width: 767px)" srcSet={`/redesign/${s.img}-m.webp`} />
                <img
                  src={`/redesign/${s.img}.webp`}
                  alt={s.alt}
                  className="journey-photo absolute inset-0 size-full object-cover"
                  fetchPriority={i === 0 ? "high" : "auto"}
                  loading={i < 2 ? "eager" : "lazy"}
                  decoding="async"
                />
              </picture>
            ) : null}
            {s.layout === "left" && <div aria-hidden className="journey-scrim journey-scrim--left absolute inset-0" />}
            {s.layout === "right" && <div aria-hidden className="journey-scrim journey-scrim--right absolute inset-0" />}
            {s.layout === "app" && <div aria-hidden className="journey-scrim journey-scrim--app absolute inset-0" />}
          </div>
        ))}

        {scenes.map((s, i) => (
          <div
            key={s.id}
            ref={(el) => {
              copyRefs.current[i] = el;
            }}
            className={`journey-copy journey-copy--${s.layout}`}
            style={{ opacity: i === 0 ? 1 : 0, visibility: i === 0 ? "visible" : "hidden" }}
          >
            <div className="journey-text">{s.copy}</div>
            {s.layout === "press" && (
              <div className="journey-board">
                <PressBoard
                  creased="/redesign/blazer-creased.webp"
                  pressed="/redesign/blazer-pressed.webp"
                  label="A creased navy suit jacket. Dragging across it presses it smooth."
                />
              </div>
            )}
            {s.layout === "app" && <div className="journey-phones">{phones}</div>}
          </div>
        ))}

        <span aria-hidden className="journey-rail">
          <span ref={railRef} className="journey-rail__fill" />
        </span>
      </div>
    </div>
  );
}
