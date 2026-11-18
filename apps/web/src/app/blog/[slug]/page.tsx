import type { Metadata } from "next";
import Link from "next/link";
import { notFound } from "next/navigation";
import { StoreButtons } from "@/components/store-buttons";
import { formatDate, getPost, posts } from "@/lib/posts";
import { site } from "@/lib/site";

// Static export: every post is built at build time and unknown slugs are 404s.
export const dynamicParams = false;

export function generateStaticParams() {
  return posts.map((p) => ({ slug: p.slug }));
}

export async function generateMetadata(props: PageProps<"/blog/[slug]">): Promise<Metadata> {
  const { slug } = await props.params;
  const post = getPost(slug);
  if (!post) return {};
  return {
    title: post.title,
    description: post.description,
    alternates: { canonical: `/blog/${post.slug}` },
    openGraph: { type: "article", title: post.title, description: post.description, publishedTime: post.published, modifiedTime: post.updated },
  };
}

export default async function BlogPost(props: PageProps<"/blog/[slug]">) {
  const { slug } = await props.params;
  const post = getPost(slug);
  if (!post) notFound();

  const jsonLd: object[] = [
    {
      "@context": "https://schema.org",
      "@type": "Article",
      headline: post.title,
      description: post.description,
      datePublished: post.published,
      dateModified: post.updated,
      mainEntityOfPage: `${site.url}/blog/${post.slug}`,
      image: `${site.url}/redesign/${post.image.src}.webp`,
      author: { "@type": "Organization", name: site.name, url: site.url },
      publisher: { "@type": "Organization", name: site.name, url: site.url },
    },
  ];
  if (post.faq?.length) {
    jsonLd.push({
      "@context": "https://schema.org",
      "@type": "FAQPage",
      mainEntity: post.faq.map((f) => ({ "@type": "Question", name: f.q, acceptedAnswer: { "@type": "Answer", text: f.a } })),
    });
  }
  jsonLd.push({
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: [
      { "@type": "ListItem", position: 1, name: "Home", item: `${site.url}/` },
      { "@type": "ListItem", position: 2, name: "Guides", item: `${site.url}/blog` },
      { "@type": "ListItem", position: 3, name: post.title, item: `${site.url}/blog/${post.slug}` },
    ],
  });
  const others = post.related.map(getPost).filter((p): p is NonNullable<typeof p> => Boolean(p));

  return (
    <div className="mx-auto max-w-3xl px-4 py-14 sm:px-6 sm:py-20">
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }} />
      <p className="text-sm font-semibold">
        <Link href="/blog" className="text-royal underline-offset-4 hover:underline">
          Guides
        </Link>
      </p>
      <h1 className="mt-3 font-display text-4xl font-bold tracking-tight sm:text-5xl">{post.title}</h1>
      <p className="mt-4 text-muted">
        By the {site.name} team, LB Nagar, Hyderabad · Updated <time dateTime={post.updated}>{formatDate(post.updated)}</time>
      </p>

      <article className="mt-8 space-y-10">
        <p className="text-xl leading-relaxed">{post.answer}</p>

        <figure className="overflow-hidden rounded-3xl bg-mist">
          {/* eslint-disable-next-line @next/next/no-img-element -- static export, images are pre-sized WebP */}
          <img src={`/redesign/${post.image.src}.webp`} alt={post.image.alt} className="aspect-[16/9] w-full object-cover" />
        </figure>

        {post.sections.map((s) => (
          <section key={s.heading}>
            <h2 className="font-display text-2xl font-semibold">{s.heading}</h2>
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
            {s.steps && (
              <ol className="mt-4 space-y-4">
                {s.steps.map((st, i) => (
                  <li key={st.title} className="flex gap-4">
                    <span className="flex size-9 shrink-0 items-center justify-center rounded-full bg-royal font-semibold text-white">{i + 1}</span>
                    <span>
                      <span className="block text-lg font-semibold">{st.title}</span>
                      <span className="block text-lg leading-relaxed text-muted">{st.body}</span>
                    </span>
                  </li>
                ))}
              </ol>
            )}
          </section>
        ))}

        {post.faq?.length ? (
          <section>
            <h2 className="font-display text-2xl font-semibold">Questions</h2>
            <dl className="mt-3 space-y-5">
              {post.faq.map((f) => (
                <div key={f.q}>
                  <dt className="text-lg font-semibold">{f.q}</dt>
                  <dd className="mt-1 text-lg leading-relaxed">{f.a}</dd>
                </div>
              ))}
            </dl>
          </section>
        ) : null}
      </article>

      <aside className="mt-14 rounded-3xl bg-ink p-7 text-white">
        <h2 className="font-display text-2xl font-semibold">Book a pickup</h2>
        <p className="mt-2 text-lg text-white/85">
          Get the app, or call or WhatsApp{" "}
          <a href={`tel:${site.phone.tel}`} className="font-semibold text-white underline underline-offset-4">
            {site.phone.display}
          </a>
          .
        </p>
        <div className="mt-6">
          <StoreButtons onDark />
        </div>
      </aside>

      <nav aria-label="More guides" className="mt-12">
        <h2 className="font-display text-xl font-semibold">Read next</h2>
        <ul className="mt-3 space-y-2 text-lg">
          {others.map((p) => (
            <li key={p.slug}>
              <Link href={`/blog/${p.slug}`} className="text-royal underline-offset-4 hover:underline">
                {p.title}
              </Link>
            </li>
          ))}
        </ul>
      </nav>
    </div>
  );
}
