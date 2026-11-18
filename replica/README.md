# replica/: competitor study and plan for IronDost

Date 2026-11-07. Everything here comes from **public sources** (store listings, marketing sites, public videos and review pages) and from reading IronDost's own repo. Nothing was installed on a device, nobody was signed in to, and no application code was changed.

## Start here

1. **[top-laundry-apps.md](top-laundry-apps.md)**: the most-downloaded laundry apps in India on both stores, and the five studied.
2. **[design/design-teardown.md](design/design-teardown.md)**: design style, layout, texture, colour and components of the five, compared with IronDost.
3. **[parity.md](parity.md)**: feature and layout parity, behaviour differences, top five gaps.
4. **[fixes.md](fixes.md)**: what customers complain about, fix plan, recommended angle.
5. **[architecture.md](architecture.md)** with **[schema.sql](schema.sql)**: the feature plan and the tested schema additions.
6. **[plans/](plans/decisions.md)**: your decisions of 7 Nov and the backend, build and review-research plans for the first slice (the Trust core). The task list is in `TASKS.md` at the repo root.

## By skill

| Skill | Files |
|---|---|
| replica-recon | [recon.md](recon.md), [features.csv](features.csv), [irondost-baseline.md](irondost-baseline.md), [screens/](screens/README.md) (68 listing screenshots, reference only), [competitors/](competitors/) |
| replica-design | [design/](design/) (7 token files with contrast results, the teardown) |
| replica-diff | [parity.md](parity.md), [diffs/](diffs/), [clone-screens/](clone-screens/) |
| replica-architect | [architecture.md](architecture.md), [schema.sql](schema.sql) |
| replica-entrepreneur | [reviews.csv](reviews.csv), [reviews.analysis.csv](reviews.analysis.csv), [themes-laundry.json](themes-laundry.json), [feedback.md](feedback.md), [fixes.md](fixes.md), [plans/entrepreneur-plan.md](plans/entrepreneur-plan.md) |
| replica-brand | [brand.md](brand.md), [brand.json](brand.json) |
| replica-launch | [launch/pricing.md](launch/pricing.md), [launch/landing.md](launch/landing.md), [launch/launch-plan.md](launch/launch-plan.md), [launch/listing.json](launch/listing.json) |
| replica-backend | [backend.md](backend.md), [plans/backend-plan.md](plans/backend-plan.md), [schema.trust-core.sql](schema.trust-core.sql) |
| replica-build | [build-log.md](build-log.md) (nothing built), [plans/build-plan.md](plans/build-plan.md) |
| replica-test | [test-plan.md](test-plan.md) |
| replica-deploy | [deploy.md](deploy.md) (nothing deployed) |

## Per-competitor detail

[DhobiLite](competitors/dhobilite/teardown.md) · [Tumbledry](competitors/tumbledry/teardown.md) · [Fabrico](competitors/fabrico/teardown.md) · [LaundryMate and LaundroKart](competitors/market-listings.md). Each teardown tags every claim observed, claimed or inferred and lists what could not be seen. Each folder also holds a feature list and verbatim reviews with links.

## What was run, and what was not

**Run:** store-data ranking; colour measurement from saved screenshots; WCAG contrast on 7 IronDost and competitor token files; layout diff on 5 screen pairs; review analysis (220 reviews); brand sweep; store-listing lint; one read-only request to IronDost's public catalogue; a dependency audit; the new schema applied to a throwaway Postgres 14 with IronDost's real migrations and **35 of 35 checks passed** (and the Trust-core migration alone, 17 of 17); independent spot checks of the research agents' review text (all testable samples matched the live pages).

**Not run:** the API unit and e2e tests (dependencies not installed here), Flutter tests, any device test, any production build, trademark and handle searches, and anything behind a sign-in at the competitors.

## Things the owner should look at now

1. The **live catalogue equals the repo's placeholder seed prices** ([launch/pricing.md](launch/pricing.md)).
2. **Next.js was upgraded to 16.4.5** in the admin and website (critical advisories cleared, build and lint pass). It is **not committed or deployed yet**; 16 high findings remain in other packages ([plans/backend-plan.md](plans/backend-plan.md), B7).
3. The Play listing says **"Available in Hyderabad"**, and the iOS draft subtitle says "in a day" ([brand.md](brand.md)).
4. **No rider app, no analytics, no crash reporting** ([deploy.md](deploy.md)).

## Limits that apply to everything

Store screenshots are curated and can be old. Competitor hex values come from pixel sampling inside phone frames (a few units of error); sizes, radii and fonts are eyeballed and low confidence. The review sample is weighted to 1 to 3 stars on purpose, so it shows what goes wrong, not how often. Priorities in the matrix are my judgement. IronDost's feature status was read from code and docs, not run.
