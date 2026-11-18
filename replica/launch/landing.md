# Landing page draft

replica-launch step 1. Copy is written fresh, in IronDost's voice (helpful, local, direct), and **only claims what the product does today**. Anything that depends on unbuilt features is listed at the bottom as "do not publish yet".

Recommended angle (from [fixes.md](../fixes.md)): **price before pickup**. It is the one claim IronDost can show in a screenshot today.

## Hero

**Headline:** See the price before we pick up.
**Line under it:** Ironing, wash and iron, and dry cleaning at your door in LB Nagar and nearby. Pick the items, see the total, choose your pickup and return windows.
**Button:** Book a pickup
**Secondary:** Check my address (opens the area check)
**Image:** a real screenshot of the basket with the itemised bill. Not a stock photo.

## The problem (paraphrased, no quotes, no competitor names)

Many pickup services tell you the price after your clothes are already gone, and the bill can differ from what you were told. IronDost shows each item's price and the total before you confirm.

## How it works

1. **Choose.** Pick ironing, wash and iron, or dry cleaning, and add your items. The total updates as you go.
2. **Schedule.** Choose a pickup window and a return window. See both before you confirm.
3. **Pay and follow.** Pay online or in cash on delivery, and follow the order from pickup to delivery.

## Features (today's, each tied to something built)

| Line | Built? | Evidence |
|---|---|---|
| Itemised prices and a total before you book | Yes | Server-calculated quote, basket (S14) |
| Separate pickup and return windows | Yes | S16 |
| Step-by-step order status with notifications | Yes | `OrderStatus`, push, realtime |
| Pay online (UPI, cards, netbanking) or cash on delivery | Yes | Razorpay, cash with admin |
| Cancel before pickup | Yes | S44 |
| Book again from a finished order | Yes | `order_card.dart` |
| Light and dark mode, large text supported | Yes | IMPLEMENTATION.md |

## Pricing

Link to the public rate card (to be built, [fix 8](../fixes.md)). Until then, show the three categories and a "see prices in the app" line. **Confirm the live prices first** ([pricing.md](pricing.md) section 1).

## FAQ (real objections from the product-marketing doc, answered with what is true)

- **Will you serve my address?** Enter it in the app to check. We serve [neighbourhoods, from `service_pincodes`]. (Fill with the live PIN list.)
- **Will the price change after pickup?** If the count differs from what you booked, our team updates the items, the total is recalculated, and you are told the new total. *(Do not add "and you must approve it" until that feature exists.)*
- **What if something is damaged or late?** Describe the real policy from `docs`/Help here once the owner has written it; today the app offers a support call and Help answers.
- **Why not my neighbourhood ironing person?** You get pickup, a price you see first and an order you can follow. We are not trying to replace anyone.
- **Can I pay cash?** Yes, on delivery, where enabled.

## Proof

Empty on purpose. No testimonials, user counts, ratings, press or "trusted by" rows until they are real and recorded with permission. Reviewers of other apps are research, not testimonials.

## Final call to action

Book your first pickup. (Add the first-order offer here only after it is implemented: today the "2 shirts and 2 pants free" idea is a draft the server cannot grant.)

## Do not publish yet

| Claim | Why not |
|---|---|
| "Approve any price change" | Not built (order adjustments, [architecture.md](../architecture.md)). |
| "Express delivery", "same day", "in a day" | No express option; default minimum turnaround is 20 hours. |
| "Someone always answers", "reply within X" | No ticket system or response clock yet. |
| "One-hour pickup windows" | Windows are 4 to 5 hours today. |
| "Live tracking" as a map | Status updates are step-based; no live rider map. |
| "Cheapest", "lowest price" | No cost data and no competitor price is stable enough to claim it. |
| Telugu or Hindi | English only. |
| Any competitor's name, logo or reviews | Name in no ad, listing, keyword or page; a comparison page is a question for a lawyer. |

Run the contrast check on the page before launch: `python3 ~/.claude/skills/replica-design/contrast.py replica/design/irondost.light.tokens.json` (passes today for the app tokens).
