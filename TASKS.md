# Tasks

## Active

- [ ] **B0: write tests that pin down how `updateItems` and pricing behave today** - first, before any change; `apps/api`, size S
  - No test covers `updateItems` now; it also reprices every line at today's catalogue price
  - Details: replica/plans/backend-plan.md
- [ ] **B1: freeze quoted prices and add the Trust-core tables** - `apps/api`, size M, after B0
  - Existing lines keep their quoted unit price; only added items use the current catalogue
  - Prisma models and a hand-written migration from replica/schema.trust-core.sql (tested: 17 of 17 checks on a throwaway database)
  - Check how Prisma 7 treats partial indexes before committing
- [ ] **B2: price-change approval** - `apps/api`, size M, after B1
  - Increases create a pending request; decreases apply at once; approve, decline, expiry job; payment and delivery guards
- [ ] **S51 and A03: approve-new-total sheet in the customer app, and the admin items card** - size M, after B2 and the contract refresh
  - Read apps/admin/node_modules/next/dist/docs before writing admin code (apps/admin/AGENTS.md)
- [ ] **B3: customer image upload route** - `apps/api`, size S
  - Reuse the existing pipeline; per-user limits; issue photos only from the user's own prefix
- [ ] **B4: problem-report API with the response-clock job** - `apps/api`, size M, after B1 and B3
- [ ] **S48 to S50 and A01 to A02: report screens (customer) and the staff queue (admin)** - size M, after B4
- [ ] **B5 and B6: admin settings, refresh OpenAPI contract and both generated clients, end-to-end tests** - size M
  - A second-customer test for every new route
- [ ] **B7: dependency hardening, 16 high findings** - size S to M, independent
  - Order: multer, body-parser, follow-redirects, deepmerge-ts, then the admin packages, then find out why mysql2 is in the API tree
- [ ] **Review and commit the Next.js 16.4.5 upgrade** - 3 files changed, not committed
  - apps/admin/package.json, apps/web/package.json, pnpm-lock.yaml; typecheck, lint and build pass for both
  - Not yet clicked through in a browser
- [ ] **Pilot the Trust core with staff and a few customers** - after B6
- [ ] **Partner app (Flutter, `apps/partner`): scaffold, screens P01 to P10, field test** - size L, start after B2
  - Android first; confirm distribution and the location-consent text before starting
  - Details: replica/plans/build-plan.md part C

## Waiting On

- [ ] **Confirm the live catalogue prices** - for owner; production catalogue equals the repo's placeholder seed
  - Correcting them later would reprice any order whose items are edited, until B1 ships
- [ ] **Choose the response clock and the approval window** - for owner; placeholders are 4 hours and 12 hours
  - Customers will see these as promises
- [ ] **Go-ahead to run the balanced review sample (E1 to E6)** - for owner; plan in replica/plans/entrepreneur-plan.md
- [ ] **Decide minimum order and delivery fee** - for owner; defaults are zero, competitors use 299 to 350
- [ ] **Fix the store-listing wording** - for owner; "Available in Hyderabad" and the unreleased iOS subtitle "in a day" (replica/brand.md)
- [ ] **Run trademark and handle searches for IronDost** - for owner or a trademark lawyer
- [ ] **Partner app: Android first? folder name? distribution?** - for owner; defaults in replica/plans/decisions.md

## Someday

- [ ] **Express option and configurable pickup windows** - needs rider capacity first; schema is drafted in replica/schema.sql
- [ ] **Wallet and referral rewards** - parked until an accountant decides the rules; tested ledger schema is on file
- [ ] **WhatsApp: click-to-chat link now, official API later** - quick win, no database change
- [ ] **Public price list and neighbourhood pages on the website** - small, high trust value
- [ ] **Telugu and Hindi** - fonts and catalogue translations first
- [ ] **Add analytics and crash reporting** - the app has neither today

## Done

- [x] ~~Competitor study: top competitors, design teardown, parity, fix plan, architecture, tested schema~~ (2026-11-07) - replica/README.md
- [x] ~~Next.js upgraded 16.3.8 to 16.4.5 in admin and web; critical advisories 2 to 0~~ (2026-11-07) - replica/plans/decisions.md
- [x] ~~Scope decisions recorded: Trust core first, Flutter partner app, wallet parked, balance the review sample~~ (2026-11-07)
- [x] ~~Backend, build and review-research plans written~~ (2026-11-07) - replica/plans/
