# IronDost: marketing plan, November 2026 to November 2027

**For:** the IronDost owner and team
**Date:** 18 November 2026
**Status:** Draft v1. Written in one pass from the repository, the earlier plans and public pages, without an interview. Everything I could not confirm is listed in §13 as an open decision, not assumed.

This plan replaces nothing. It builds on the [Dasara launch plan](irondost-hyderabad-dasara-launch-plan.md), the [November LB Nagar plan](irondost-november-2026-lb-nagar-plan.md), the [1–7 November social plan](irondost-november-1-7-social-plan.md) and the competitor study in [`replica/`](../../replica/README.md). The ready-to-post creatives for the next six weeks are in [december-2026-pack](december-2026-pack/README.md), and the weekly Instagram plan is in [instagram/plan.md](instagram/plan.md).

## 1. Executive summary

**What this plan optimises for:** delivered first orders inside the seven served PIN codes, and a second order from the same home within 14 days. Not installs, not followers.

**Three bets, in order of leverage**

1. **Win one neighbourhood at a time, by hand.** IronDost serves a 6 km circle around LB Nagar Circle and seven PIN codes. A flyer in a lift, a security-desk QR code and one resident who vouches for you reach every home in a building at almost no cost, and every extra order in the same building makes the pickup trip cheaper. Target 15 apartment communities and 10 PGs before spending more on ads.
2. **Sell the price, not the app.** The live rate card (shirt ironing ₹20, ₹15 on offer; wash and iron shirt ₹35; saree ironing ₹50) is clear and low next to what nearby chains publish (a shirt at ₹20 to ₹50, with ₹299 to ₹350 minimums). "See the price before we pick up" is the one message every ad, poster and reel should carry. No competitor name, no "cheapest".
3. **Make the second order automatic.** Ironing is a weekly problem. A customer who books twice in a month is worth many times a one-off. A weekly pickup day per building, a reminder at day 6, and a neighbour referral credit turn one order into a routine.

**What twelve months plausibly looks like** (targets to test, not forecasts; there is no order data yet)

- LB Nagar circle filled to a steady share of today's capacity (8 pickups per window, 3 windows a day, so 24 a day at most) before any second area.
- Half or more of weekly orders from repeat customers.
- 50 or more honest Google reviews and a rating that reflects real service.
- A measured cost per delivered first customer for each channel, and paid spend only on the channels that pay back.
- A decision, made on data from the "Outside the area" waiting list, on whether and where to open a second hub.

**The next 90 days**

1. Fix the six blockers in §3 (support phone is empty in production, analytics, Google Business Profile, handles, the travel-charge release, the offer).
2. Post the December pack: 4 to 5 posts a week, at least 3 reels (§4, [instagram/plan.md](instagram/plan.md)).
3. Apartment and PG outreach: 5 new buildings a week, each with its own code.
4. Run one click-to-WhatsApp ad test at ₹200 to ₹300 a day, judged on delivered orders.
5. Start the repeat loop: after-delivery message, review request, day-6 reminder, referral code.
6. Review every Monday with the scorecard in §13.

## 2. Strategic frame

**What IronDost is:** IronDost picks up clothes from homes around LB Nagar, irons, washes or dry cleans them, and brings them back, with the price and both time windows shown before the customer confirms.

**Category:** doorstep ironing and laundry, in a defined existing category. IronDost does not need to explain the category; it needs to be the obvious local choice inside it.

**Problem size and frequency:** high frequency, small to medium problem. Clothes need pressing every week, and no single week is a crisis. That quadrant builds habits and churns on price and reliability. It means: low order values (a 10-shirt ironing order is ₹150 to ₹200), so the cost of winning a customer must be very low or be repaid by repeat orders; and retention matters more than acquisition.

**Who it is for**

- Working households in apartments in LB Nagar, Dilsukhnagar, Chaitanyapuri, Saroornagar, Mansoorabad, Nagole, Bandlaguda, Vanasthalipuram, Karmanghat, Champapet, Santosh Nagar and Saidabad. School uniforms and office shirts every week.
- Young professionals and students in PGs and hostels, especially around Dilsukhnagar's coaching belt. Small, frequent orders; no iron or machine.
- Occasion buyers: sarees, suits and blazers before weddings and festivals. Higher order value, lower frequency.
- Later: salons, clinics, small offices with weekly linen or uniforms.

Stated problem: "no time to iron." Real problem: "I do not trust a new person with my clothes, and I do not want to be surprised by the bill or the return date."

**Business model logic:** per-piece prices; pickup and return are the main cost and are the same for 3 shirts or 30. The ₹200 rule (flat ₹30 travel charge under ₹200, decided 15 November, built, not yet in production) and building-level density are what make small orders viable. The compounding asset is route density: more orders per building per trip.

**Voice (hard rules)** from [`.agents/product-marketing.md`](../../.agents/product-marketing.md) and [`replica/brand.md`](../../replica/brand.md)

- Helpful, local, direct, reassuring. Short plain sentences.
- Say: doorstep, clear price, pickup slot, return window, crisp, everyday laundry, LB Nagar, wash and iron.
- Do not say until proven: cheapest, fastest, same-day, guaranteed stain removal, zero damage, premium, 100% safe, "live tracking" (say "track your order step by step").
- Never name a competitor. Never publish a review without the customer's permission. Never ask for positive reviews in exchange for anything.
- Royal blue `#1F4FD1` leads; yellow `#FFC93C` only as a small offer marker.
- Telugu lines are checked by a Telugu speaker before posting.

## 3. Current state (scored from materials, not from an audit interview)

**Verified on 18 November 2026**

| Item | State | Source |
| --- | --- | --- |
| Android app | Live, "10+" downloads, last updated 3 Nov | Play listing |
| iPhone app | Live, version 2.0.0, India | App Store search |
| Live prices | Ironing: shirt ₹20 (offer ₹15), trousers ₹15, kurta ₹20, saree ₹50, dupatta ₹10, single bedsheet ₹25. Wash and iron: shirt ₹35, trousers ₹40, double bedsheet ₹70. Dry cleaning: suit ₹350, blazer ₹200, silk saree ₹250 | Production catalogue |
| Pickup windows | 7 to 11 am, 11 am to 4 pm, 4 to 8 pm | Production config |
| Earliest return | 20 hours after pickup at the earliest | Production config |
| Travel charge in production | ₹0, no minimum. The ₹30-under-₹200 rule is built but not deployed | Production config, git log |
| Support phone and email in production | **Empty** | Production config |
| Live promotions | None | Production API |
| Service area | 6 km around LB Nagar Circle and PINs 500074, 500060, 500035, 500068, 500070, 500079, 500059 | Area rules plan |
| Phone | Main 79934 34932, second 70329 90632 (given by the owner on 18 Nov; whether WhatsApp is on the main number is not confirmed) | November plan |

The prices changed since 7 November (shirt was ₹15 with a ₹10 offer), which suggests someone set them on purpose. Please confirm they are final (§13).

**Team and budget:** not stated anywhere. The plans assume the owner covers campaign, WhatsApp replies and outreach, with one operations person. Budget in earlier plans: ₹5,000 to ₹10,000 a month. No results from October or November are recorded.

**Phase:** before the first 100 customers. The binding constraint is trust and proof, not reach.

**Scorecard (0 to 5)**

| Area | Score | Why |
| --- | --- | --- |
| Positioning and message | 4 | Clear, written down, differentiated on price clarity |
| Product and booking flow | 4 | App live on both stores; basket, slots, payment, tracking, care notes |
| Pricing and offer | 2 | Prices live; no confirmed first-order offer; travel rule not deployed |
| Measurement | 1 | No analytics in the app; no recorded campaign results |
| Social presence | 2 | A week of creatives and one reel made; no evidence of what was posted or how it did |
| Local search (Google Business Profile, reviews) | 0 | No evidence a profile exists |
| Paid acquisition | 1 | Planned, no results recorded |
| Community and partnerships | 1 | Planned, no results recorded |
| Retention and referral | 1 | Reschedule, ledger and alerts built; no reminder or referral loop running |
| Proof (reviews, real footage) | 0 | None published |

**Six blockers to clear before spending**

1. Put the support phone and email into production settings. A customer with a problem and no number is the worst advert.
2. Deploy the travel-charge and service-area release (migrations are on the release checklist), then set ₹30 and ₹200 in admin.
3. Create or claim the Google Business Profile as a service-area business.
4. Confirm the Instagram and Facebook handles, the bio link and the WhatsApp Business quick replies.
5. Decide the first-order offer and create it in admin, or run with none (§8).
6. Decide how orders will be traced to a source (§13). Until the app has analytics, the admin's order list plus a source question on WhatsApp is enough.

## 4. Acquisition: how a stranger hears about IronDost

Ranked by expected cost per delivered order for a business this size. Rank is my judgement; your own numbers after four weeks replace it.

| # | Channel | First 90 days | 12 months | Status |
| --- | --- | --- | --- | --- |
| 1 | Apartment communities | 5 buildings a week: ask the association or manager, put up the lift poster with a building code (`APT01`…), offer one shared pickup window | 60+ buildings with a weekly pickup day each | Now |
| 2 | PGs and hostels (Dilsukhnagar, Chaitanyapuri) | 10 PGs: a notice-board poster and one weekly pickup day per PG | Monthly account per PG where the owner wants one | Now |
| 3 | Google Business Profile and Maps | Create profile, real photos, weekly post, ask every happy customer for an honest review | 50+ reviews; ranks for "ironing near me", "laundry pickup LB Nagar" | Now |
| 4 | Instagram and Facebook, organic | The December pack; reels in Telugu and English; real process footage as soon as it exists | A library of proof reels; local reach inside the circle | Now |
| 5 | Click-to-WhatsApp ads | One campaign, 6 km around the centre pin, ₹200 to ₹300 a day, two creatives | Scale only the creative with the lowest cost per delivered order | Now, small |
| 6 | WhatsApp status and broadcast to opted-in customers | Weekly: slots open, festival reminders | Core repeat channel | Now |
| 7 | Flyers with a QR code | 1,000 A5 flyers through newspaper inserts in two colonies, one code per colony | Repeat only where the code was used | Test once |
| 8 | Local partners: tailors, boutiques, saree shops, dry-clean-free laundromats | 5 counters with a small standee and a code | Referral credit for the partner | Weeks 5 to 8 |
| 9 | Local creators (5k to 50k followers, east Hyderabad) | One paid, disclosed trial with a trackable code | Repeat only if orders came | Weeks 9 to 12 |
| 10 | Schools (uniform ironing) | Ask two schools' parent groups through a parent you know | Uniform bundle in June | Q3 2027 |
| 11 | Google Search ads | Skip for now | Test "laundry pickup near me" at ₹150 a day once the profile has reviews | Q2 2027 |
| — | Citywide ads, newspaper ads, radio, hoardings, app-install campaigns | Skip | Skip | Not for a 6 km service |

**Why ads are fifth, not first.** Public figures for click-to-WhatsApp in India are vendor estimates and range widely, from about ₹20 to ₹120 for a conversation and ₹80 to ₹350 for a qualified lead ([Spur](https://www.spurnow.com/id/blogs/click-to-whatsapp-ads-benchmarks), [Kanal](https://getkanal.com/es/blog/click-to-whatsapp-ads-benchmarks-2026)); none covers a local laundry. With a first order worth ₹150 to ₹300, an ad that costs ₹150 per delivered customer only makes sense if that customer comes back. Run it small, measure delivered orders, and let apartments and Maps carry the base.

**The ad test, exactly**

- Objective: messages to WhatsApp. Location: a pin on LB Nagar Circle, smallest radius that covers the served PINs; "people living in this location".
- Creative A: the "price" reel. Creative B: the "pile to pressed" reel. Same text.
- Text: "LB Nagar, ironing piling up? IronDost picks up from your door. Shirt ironing from ₹15. See the price and the return slot before you confirm."
- Headline: "Laundry pickup near you". Button: Send WhatsApp message.
- Budget: ₹250 a day for 7 days (₹1,750). Stop a creative after ₹600 with no serviceable chat.
- Judge on: cost per delivered first order, and share of chats inside the served PINs.

## 5. Activation: from "interested" to a first delivered order

The first order is the product demo. Moves, in order:

1. **Answer in five minutes during working hours.** WhatsApp quick replies for: area check, rate card image, how it works, slots today.
2. **Send the rate card as an image**, not a link, then the app link. The rate card in the December pack is made from the live catalogue.
3. **Remove the "is my area covered" doubt** up front: every creative names the localities. Outside the circle, the app already offers "Tell me when you're here"; say so.
4. **Guide the first basket past ₹200** once the travel rule is live: "8 shirts and 4 trousers is ₹220, travel is free."
5. **Phone orders for people who will not install an app.** Staff can already place phone orders in admin. The app remains the main route; nobody is refused for not using it.
6. **Store listings.** Change "Available in Hyderabad" to the true area; first screenshots should show the basket with prices and the two time windows ([brand.md](../../replica/brand.md)).
7. **First-order message at pickup and at delivery**, from a person, by name.

Target to test: 60% of serviceable chats get a quote within 5 minutes; 40% of quotes become a booked pickup.

## 6. Retention: the second and third order

| Move | When | How |
| --- | --- | --- |
| "Did everything come back right?" | 2 hours after delivery | WhatsApp, personal. Fix anything the same day |
| Honest review request | Next day, only if they said yes above | Google review link. No reward |
| "Same time next week?" | Day 6 | One message, only to customers who agreed to reminders. The lapsed list in the planned Insights page drives this later |
| Building pickup day | From 5 customers in a building | "Every Tuesday evening at {building}" becomes the habit |
| Festival and season prompts | Before weddings, Christmas, New Year, Sankranti, school reopening | One message each, to opted-in customers |
| Lapsed win-back | 30 days without an order | One message; ask what went wrong before offering anything |

Service is the retention plan: on-time pickup, on-time return, the bill equal to the quote. The competitor review study found unanswered support was the most common complaint (18% of 220 reviews) and bills that differed from the quote were 6% ([pricing.md](../../replica/launch/pricing.md)). Being reachable and predictable is the difference customers will feel.

Target to test: 35% of first-time customers order again within 14 days.

## 7. Referral

- **Neighbour code.** After the second order, give each customer a short code. Suggested: ₹50 credit to both sides on the friend's first delivered order of ₹200 or more. The wallet exists; the referral rule does not, so run it by hand through coupons until it is built. Confirm the cost first.
- **Building champions.** One resident per building who shares the weekly pickup message. Thank them with free ironing credit each month, agreed in advance and disclosed.
- **Partner counters.** Tailors and boutiques hand a card with their code; pay a fixed credit per delivered first order.
- **Shareable proof.** A "returned and packed" photo sent with the delivery message is the thing customers forward.

## 8. Revenue

- **Prices:** confirm the live rate card is final. I have no cost data, so I make no claim about the right level.
- **Order size:** the ₹200 line is the main lever. Show "add ₹X more and travel is free" (built) and suggest bundles in posts: "Office week: 5 shirts and 5 trousers, ₹175."
- **First-order offer, three options.** (a) None: the price is already the offer. (b) ₹50 off a first order of ₹250 or more. (c) Keep the ₹15 shirt offer as the hook, which is what is live now. My recommendation is (c) until 30 orders show whether price or trust is the real barrier, because a deeper discount on a ₹200 order leaves nothing to pay for the trip.
- **Higher-value work:** sarees, suits and blazers before weddings carry ₹200 to ₹350 a piece. Push these in wedding weeks.
- **Later:** per-kg wash and iron for families, a monthly ironing pass per building, and PG or small-business accounts. All after the pilot proves the basics.

**Unit economics you need to fill in** (per delivered order): amount paid − discount − ironing or washing cost − rider cost for two trips − packaging and payment fee = contribution. The highest sensible cost per new customer is that contribution times the number of orders you expect from them in three months. No target is defensible until these are known.

## 9. Ninety-day roadmap (19 November 2026 to 16 February 2027)

| Weeks | Dates | Moves | Stage | Owner |
| --- | --- | --- | --- | --- |
| 1–2 Unblock | 19 Nov – 2 Dec | Six blockers in §3. Post launch-of-pack reel and rate card. Film 10 real clips (pickup, counting, pressing, packing). First 5 buildings | All | Owner; ops lead for filming |
| 3–4 Foundation | 3 – 16 Dec | Ad test (7 days). Google profile posts weekly. 10 buildings and 5 PGs reached. After-delivery and day-6 messages running. Wedding-wear posts | Acquisition, Retention | Owner |
| 5–8 Velocity | 17 Dec – 13 Jan | Christmas, New Year and Sankranti posts. Referral code to every second-order customer. Partner counters. Second ad round with the winning creative. First real customer review reel (with permission) | Acquisition, Referral | Owner; partner for outreach if hired |
| 9–12 Compound | 14 Jan – 16 Feb | Building pickup days. One creator trial. Review which channels paid back; drop the rest. Read the outside-area list and decide on area changes | Retention, Revenue | Owner |

## 10. Twelve-month outlook

| Quarter | Aim | Unlocks only when |
| --- | --- | --- |
| Nov 2026 – Feb 2027 | First 100 customers, measured channel costs, repeat loop running | Blockers cleared |
| Mar – May 2027 | Fill the circle: 60 buildings, PG accounts, summer and Ugadi (date to confirm), school holidays | On-time pickup and return above 90% for four weeks |
| Jun – Aug 2027 | School reopening uniform push, monsoon "clothes won't dry" wash and iron push, per-kg line if costs support it | Contribution per order is positive |
| Sep – Nov 2027 | Bathukamma, Dasara, Diwali; decide on a second hub from waiting-list demand | Steady repeat rate and spare capacity plan |

Capacity is the ceiling on marketing: 24 pickups a day today. When a window shows Full for a week, raise capacity before raising spend.

Budget tiers, as scenarios: ₹5,000 a month (print ₹1,500, ads ₹3,000, reserve ₹500); ₹10,000 (print ₹2,000, ads ₹6,000, creator or partner credits ₹1,500, reserve ₹500); ₹25,000 only after a channel shows a cost per delivered customer below the three-month contribution. Roughly 70% on what already works, 20% on the next channel, 10% on one experiment.

## 11. Tools and who does what

| Stage | Work | Tool |
| --- | --- | --- |
| Acquisition | Posters, carousels, reels | The generators in [december-2026-pack](december-2026-pack/README.md) and `videos/irondost-reels/` (HTML to image, HyperFrames to video); Codex for photo-style images |
| Acquisition | Posting and scheduling | Meta Business Suite (free). A scheduling connector exists in this workspace but nothing is posted without your say |
| Acquisition | Local search | Google Business Profile |
| Activation | Replies, quotes | WhatsApp Business quick replies and catalogue |
| Retention | Reminders, lapsed list | Admin customer list now; Insights page when built |
| Measurement | Orders by source | Admin orders plus a "where did you hear about us" field or coupon codes per channel |

One person can run this in about 60 to 90 minutes a day plus outreach visits. If a second pair of hands is added, make it a part-time field person for buildings and PGs, not an agency.

## 12. Idea bank (short list)

The marketing-ideas library the plan format calls for is not installed here, so this is a shortlist rather than the full cross-reference.

| Idea | Stage | Status |
| --- | --- | --- |
| Lift and notice-board posters with building codes | Acquisition | Now |
| Security-desk QR standee | Acquisition | Now |
| "Rate card" pinned post and highlight | Activation | Now |
| Before and after pile reels with real clothes | Acquisition | Now, needs filming |
| Founder on camera: "why I started IronDost" | Acquisition | Weeks 3–4 |
| Saree and suit care tips series | Acquisition | Now |
| Weekly "slots open today" story | Activation | Now |
| Packed-order photo with delivery message | Referral | Now |
| Neighbour referral credit | Referral | Weeks 5–8 |
| Tailor and boutique counters | Acquisition | Weeks 5–8 |
| Uniform week bundle for schools | Revenue | June 2027 |
| Monsoon wash and iron push | Acquisition | July 2027 |
| Monthly ironing pass | Revenue | After pilot |
| Corporate or clinic linen accounts | Revenue | Q3 2027 |
| Free-garment offers, "cheapest" claims, buying followers or reviews, mass WhatsApp to strangers | — | Skip |

## 13. Measurement, ownership and open decisions

**North star:** delivered orders per week inside the served area.

**Weekly scorecard (Monday)**

| Stage | Measure |
| --- | --- |
| Acquisition | Serviceable enquiries by source (building code, ad, Maps, Instagram, referral) |
| Activation | Quotes sent, first orders booked, first orders delivered |
| Retention | Repeat orders, share of customers ordering again within 14 days |
| Referral | Referral codes used, reviews received |
| Revenue | Average order value, share of orders under ₹200, contribution per order |
| Service | On-time pickups and returns, complaints, bill changes after pickup |
| Spend | Rupees by channel; cost per delivered first order by channel |

**Open decisions for the owner**

1. Are the live prices final?
2. Monthly marketing budget, and who answers WhatsApp in which hours.
3. First-order offer: none, ₹50 off above ₹250, or the current ₹15 shirt (§8).
4. Support phone and email to show customers. Production has neither.
5. When the travel-charge release goes live. The pack avoids claims that depend on it.
6. Actual return time you are willing to state publicly. The app allows 20 hours at the earliest; I have used "you choose the return slot" and no fixed promise.
7. Referral credit amount and champion rewards.
8. What happened in October and early November: orders, spend, which posts went out. Nothing is recorded.
9. Instagram and Facebook handles. I did not find them in the repository.
10. Whether WhatsApp is active on the main number 79934 34932. Every creative says "Call or WhatsApp" with that number.

**Sources:** production catalogue and config read 18 November 2026; [`replica/launch/pricing.md`](../../replica/launch/pricing.md) for competitor prices (partly unverified, see that file); [area and order rules](../ui-ux-audit/review-2026-11-14/AREA-AND-ORDER-RULES-PLAN.md); ad cost ranges from [Spur](https://www.spurnow.com/id/blogs/click-to-whatsapp-ads-benchmarks) and [Kanal](https://getkanal.com/es/blog/click-to-whatsapp-ads-benchmarks-2026), both vendor estimates.
