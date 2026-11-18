# Guides audit, robots.txt and llms.txt

Mode: **AUDIT** (human-first SEO, AEO, GEO). Written 19 November 2026 for the five guides in `apps/web/src/lib/posts.ts`. I did not check live search results, so search demand and competition for each query are unverified.

## Verdict

The guides are useful and answer-first, and they claim only what the app and site already state. Their weak point is proof. They have no photos, no named person behind them and no real customer detail, so they read as correct but generic. Fixing that needs real photos and the owner's input, not more text.

## Fixed in code today

| Label | Finding | Change |
| --- | --- | --- |
| Fix → done | No visible author or accountability | Byline: "By the IronDost team, LB Nagar, Hyderabad · Updated <date>" |
| Fix → done | "More guides" showed the first three posts, whatever the topic | Each post now has a hand-picked `related` list in decision order ("Read next") |
| Fix → done | No breadcrumb data | BreadcrumbList JSON-LD (Home, Guides, post) |
| Fix → done | No AI-crawler policy and no llms.txt | See below |

## Still open

| Label | Finding | Next action |
| --- | --- | --- |
| Warning | No images. A process guide without a single real photo is hard to trust | After the 19–20 Nov filming: add 2 to 3 photos per guide (handover, counting, pressing, saree border). Alt text states what is shown, for example "Partner counting shirts with a customer at the door" |
| Warning | No prices. The PG guide in particular is weaker without one | Confirm the catalogue (still the placeholder seed), then add a dated price line and the `/prices` page |
| Warning | No first-hand detail (a building served, a real stain case) | Add one true example per guide once there are real orders, with permission |
| Fix | Guides are only linked from the header and from each other | Link the areas guide from the homepage service-area section, and the bill guide from the FAQ "Will the price change?" answer, in the redesign |
| Fix | Organization identity is thin for answer engines | Once the Google Business Profile exists, add Organization/LocalBusiness JSON-LD on the homepage with `sameAs` (GBP, Instagram, YouTube, Play, App Store) and `areaServed` |
| Pass | Title, description, H1 and answer paragraph each match one question | n/a |
| Pass | Opening paragraph answers the title in under 60 words, with no pronouns that depend on context | n/a |
| Pass | FAQ schema only where questions are visible on the page | n/a |
| Pass | No competitor names, "best", "cheapest", invented numbers or customers | n/a |

## robots.txt (live at /robots.txt after deploy)

Everything is allowed. The search and answer crawlers are named explicitly (Googlebot, Bingbot, Google-Extended, Applebot, Applebot-Extended, OAI-SearchBot, GPTBot, ChatGPT-User, ClaudeBot, Claude-SearchBot, Claude-User, PerplexityBot, Perplexity-User), so a future blanket rule cannot block them by accident. The sitemap line uses `NEXT_PUBLIC_SITE_URL`. It must be `https://irondost.in` on the production deploy.

**Decision for you:** this lets AI companies use the pages for training as well as for answers (GPTBot, Google-Extended, Applebot-Extended). That is the usual choice for a local business that wants to be named in AI answers. To allow answers but not training, change those three to `disallow`.

## llms.txt and llms-full.txt

- `/llms.txt`: a short Markdown summary for AI assistants covering what IronDost is, the area and PIN codes, pickup windows, payment, the billing rule, and how to book (both store links and the phone number). It then lists every guide and policy page.
- `/llms-full.txt`: the same facts plus the full text of every guide.

Both are generated at build time from `posts.ts` and `site.ts` (`src/lib/llms.ts`), so they never drift from the pages. llms.txt is a proposed convention, not a standard. No search engine has said it uses it for ranking. It is cheap and does no harm.
