# Review research plan: balance the sample

replica-entrepreneur, as a plan. Date 2026-11-07. Choice recorded in [decisions.md](decisions.md): collect a sample that is not skewed to low stars. Nothing has been collected yet.

## Why

The 220 reviews analysed in [feedback.md](../feedback.md) were collected 1 to 3 stars first. The three apps' real averages are higher (DhobiLite 4.9 on Play, Tumbledry 4.3, Fabrico 3.5), so those theme shares overstate how often each problem happens and say nothing about what customers like. That second half matters: IronDost must not lose what people praise while fixing what they hate.

Neither store publishes star counts, only an average and a total, so the true distribution cannot be read directly. The clean fix is a **recency sample with no rating filter**: the newest reviews, whatever their stars, show the real recent mix.

## Sample design

| Sample | What | Purpose |
|---|---|---|
| **A: unbiased recent** | For each of DhobiLite, Tumbledry and Fabrico: the newest 60 Google Play reviews with the default newest sort and no star filter, every review visible on the App Store India page (about 10), and every Google Maps review of the Hyderabad stores near LB Nagar (Fabrico Dilsukh Nagar, Tumbledry Vanasthalipuram and Kharmanghat cards, DhobiLite Bandlaguda) | The real mix of praise and complaint; theme shares that can be quoted |
| **B: existing** | The 220 reviews already analysed (1 to 3 stars weighted) | What kinds of problems exist, including rare ones |

Target: at least 150 reviews in sample A across at least three sources. If fewer exist, say so and report the real number.

## Method (the pack's rules)

- **Reading, not scraping.** Read the pages in Chrome the way a person does, at human speed, signed out, with no forms. No scraping tools against stores or review sites. Apple's official reviews feed is allowed within its terms (it returned nothing for India earlier, so the on-page reviews are the source).
- **Every review verbatim with its page link**, copied exactly (typos included), with date, star rating and a `city_mentioned` column only when the text names one.
- **Record the sort order and the date read** for every source, so the sample can be reproduced.
- **Never fabricate**; if a source cannot be reached, say so.
- **Hinglish and Telugu:** keep the original text; add a `translation_note` only as a separate column, never replacing the review.
- **Exclusions, as before:** brand-curated reviews on the companies' own sites, duplicates, and one- and two-star reviews whose text is plainly positive (listed in an audit file, not silently dropped). Add the mirror case: **four- and five-star reviews whose text is plainly negative** (Tumbledry had one) go to the audit list too.

## Work

| # | Step | Who | Output |
|---|---|---|---|
| E1 | Three research agents, one per app, collect sample A with the rules above | agents | `replica/competitors/<app>/reviews-recent.csv` |
| E2 | Independent verification: I re-read a sample of each agent's reviews against the live pages (the method used before: distinctive phrases, word for word) | me | A short log; any app with a failed check is redone |
| E3 | Merge and clean; apply the exclusions | me | `replica/reviews-recent.csv`, `reviews-recent.excluded.csv` |
| E4 | Run `reviews.py` with the laundry themes and a new **praise** theme file (on time, quality, price, staff, app ease, support helped) | me | `replica/feedback-balanced.md` |
| E5 | Compare A with B: which complaint themes stay large, which shrink, and which praise themes appear | me | A section in [fixes.md](../fixes.md) |
| E6 | Update the three lists, the fix plan and the angle if the evidence moved | me | [fixes.md](../fixes.md) revised |

Keyword matching has limits (about 60 to 85% precision in the earlier spot check). Before reporting any share, sample six matches per theme by eye, as before, and report the precision found.

## Questions the new sample can answer

1. Does "support that does not answer" stay the top theme when five-star reviews are included, or is it a feature of the low-star filter?
2. What do customers praise at each app (on-time pickup, price, quality, one helpful person)? Those are the things IronDost must keep.
3. Do the Hyderabad stores differ from the national averages? (Google Maps rows for the three nearest stores.)
4. Is the "billed price differed from the quote" theme visible in the unbiased sample, or only among the unhappy?

## What would change the plans

| If the unbiased sample shows | Then |
|---|---|
| Support complaints are common even among all recent reviews | Keep the report-and-response clock as the first slice (as chosen) |
| Billing disputes are rare in the unbiased mix | Keep price approval, but move the angle toward reliability evidence if that theme is bigger |
| Praise concentrates on punctuality | Prioritise the honest pickup windows work and the rider app before express |
| Praise concentrates on a named person or a store | Note the operational lesson (relationships), not a feature |

## Cost and timing

Three agents running in parallel took about 16 to 20 minutes each last time, with verification on top. I will not start this until you say so, since it uses a lot of browser time and is separate from the build.

## Output files (when run)

`replica/reviews-recent.csv`, `reviews-recent.excluded.csv`, `themes-praise.json`, `feedback-balanced.md`, an updated [fixes.md](../fixes.md), and a short verification log.
