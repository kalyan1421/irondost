# Backend checklist

replica-backend output, adapted: IronDost's backend already exists, so this records what is verified, what is not, and what the new features add. Date 2026-11-07. Nothing was changed in `apps/api`.

## Rules carried over

- Official, public APIs only, with the owner's own keys. No competitor endpoint was called; the only requests to a competitor were ordinary page loads of public pages.
- The owner creates accounts and keys (Razorpay, Firebase, Supabase, and Meta for WhatsApp). `.env.example` already lists variable names.
- Test mode first for anything that moves money.

## Security checklist (status as verified today)

| Item | Status | Evidence or gap |
|---|---|---|
| Secrets only in env vars, `.env*` ignored | Verified (ignore rules) | `.gitignore` ignores `.env` and `.env.*`, keeps `.env.example`. Not checked: that nothing sensitive is in the Flutter bundle. |
| Input validated on the server | Verified | Global `ValidationPipe` with `whitelist`, `forbidNonWhitelisted`, `transform` (`app.setup.ts`). |
| Secure headers | Verified | `helmet()` enabled. |
| Authorisation on every read and write | Partly | `@Roles(...)` guards and `@Public()` markers exist. Not audited route by route; I did not read the e2e suite for second-customer tests. |
| Rate limits on sign-in and anything that sends SMS or email | Partly | `ThrottlerModule` is wired in `app.module.ts`. Which routes and limits apply was not checked. |
| Webhooks verify signatures | Verified | Razorpay route reads `x-razorpay-signature` from the raw body and returns 401 on mismatch. |
| Idempotency | Partly | Order idempotency key and hash fields exist and the replay header is exposed. I found no stored-event table for webhook de-duplication; check that `payment.captured` handling is safe to repeat. |
| Uploads: type and size limits, privacy | Partly | README: checks the file is an image, strips camera data including GPS, resizes to WebP. Size limit not checked. |
| No personal data in URLs or logs | Not checked | |
| Dependencies audited | **Run: 38 findings, needs action** | See below. |
| Privacy policy lists every processor | Not verified | `packages/legal` is marked "needs business review" in the README. |
| Backups on | Not verified | Database is on Supabase; confirm the plan's backups in the dashboard. |
| Dev sign-in bypass off in production | Not verified | README says the API refuses it when `NODE_ENV=production`. |

### Dependency audit (`pnpm audit --prod`, 2026-11-07)

38 findings: 4 low, 15 moderate, **17 high, 2 critical**. Counts include every dependency path, so some are duplicates and several are build tools; nothing below has been triaged for reachability beyond the notes.

- **Critical (2), Next.js in `apps/admin`** (the admin console is publicly reachable). Both `apps/admin` and `apps/web` pin `next@16.3.8`; the advisories cover 16.0.0 to 16.4.0 and are patched in **16.4.1**: unauthenticated remote code execution in the image optimiser when SVG files are used ([GHSA-2464-fhr4-w9xw](https://github.com/advisories/GHSA-2464-fhr4-w9xw)), and in `use cache` functions returning typed arrays ([GHSA-673q-mjm6-r5xr](https://github.com/advisories/GHSA-673q-mjm6-r5xr)). I found no `use cache` in the admin source, so the second likely does not apply; the admin does use `next/image` in three components, so the first needs a configuration check. A denial-of-service advisory for Server Actions ([GHSA-p3m5-59mp-jv5r](https://github.com/advisories/GHSA-p3m5-59mp-jv5r)) has the same range. **Status: upgraded to 16.4.5 on 7 Nov 2026.** Typecheck, lint and build pass for both apps and the critical advisories are cleared; after the upgrade the audit shows 35 findings (4 low, 15 moderate, 16 high, 0 critical). Not yet committed, and the admin was not clicked through in a browser. See [plans/decisions.md](plans/decisions.md).
- **High, API runtime (`apps/api`):** `body-parser` (denial of service, fixed in 2.4.0), `multer` (denial of service, 2.5.0; this is the upload path), `follow-redirects` (1.16.2), `deepmerge-ts` (8.0.0), `mysql2` (3.22.0; I did not trace why a MySQL driver is in the API's dependency tree).
- **High, admin:** `undici` (four advisories, 7.30.1), `zod` (4.6.6), `@grpc/grpc-js`, `@modelcontextprotocol/sdk`, `re2js`, `systeminformation`. The audit path for the MCP SDK finding runs through the `shadcn` CLI, which is listed as a dependency of the admin; a code-generation tool is not normally needed at runtime, so moving it to dev dependencies is worth checking.
- **Not run:** the API unit tests. `apps/api` has no `node_modules` in this checkout, so `vitest` is missing; installing dependencies was out of scope for this pass.

## What the new features need

| Feature | Backend work | External service | Notes |
|---|---|---|---|
| Express, slots, reschedule | Settings, quote, slot templates, capacity lock | none | Additive API; old apps default to STANDARD |
| Problem reports, adjustments, photos | New tables and routes, two jobs, staff alerts | Supabase Storage (existing) | Second-customer tests on every route |
| Wallet and referrals | Ledger, top-up through Razorpay order and webhook | Razorpay (existing keys) | Ledger keys come from provider payment ids; accountant first |
| WhatsApp | Phase 1: link only. Phase 2: outbound templates and an inbound webhook | **Meta WhatsApp Business Cloud API** | Needs a verified business, approved message templates, recorded opt-in. Scopes are the messaging and template-management permissions only. Rate limits and per-message pricing change; read Meta's current documentation before committing. Allow weeks for verification and template approval. |
| Telugu | Strings and `name_i18n` for catalogue | none | Font licence and rendering to confirm |

Schema: [schema.sql](schema.sql) (tested on a throwaway database; not applied anywhere).

## Output status

Auth, database and payments exist and are not modified by this pass. `backend.md` ticks only what was verified; the rest is listed as not checked. Feature matrix rows are unchanged because nothing was built. Next: `/replica-test` (the plan is [test-plan.md](test-plan.md)).
