# Pricing research

replica-launch step 2. Date 2026-11-07. Prices change; every figure carries where it came from and how far I checked it.

**Verification levels:** *Live API* = read by me today from IronDost's own public endpoint. *Agent-observed* = read by a research agent on the competitor's public page and **not re-checked by me**. *Listing screenshot* = visible in a store image, may be sample data.

## 1. IronDost's live catalogue needs a decision from you

Read today from `GET /v1/catalog` on the production API (read-only, public endpoint):

| Category | Item | Live price |
|---|---|---|
| Ironing | Shirt / T-shirt | ₹15, **offer price ₹10** |
| Ironing | Trousers / Jeans | ₹15 |
| Ironing | Kurta | ₹20 |
| Ironing | Saree | ₹50 |
| Ironing | Dupatta | ₹10 |
| Ironing | Bedsheet (single) | ₹25 |
| Wash & Iron | Shirt / T-shirt, Trousers / Jeans, Bedsheet (double) | ₹35, ₹40, ₹70 |
| Dry Cleaning | Suit (2 piece), Blazer, Silk saree | ₹350, ₹200, ₹250 |

**These are the same values as the sample catalogue in `apps/api/prisma/seed.ts`**, whose own comment says the prices are placeholders and must never be shown to real customers; the only difference is the ₹10 offer on the shirt. `.agents/product-marketing.md` also says launch pricing is still an open decision. The Play listing is public (10+ downloads), so if these are not your intended prices they are live now. If they are intentional, ignore this paragraph. I cannot see the minimum order or delivery fee (they default to ₹0 in `business_settings`; set in the admin).

## 2. What competitors publish for the same job

Ironing per piece, near LB Nagar:

| Item | DhobiLite, Bandlaguda (agent-observed) | Fabrico, Dilsukh Nagar (agent-observed) | Tumbledry | IronDost live |
|---|---|---|---|---|
| Shirt | ₹50 (₹38 first order) | ₹20 (premium press with hanger ₹30) | no Hyderabad price public | ₹15 (₹10 offer) |
| Trouser | ₹70 (₹53) | ₹15 | no | ₹15 |
| Kurta | ₹70 (₹53) | ₹25 | no (sample store elsewhere: ₹30 plain) | ₹20 |
| Saree | ₹119 (₹89) | ₹20 | no | ₹50 |
| Single bedsheet | ₹79 (₹59) | not shown | no | ₹25 |

Wash by weight: DhobiLite Hyderabad wash and fold ₹100/kg (₹75 first order), **wash and iron ₹144/kg** (₹108), premium ₹216; Fabrico Dilsukh Nagar **wash and iron ₹119/kg**, wash and fold ₹180/kg (dearer than wash and iron, which looks odd and which I could not verify), premium ₹199; Tumbledry's only in-app sample (a store in an unknown city, probably Kolkata): wash and fold ₹90/kg, wash and steam iron ₹130/kg.

I re-checked only part of this: Fabrico's pricing page shows a default Lucknow block that matched the agent's numbers exactly, but the Dilsukh Nagar numbers load only after a store is selected in a browser and I could not reproduce them. Full tables with sources: [DhobiLite](../competitors/dhobilite/teardown.md) section F, [Fabrico](../competitors/fabrico/teardown.md) section F, [Tumbledry](../competitors/tumbledry/teardown.md) section F.

Outside Hyderabad, as category context only: LaundryMate's listing screenshot shows a shirt at ₹25 to ₹30 and jeans at ₹50 (Bengaluru, sample data).

Rules around the price:

| | DhobiLite | Tumbledry | Fabrico | LaundryMate | LaundroKart |
|---|---|---|---|---|---|
| Minimum order | ₹299 + tax | ₹350 for free delivery | ₹349 | not found | not found |
| Express | 12 h at +40% | 1.5× or 2× (two pages disagree) | same day +100%, next day +50% | +20% tags on slots | Semi and Express multipliers |
| First order | 25% (code MY25) | flat 20% | up to 20 to 25% | 20% banner | not seen |

## 3. What the numbers say

- **Ironing prices in the same area differ by 2.5×** for a shirt (₹20 to ₹50). There is no single market price to match; a clear, honest price is a better lever than being cheapest.
- **Minimums are high relative to ironing.** ₹349 is about 17 shirts at ₹20 or 7 at ₹50. A pickup-and-return trip costs the same whatever is in the bag, which is why minimums exist, and why IronDost with a ₹0 default minimum needs a deliberate choice (a minimum, a delivery fee, or both) before volume.
- **Express is priced as a multiple, +20% to +100%, and described inconsistently.** The consistent version of it is itself a differentiator (one rule, shown beside the option).
- **Price complaints in the review sample:** 12 of 220 reviews say the billed price differed from the quote (6%), 8 say it is too expensive (4%). The first is a transparency problem IronDost can fix; the second is a positioning choice.
- **Plan terms disagree between the competitors' own surfaces** (Tumbledry package percentages, DhobiLite's "Big" plan at ₹3,499 on the site and ₹5,555 in store art; both are in the saved screenshots). One source of truth for every price and term is cheap to do and rare.

I have **no cost data**, so I make no recommendation on the level of any price. The questions only you can answer: cost per pickup and per kg or piece, target margin, minimum order, delivery fee, express surcharge, first-order offer.

## 4. Model options (not decisions)

1. **Per-piece ironing menu with a public rate card**, a modest minimum or delivery fee, and a flat first-order offer. Closest to today's catalogue.
2. **Add a per-kg wash and iron line** for everyday bundles (the schema already has a KG unit).
3. **Add express as a visible surcharge** after capacity is proven ([architecture.md](../architecture.md)).
4. **Prepaid credit with a bonus** only after an accountant confirms the rules; competitors' versions generated the most term-inconsistency.

Three tiers at most; name any plan by who it is for, not by size. One-click, plain-language renewal and cancellation if a plan ever renews.

## 5. Billing complaints turn into product work

Quote-versus-bill disputes: customer approval before any price change after pickup ([fixes.md](../fixes.md), item 2). Late charges and hidden fees: show the delivery fee and any minimum in the basket before payment (IronDost already shows its bill lines). Payments run on Razorpay, so there are no Stripe products to create; a wallet pack would be a row in `wallet_packs`.
