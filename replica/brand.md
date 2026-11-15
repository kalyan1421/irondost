# Brand check: IronDost against the market

replica-brand output, adapted. The skill exists to make a clone stop looking like its original. IronDost is not a clone and keeps its name, logo and palette, so the useful parts here are the **collision checks, the distinctness numbers and the sweep**, run and recorded below. Date 2026-11-07.

## Name: IronDost stays. Checks run today

| Check | Result (2026-11-07) | Note |
|---|---|---|
| Google Play, search "IronDost" (India) | One match: **`com.irondost.customer`, which is your own live listing** ("IronDost: Laundry & Ironing", 10+ downloads, updated 3 Nov 2026). No other app uses the name. | Matches your Android `applicationId`. |
| Google Play, "Iron Dost laundry" | No package with the name; results are other laundry apps. | |
| App Store, India and US, three spellings | No app named IronDost, and no publisher with that name. | Consistent with no iOS release yet. |
| Similar names in the category | Nearest: **Iztri** (iron, in Hindi), STEAMEE, Ironing Princess (a game). None share the sound or the "Dost" half. | Judgement, not a legal test. |
| Domain irondost.com | The `.com` registry returned "No match", which suggests it is **not registered**. | A whois line, not a purchase check. |
| Domains irondost.in and irondost.app | **Inconclusive.** The lookups returned only registry boilerplate. | The repo does not name the website's domain; check it at a registrar. |
| Trademark (IP India, WIPO Global Brand Database, EUIPO TMview) | **To run.** Not done: these databases need an interactive search. | Screening only; a trademark lawyer should do the real search, especially before paid ads or a national launch. |
| Handles (Instagram, X, YouTube) | **To run.** | The marketing plans in `docs/marketing/` assume handles exist. |

## Distinctness from the competitors (computed)

Colour distance (CIE ΔE76; under 15 reads as close, 15 to 30 related, over 30 clearly different), IronDost against each measured competitor colour:

| IronDost colour | Closest competitor colours | Reading |
|---|---|---|
| Royal blue `#1F4FD1` (primary) | LaundryMate blue 43.1, DhobiLite blue button 43.6, Tumbledry navy 54.9 | **Clearly different.** Keep. |
| Offer yellow `#FFC93C` | Tumbledry amber `#FCC40C` **9.7**, LaundryMate yellow `#FECC04` **12.3** | **Close.** Fine as a small offer marker, which is its documented use. Do not grow it into a CTA or banner colour, because Tumbledry (a Hyderabad competitor) uses amber for its primary buttons. |
| Ink navy `#0E1E3D` | Tumbledry navy `#243C64` 14.4, LaundroKart plum `#2B1331` 14.5 | Related; used for text and logo only. |
| Sky `#3FB8EA` (logo artwork) | DhobiLite blue 27.1, LaundryMate blue 30.9 | Related at most; stays in logo artwork. |

Details and the measured values: [design/design-teardown.md](design/design-teardown.md) and the `*.tokens.json` files.

## Sweep

`sweep.py` over `apps/` and `packages/` with [brand.json](brand.json): 16 competitor names, 7 domains, 13 measured brand colours. **Clean (exit 0) for both folders.** It does not scan `docs/` (which legitimately discusses competitors) or `replica/`.

## Palette and logo

No change recommended. IronDost's tokens pass AA in light and dark (13 of 13 pairs each; [design/irondost.light.tokens.json](design/irondost.light.tokens.json)). The existing logo is the outlined wordmark with the washer and iron signature; it shares no shape or colour pair with any of the five apps' marks as far as their public listing images show (an eyeball comparison, not a formal one).

## Voice and the strings that need attention

Voice (from `.agents/product-marketing.md`): helpful, local, direct, reassuring; plain short sentences; no superlatives. Competitors' superlatives are the opposite and inconsistent across their own channels (Tumbledry quotes 1400+, 1500+ and 1600+ stores on different surfaces).

| Where | Current text | Concern | Suggested direction |
|---|---|---|---|
| App Store subtitle (iOS draft, `docs/customer-app-release.md`) | "Pickup and delivery in a day" | A timing promise. The API's default minimum turnaround is 20 hours and the product-marketing doc lists "same-day" as unproven. Not live yet (no iOS listing). | "Doorstep ironing and laundry" |
| Play description, live | "Available in Hyderabad." | Service area is a radius or PIN list around LB Nagar (`business_settings`); the doc itself says to re-check this at submission. | "Available in parts of Hyderabad. Check your address in the app." Keep it true to the PIN list. |
| Play "What's new", live | Describes sign-in and error handling | Accurate. | None. |
| Marketing | "live order tracking" (draft What's new for iOS) | Tracking is status-based with realtime updates, not a live map. | "Track your order step by step." |

These are suggestions; wording is the owner's call. Do not name any competitor in IronDost's name, ads, listing or keywords (the `avoid` list guards the listing check).
