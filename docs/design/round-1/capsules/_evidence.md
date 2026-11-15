# Evidence capsule: IronDost customer app, Round 1

Withheld from the first visual encounter. Facts only; the premises are in the per-direction capsules (A to J).

## Subject and intent

- **Subject:** IronDost, a doorstep ironing, washing and dry-cleaning service in Hyderabad. A customer books a pickup in a time window; a delivery partner collects the clothes, the workshop processes them, a partner brings them back.
- **Intent (from the user's request):** a better visual design for the customer app. Typography-led directions are the first test; concrete screens come after one direction is locked.
- **Audience and context:** households in Hyderabad using a phone, often one-handed, often outdoors or in bright light. Hyderabad speaks Telugu, Urdu, Hindi and English; the app is English only today, with Telugu and Hindi planned.

## First-party language used as working copy

Taken verbatim from the shipped app (Welcome, Choose items, Pickup and delivery, Checkout screens). Item names and prices come from the current store screenshots and are provisional working copy, not a price list.

- IronDost
- Fresh clothes, back at your door.
- Ironing, washing and dry cleaning, picked up and delivered.
- Choose your pickup and delivery times.
- Your partner arrives within the window you pick.
- Morning 7 – 11 AM / Afternoon 11 AM – 4 PM / Evening 4 – 8 PM
- Shirt / T-shirt ₹35 per piece / Trousers / Jeans ₹40 per piece / Bedsheet (double) ₹70 per piece
- A rough count is fine. Your partner confirms it at pickup.
- Pay online or in cash at delivery.
- Get started

## Observations from the subject

1. Price is per piece, so the order is a count of garments. Neighbourhood ironing has long worked from a tally of pieces.
2. The promise is a time window, not a time: three fixed windows (4, 5 and 4 hours) and "within the window you pick".
3. The name joins "Iron" and "Dost" (friend). The shipped design system already colours the two parts differently.
4. The customer's count may be rough; the partner's count at pickup is the exact one. Two voices, one transaction.
5. The service is a round trip: out from the door, through the workshop, back to the door.
6. Pressing flattens: heat and weight remove creases; a crisp garment hangs straight.
7. The aim of the service is less effort for the customer; the best screen asks for very little.
8. Money is rupees (the ₹ sign must exist in every face) and is paid online or in cash, to a person.

## Tensions to preserve

- Exact promise (windows, per-piece prices) against a relaxed instruction ("A rough count is fine").
- An automated booking flow against a person who arrives ("Your partner").
- Speed (a delivery window) against care (pressing takes time).

## Constraints that change Round 1

- The medium is a phone screen, so the pages are composed to hold from about 360 px wide upward; they are browser pages, not a phone mock-up.
- Every face must contain ₹ (U+20B9) and the en dash. Where a display face lacks ₹, the stack falls back for that one glyph only.
- Telugu and Hindi are not in the working copy, so Round 1 judges Latin typography only. Script coverage is a Round 2 requirement for the locked direction.

## Source boundary

- **Allowed:** the copy above, the app's own flow and status model (`order-state.ts`), its token notes, the user's request, facts about Hyderabad's languages, and the physical behaviour of ironing and garments.
- **Prohibited during creation:** other designers' or companies' interfaces and identities (including competitor apps and the market-research document in `docs/`), galleries, trend reports, templates and UI kits, icon libraries, Google Fonts and Material or platform house styles, AI-generated concepts.
- **Functional research done:** the current screens and theme tokens were reviewed for the separate design critique (`docs/design/customer-app-critique.md`). Only usability constraints were taken from that review (phone width, contrast limits, need for a contact-number row); no typography, spacing or colour from the current app was reused here.

## Unresolved

- Final copy, real prices and real time windows.
- Telugu and Hindi strings and their typefaces.
- Whether the Round 2 build keeps light and dark themes.
