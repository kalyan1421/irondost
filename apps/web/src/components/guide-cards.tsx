import Link from "next/link";
import { formatDate, posts } from "@/lib/posts";

/** Every guide as a card with its photo. Used on the homepage and on /blog. */
export function GuideCards({ headingLevel = "h3" }: { headingLevel?: "h2" | "h3" }) {
  const Heading = headingLevel;
  return (
    <ul className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
      {posts.map((p) => (
        <li key={p.slug} data-reveal>
          <Link
            href={`/blog/${p.slug}`}
            className="group flex h-full flex-col overflow-hidden rounded-3xl bg-white ring-1 ring-ring transition-shadow hover:shadow-lg hover:ring-royal"
          >
            <span className="block aspect-[16/10] overflow-hidden bg-mist">
              {/* eslint-disable-next-line @next/next/no-img-element -- static export, images are pre-sized WebP */}
              <img
                src={`/redesign/${p.image.src}.webp`}
                alt=""
                loading="lazy"
                className="size-full object-cover transition-transform duration-500 group-hover:scale-105"
              />
            </span>
            <span className="flex flex-1 flex-col p-6">
              <Heading className="font-display text-xl font-semibold leading-snug">{p.title}</Heading>
              <span className="mt-2 line-clamp-3 text-base leading-relaxed text-muted">{p.description}</span>
              <span className="mt-auto pt-4 text-sm text-muted">
                Updated <time dateTime={p.updated}>{formatDate(p.updated)}</time>
              </span>
            </span>
          </Link>
        </li>
      ))}
    </ul>
  );
}
