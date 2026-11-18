# Deploy checklist

replica-deploy output, filled with real results. Date 2026-11-07. Branch `ops/launch-gaps`, working tree has uncommitted changes. **Go from the owner: not requested. Nothing was deployed, published or changed in any running service by this pass.** The only request to a live IronDost service was one read-only `GET /v1/catalog`.

## Preflight

| Check | Result |
|---|---|
| e2e and unit tests green | **Not run.** `pnpm --filter @laundry/api test` failed to start: `vitest` is missing because `apps/api/node_modules` is not installed in this checkout. The e2e suite needs a database. The Flutter suite was not run (398 passed per the repo's own 5 Oct report). |
| No open S1 or S2 bugs | **Not assessed.** No testing was done. |
| Market parity, for information | Feature score 55.7; must-haves 10 of 16 ([parity.md](parity.md)). Not a ship gate for IronDost. |
| Brand sweep clean (`sweep.py`) | **Pass**, exit 0 for `apps/` and `packages/` against 16 competitor names, 7 domains, 13 colours. |
| Store listing check (`listing.py`) | **Pass**: 0 errors, 2 warnings (empty promotional text; keywords repeat the title). |
| Production build passes | **Not run.** |
| Privacy policy and terms live, processors listed | **Not verified.** The pages exist in `apps/web` (privacy, terms, cancellation, delete-account); the live domain is not named in the repo. README: legal text "needs business review". |
| Account deletion works | **Not tested.** Implemented in the app (S46, S47) and the website has a delete-account page. |
| Favicon, titles, social image are IronDost's | **Pass by inspection**: `apps/web` carries its own `icon.svg`, `apple-icon.png`, `opengraph-image.png`. |

## Findings that need a decision before more traffic

1. **Next.js critical and high advisories** in `apps/admin` and `apps/web` (were pinned at 16.3.8; patched in 16.4.1). **Upgraded to 16.4.5 on 7 Nov 2026 and verified by typecheck, lint and build; not yet committed or deployed.** Details in [backend.md](backend.md). The admin console is on a public Render URL, so deploy the upgrade soon.
2. **The live catalogue equals the placeholder seed** ([launch/pricing.md](launch/pricing.md)).
3. **Listing wording**: "Available in Hyderabad" and the unreleased iOS subtitle ([brand.md](brand.md)).
4. **No analytics or crash reporting**, so launch health cannot be measured from the client.
5. **No rider app**; every leg is moved by staff in the admin.

## Production (state as far as the repo shows)

| Item | Status |
|---|---|
| Separate production database, backups on | Production API and database run on Render and Supabase per README. Whether it is a separate project from development and whether backups are enabled: **not verified**. |
| Env vars match `.env.example` | **Not verified.** |
| Razorpay in live mode and webhook | **Not verified.** The README says the webhook points at `POST /v1/webhooks/razorpay`. |
| Firebase phone sign-in and push | Not verified. The repo lists SMS autofill and push on hardware as open checks. |
| Domain, DNS, HTTPS | The repo does not name the website's domain. **Owner to confirm.** I did not buy or configure anything. |
| Email DNS (SPF, DKIM, DMARC) | Not applicable until the product sends email from a domain. |

## Mobile

- **Android:** live on Play (10+ downloads, updated 3 Nov 2026). Release process: [docs/play-store-release-flow.md](../docs/play-store-release-flow.md).
- **iOS:** no listing found. TestFlight and review need the owner's Apple developer account.

## Watch (first week)

Error tracking: none yet. Uptime: the API has a heartbeat module (`keep-alive`, `service_heartbeats`); an external uptime check on the API health endpoint and the booking path is still worth adding. Analytics: none. Alerts: staff alerts exist in the admin for new orders and unassigned pickups. Do the core flow on a real phone after any release and ask the owner to repeat it.

## Result

Not ready to call "deployed and verified". The plan's own steps have not been built, so there is nothing new to deploy. The items above are for the owner to schedule. Next: review and commit the Next.js upgrade, then deploy the admin and website when you are ready.
