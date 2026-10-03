import Link from "next/link";
import { legal, legalPages, type LegalSlug } from "@/lib/legal";
import { site } from "@/lib/site";

const slugify = (heading: string) => heading.toLowerCase().replace(/^\d+\.\s*/, "").replace(/[^a-z0-9]+/g, "-").replace(/(^-|-$)/g, "");

/** One of the policies as readable text, from the same file the app reads. */
export function LegalDocument({ slug }: { slug: LegalSlug }) {
  const doc = legal.documents[slug];
  const others = legalPages.filter((p) => p.slug !== slug);
  return (
    <div className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-20">
      <h1 className="font-display text-4xl font-bold tracking-tight sm:text-5xl">{doc.title}</h1>
      <p className="mt-4 text-lg text-muted">{legal.byline}</p>

      <nav aria-label="On this page" className="mt-8 rounded-2xl bg-mist p-5">
        <h2 className="font-display text-base font-semibold">On this page</h2>
        <ol className="mt-3 space-y-1.5">
          {doc.sections.map((s) => (
            <li key={s.heading}>
              <a href={`#${slugify(s.heading)}`} className="text-royal underline-offset-4 hover:underline">
                {s.heading.replace(/^\d+\.\s*/, "")}
              </a>
            </li>
          ))}
        </ol>
      </nav>

      <article className="mt-10 space-y-10">
        {doc.sections.map((s) => (
          <section key={s.heading} aria-labelledby={slugify(s.heading)}>
            <h2 id={slugify(s.heading)} className="font-display text-2xl font-semibold">
              {s.heading}
            </h2>
            {s.paragraphs?.map((p) => (
              <p key={p} className="mt-3 text-lg leading-relaxed">
                {p}
              </p>
            ))}
            {s.bullets && (
              <ul className="mt-3 list-disc space-y-2 pl-6 text-lg leading-relaxed marker:text-royal">
                {s.bullets.map((b) => (
                  <li key={b}>{b}</li>
                ))}
              </ul>
            )}
          </section>
        ))}
      </article>

      <aside className="mt-14 rounded-2xl border border-ring p-6">
        <h2 className="font-display text-xl font-semibold">Questions about this?</h2>
        <p className="mt-2 text-lg">
          Call us on{" "}
          <a href={`tel:${site.phone.tel}`} className="font-semibold text-royal">
            {site.phone.display}
          </a>{" "}
          or email{" "}
          <a href={`mailto:${site.email}`} className="break-all font-semibold text-royal">
            {site.email}
          </a>
          .
        </p>
        <p className="mt-4 text-muted">
          Also read:{" "}
          {others.map((p, i) => (
            <span key={p.slug}>
              {i > 0 && " · "}
              <Link href={`/${p.slug}`} className="text-royal underline-offset-4 hover:underline">
                {p.label}
              </Link>
            </span>
          ))}
        </p>
      </aside>
    </div>
  );
}
