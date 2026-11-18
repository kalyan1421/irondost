# Parity: IronDost against the five most-downloaded laundry apps

Date 2026-11-07. Matrix: [features.csv](features.csv), 56 rows. Tool: `parity.py` from replica-diff.

## Read this first

replica-diff was written to score a clone against the app it copies. IronDost is not a clone, so the numbers mean something different here:

- **Feature score = how much of what the market's top apps offer IronDost already does.** It is a gap list, not a ship gate. The tool's "not shippable yet" line is its fixed wording for a clone with missing must-haves; for IronDost it only means six market-standard features are not built.
- **"Original" means "at least one of the five apps shows it".** Five apps seen through public listings and marketing pages are a sample, not the market. `-` in the matrix means "not seen", never "does not exist".
- **"Clone" status for IronDost comes from reading the code and repo docs (see [irondost-baseline.md](irondost-baseline.md)). Nothing was run on a device.** Priorities (must, should, could) are my judgement: *must* = core booking, money, trust or support, in at least two apps or tied to a top complaint theme; *should* = in two or more apps; *could* = in one app or outside the ironing-first launch scope.
- The tool also prints a combined 47.9 that blends in layout similarity. **Ignore it.** Layout similarity rewards looking like another app, which is the opposite of the goal.

## Feature parity: 55.7 / 100

50 features counted. **Must-haves: 10 of 16 done.** Skipped (not scored): store locator, franchise programme. IronDost-only (not scored): rating prompt after delivery, AA contrast and text scaling, price-change notice with refund alert, honest overdue label.

| Area | Score | Features |
|---|---|---|
| auth, serviceability, checkout, payments, notifications, orders, design, account | 100 | 12 |
| pricing | 83 | 3 |
| tracking | 80 | 3 |
| offers | 62.5 | 4 |
| scheduling | 57 | 6 |
| catalogue | 42 | 6 |
| trust | 19 | 4 |
| support | 17 | 3 |
| web, express, wallet, localisation, b2b | 0 | 8 |

### Missing must-haves, in build order

1. **Express or faster-turnaround option with the extra charge shown.** All five apps have one (surcharges from +20% to +100%). IronDost has a fixed 20-hour minimum and no choice.
2. **Order-linked problem report with a visible status.** Unanswered support is the largest complaint theme (see [fixes.md](fixes.md)); no app shows this working.
3. **WhatsApp channel in the app or one tap away.** Three apps have it; IronDost's own marketing plans already rely on it as the fallback.
4. **Public price list on the website.** Fabrico and DhobiLite publish one; IronDost's API already serves the catalogue publicly.
5. **In-app support with call, form and photo** (partial: Help screen and call only).
6. **Damage or loss policy with a stated remedy** (partial: an FAQ answer, no claim record).

## Layout diff (replica-diff step 2)

Five like-for-like screens, IronDost's own 390 × 844 captures against Fabrico's raw Android screens (the only competitor set with unframed app screens). Structural similarity from `imgdiff.py`, layout mode (edges and positions, colour ignored):

| Screen | Fabrico reference | IronDost | Similarity | Verdict |
|---|---|---|---|---|
| Home | `screens/fabrico/play-03.jpg` | S11 home | 24.2 | different |
| Pickup schedule | `play-05.jpg` | S16 schedule | 27.3 | different |
| Orders | `play-07.jpg` | S20 orders | 17.9 | different |
| Account | `play-06.jpg` | S29 account | 12.4 | different |
| Outside service area | `play-02.jpg` | S07 outside area | 2.1 | different |

Average 16.8. **Good: IronDost's layouts do not resemble the white-label platform used by Fabrico and Tumbledry.** The score cannot say whether the differences are improvements; that needs the design comparison in [design/design-teardown.md](design/design-teardown.md). Diff images are in `diffs/`. Limits: the references include an Android status bar and bottom bar that IronDost's captures lack, and the pairs are not in identical states.

## Behaviour diff (replica-diff step 3)

| Flow | Competitors do | IronDost does | Fix or keep |
|---|---|---|---|
| Taps to book for a returning user | DhobiLite about 4 (day, slot, Place Order, Confirm); Fabrico 4 to 5; Tumbledry about 6. All three skip items and price (agent tap counts; DhobiLite and Fabrico steps observed, Tumbledry partly inferred). | About 8 to 10 taps plus one per item, **estimated from the route structure, not measured**: Book, items, Basket, Schedule, Checkout, Pay. | Keep the price step; it is the differentiator. Shorten with Book again, default slots and a Quick order that still ends in an approved price. |
| What the customer sees before committing | Service type and a time slot. DhobiLite and Fabrico show no price or total; billing happens after intake. | Itemised basket, server quote, pickup and delivery windows, payment choice. | Keep. Make it visible on the website too (public price list). |
| Price changes after pickup | Reviews at all three allege the billed rate differed from the quote (about 6% of sampled reviews). | Staff can reprice in the admin, the customer is told the new total, staff get a refund alert. No customer approval step. | Add approval before payment (see architecture). |
| Choosing speed | Express options at all five, shown as a surcharge. | None. Fixed 20-hour minimum. | Build (must). |
| Pickup window length | 1 h (Tumbledry, Fabrico), 2 h (DhobiLite), 2.5 h (LaundryMate). | 4 to 5 h windows. | Configurable windows (should). |
| Rescheduling | Reschedule button (Tumbledry, Fabrico). Reviews complain the company reschedules for them. | Cancel and book again. | Add reschedule (should). |
| Support | Call, WhatsApp tab, form with photo. Reviews: unanswered calls and hang-ups. | Help screen and a support call. | WhatsApp one-tap, order-linked report with status (must). |
| Sign-in vs area check | Fabrico shows "not serviceable" before login. DhobiLite and Tumbledry reviews say the area is decided after booking. | Sign-in, then address, then area check with a clear outside-area screen. | Keep. Consider a pre-login area check by PIN code. |
| After delivery | No rating prompt seen at any of the five. | None. | Opportunity: simple rating plus "report a problem". |

## Verdict (replica-diff scale)

- **Not at market parity:** 6 of 16 must-haves missing, feature score 55.7. These are gaps to plan, and the plan is in [architecture.md](architecture.md).
- **Not tested:** no end-to-end or device testing was done in this pass, so there is no statement about open S1 or S2 bugs. The repo's own list of unfinished device checks stands (Maps, SMS autofill, Razorpay native, push, screen readers).
- **Better than the market on several points that can be shown today:** price before pickup, server-quoted bill, separate pickup and delivery windows, honest overdue labels, light and dark themes, and contrast that passes on every measured pair.

## Top five to build next

1. Express and priority option with the surcharge shown (M).
2. Order-linked problem report with status and a response clock (M).
3. Customer approval of price changes after pickup (M).
4. WhatsApp one-tap support, then order updates (S, then M).
5. Public price list and a handful of real neighbourhood pages on the website (S to M).
