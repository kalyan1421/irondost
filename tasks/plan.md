# Implementation plan: IronDost on irondost.in

Written 19 November 2026. Tasks with acceptance criteria are in [todo.md](todo.md).

## Overview

Move IronDost's public presence onto its own domains:
- The admin goes to `admin.irondost.in` on Vercel.
- A redesigned website goes to `irondost.in`, and `.com` and `.shop` redirect to it.
- The website has guides and AI-crawler files.
- A Google Business Profile, Instagram and YouTube point back to the site.

The redesign comes before the domain switch, so irondost.in launches with the new site. Until then, the current site with the guides and fixed store links can go out on a Vercel preview.

## Where things stand (19 Nov)

| Area | State |
| --- | --- |
| Admin | Live at https://irondost-admin.vercel.app. `admin.irondost.in` is attached to the Vercel project and waits for DNS |
| Domains | irondost.in and irondost.com are registered at Hostinger and parked. irondost.shop is **not registered** |
| Website code | Store links fixed, phone 79934 34932, 5 guides, robots.txt, llms.txt, llms-full.txt. Builds clean. Not deployed, not committed |
| Redesign | Two drafts being built (see `docs/marketing/website-redesign-drafts.md` when ready) |
| SEO and GBP | Audit, local SEO and the GBP pack in `docs/marketing/seo/` |
| Zernio | Blocked: needs a payment method before any more accounts can be connected |

## Architecture decisions

- **irondost.in is primary.** `.com`, `.shop` and every `www` 301 to it with the path kept. Reason: one site for search engines; `.in` reads local.
- **Website on Vercel as a static export** (`output: "export"` stays). Reason: same dashboard as the admin; multi-domain redirects; preview per change. Firebase Hosting stays up until the store listings point at irondost.in, then redirects.
- **API stays on Render** with `api.irondost.in` as a later step. Reason: the customer app has the Render URL built in; switching needs an app release.
- **DNS stays at Hostinger** (records, not nameservers). Reason: fewer moving parts; email can stay at Hostinger.
- **Booking on the website is phase 1 links only** (app, WhatsApp, call, PIN check). A web booking form is a separate project.
- **Generated images are drafts only.** Codex images are used for layout and the first preview. Real photos replace every "our work" image before launch.

## Phases

1. **Foundation** (tasks 1 to 3): admin domain working, website on a Vercel preview, domains attached.
2. **Redesign** (tasks 4 to 9): choose a draft, build it into `apps/web`, real photos, verify on phones.
3. **Launch** (tasks 10 to 12): switch irondost.in to the new site, Search Console, store listing URLs.
4. **Local and social** (tasks 13 to 18): Business Profile, prices page, schema, Zernio, posting.

## Risks and mitigations

| Risk | Impact | Mitigation |
| --- | --- | --- |
| Changing `CORS_ORIGINS` on Render redeploys the API from the latest commit, which includes new migrations (release checklist) | High | Do it as part of the planned API release, with the checklist; or confirm that the deployed commit is the current one first |
| Admin sign-in fails on the new domain | Med | Add both Vercel domains to Firebase authorized domains before switching; keep the vercel.app URL working |
| Prices shown are the placeholder seed | High | No prices on the site, guides or GBP until the owner confirms them |
| Generated "our work" photos mislead customers | High | Real photos required before launch (task 7) |
| irondost.shop not registered | Low | Buy it, or drop it from the plan |
| Zernio paid plan | Low | Owner adds a payment method, or posts from Meta Business Suite and YouTube Studio |

## Open questions

The full list is in todo.md under "Owner inputs". The decisions that block everything else:
1. Which draft, A or B (or a mix)?
2. Are the catalogue prices real?
3. Who can edit DNS at Hostinger, you or me with your login?
4. Is irondost.shop bought?
