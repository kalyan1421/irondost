# Status and roadmap

Everything about building and auditing the IronDost platform in one place. Updated 23 Nov 2026 from the repo (last commit 19 Nov 2026, customer app version 2.0.0+103).

## What exists

| Part | Stack | Status |
|---|---|---|
| `apps/api` | NestJS 12, Prisma 7, PostgreSQL, pg-boss, Socket.IO | Live on Render. Trust core tables are in the schema (OrderAdjustment, OrderIssue, IssuePhoto, OrderCarePhoto, AreaInterest) |
| `apps/admin` | Next.js 16 | Live through Vercel |
| `apps/web` | Next.js 16, static | Live: redesigned homepage, prices page, five guides, robots, llms.txt, Search Console tags |
| `apps/customer` | Flutter | Release 2.0.0 shipped (trust core, phase 1, LB Nagar rules). New UI changes are uncommitted in the working tree |
| `apps/partner` | Flutter | Not started |
| CI/CD | GitHub Actions + Vercel + Render | Website, admin and API deploy from `main` |

**Firebase** is kept only for phone OTP and push. Payments: Razorpay and cash on delivery. Service area: 7 PIN codes around LB Nagar with pickup capacity, a waiting list and a travel charge under ₹200.

## Recently shipped

- 19 Nov: Google Search Console verification on the website.
- Launch release 2.0.0: trust core, phase 1, LB Nagar rules, website redesign, CI/CD.
- Prices page from the live catalogue; LB Nagar service-area rules, pickup capacity, waiting list, care notes.
- Reschedule a pickup, payments and refunds ledger, undelivered alerts.

## Next up

| # | Work | Size | Note |
|---|---|---|---|
| 1 | Review and commit the uncommitted customer app, admin, API and web changes now in the working tree | S | About 50 files changed since 2.0.0 |
| 2 | Dependency hardening: 16 high findings (multer, body-parser, follow-redirects, deepmerge-ts, admin packages) | S–M | Independent |
| 3 | Confirm what is left of the trust core: price-change approval sheet (S51/A03), problem reports (S48–S50, A01–A02), admin settings, contract refresh, end-to-end tests | M | `TASKS.md` was last updated 7 Nov and is now behind the code; check each item |
| 4 | Pilot the trust core with staff and a few customers | — | After 3 |
| 5 | Add analytics and crash reporting | S | The app has neither |
| 6 | Partner app (Flutter): scaffold, screens P01–P10, field test, Android first | L | Needs owner answers below |
| 7 | WhatsApp click-to-chat link now, official API later | S | No database change |

## Waiting on the owner

1. Confirm live catalogue prices (production may still equal the seed).
2. Response clock and approval window (placeholders 4 h and 12 h). Customers see these as promises.
3. Minimum order and delivery fee (defaults zero; competitors use ₹299–350).
4. Store-listing wording: "Available in Hyderabad" and the iOS subtitle "in a day".
5. Trademark and handle searches for IronDost.
6. Partner app: Android first, folder name, distribution, location-consent text.
7. One support phone number. The app screens show +91 90632 90012; marketing uses 79934 34932.

## Audits on file

| Audit | Date | Main result |
|---|---|---|
| Cloud Ironing platform audit | 2 Oct 2026 | 15 security findings on the old Firebase apps (world-writable orders, self-promotion to admin, public Aadhaar and driver codes). Led to the rebuild on NestJS + PostgreSQL that is live now |
| UI/UX audit, design research, design system | Oct – Nov 2026 | Customer app redesign; implementation and lessons recorded |
| Customer app critique | Nov 2026 | Screen-by-screen fixes for the Flutter app |
| India laundry app market research | Oct 2026 | Competitor UX patterns |
| Competitor replica study | 7 Nov 2026 | Parity plan, tested schema, backend and build plans |

## Later

Express option and configurable pickup windows (needs rider capacity), wallet and referral rewards (needs an accountant's rules), Telugu and Hindi, public neighbourhood pages.
