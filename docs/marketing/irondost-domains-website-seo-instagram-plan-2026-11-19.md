# IronDost: domains, website, blog and Instagram plan

Written 19 November 2026. Facts were checked that day; anything marked **you** needs the owner.

## 1. Domains: irondost.in, irondost.com, irondost.shop

### What exists today (checked with RDAP on 19 Nov)

| Domain | Status | Registrar | DNS |
| --- | --- | --- | --- |
| irondost.in | Registered 18 Nov 2026, expires 18 Nov 2027 | Hostinger | Parked (dns-parking.com) |
| irondost.com | Registered 18 Nov 2026, expires 18 Nov 2027 | Hostinger | Parked (dns-parking.com) |
| irondost.shop | **Not found in the registry** | n/a | n/a |

**You:** buy irondost.shop at Hostinger if you want it (or check the order went through), and turn on auto-renew for all three.

### Decision

- **irondost.in is the main address.** Customers are in Hyderabad; `.in` reads local and is what goes on posters, the app stores and Google Business Profile.
- **irondost.com and irondost.shop redirect (301) to irondost.in**, path kept (`irondost.com/blog/x` goes to `irondost.in/blog/x`). They protect the name; they never serve their own copy, so search engines see one site.
- **www redirects to the bare domain.**
- **Website on Vercel**, next to the admin. It is a static export, so Vercel serves it as plain files. One dashboard, redirects for all three domains in one place, and a preview link for every change. Firebase Hosting (`irondost-app.web.app`) stays up for now because the store listings link to its privacy and delete-account pages; redirect it to irondost.in once the store links are updated.

| Address | Serves | Where |
| --- | --- | --- |
| irondost.in | Website (`apps/web`) | Vercel project `irondost-web` (new) |
| www.irondost.in, irondost.com, www.irondost.com, irondost.shop, www.irondost.shop | 301 to irondost.in | Same Vercel project |
| admin.irondost.in | Admin (`apps/admin`) | Vercel project `irondost-admin` (live at irondost-admin.vercel.app) |
| api.irondost.in | API | Render service `irondost-api` (custom domain, free on Render) |

### Steps, in order

1. **Create the website project on Vercel** from `apps/web` with `NEXT_PUBLIC_SITE_URL=https://irondost.in`, and deploy. (I can do this; deploying is your go-ahead.)
2. **Add the domains in Vercel:** `irondost.in` as primary, the other five as redirects to it; `admin.irondost.in` on the admin project.
3. **DNS at Hostinger** (hPanel, DNS zone for each domain): replace the parking records with what Vercel shows for each domain, normally an `A` record for `@` and a `CNAME` for `www`. For the API, add `CNAME api` to the address Render gives when you add `api.irondost.in` to the service. Leave MX records alone if you set up email.
4. **Wait for HTTPS** (Vercel and Render issue certificates once DNS resolves; minutes to a few hours).
5. **Point everything at the new addresses:**
   - API `CORS_ORIGINS` on Render: add `https://admin.irondost.in` (and `https://irondost-admin.vercel.app` while it is still in use).
   - Firebase, Authentication, Authorized domains: add `admin.irondost.in` and `irondost-admin.vercel.app`, or phone sign-in on the admin fails.
   - Admin env on Vercel: `NEXT_PUBLIC_API_URL=https://api.irondost.in` once the API domain works, then redeploy.
   - Play Console and App Store Connect: privacy policy, support and marketing URLs to `https://irondost.in/...`.
   - Customer app: the API base URL ships in the next release only. Keep the Render address working until old app versions are gone.
6. **Google:** add irondost.in to Search Console (DNS TXT at Hostinger), submit `https://irondost.in/sitemap.xml`, and put irondost.in on the Google Business Profile.
7. **Email (optional):** `hello@irondost.in` through Hostinger email or Zoho; replace the Gmail address in `apps/web/src/lib/site.ts` after it works.

## 2. Website redesign: book and show our work (scroll-craft)

This is the plan, not the build. The scroll-craft method starts with an eight-question brief. Below is a draft with my assumptions marked; **you** answer or correct them, then the build starts.

### Draft brief (assumptions, not your words)

| # | Question | Draft answer | Status |
| --- | --- | --- | --- |
| 1 | Vibe in 3 to 5 words, plus references | Clean, warm, local, trustworthy. References: a freshly folded shirt on a hanger, a hotel laundry slip, the LB Nagar flyover at dusk | **You** |
| 2 | Journey, section by section | Sunday pile, what it costs you, we come to your door, how we handle your clothes, what we do and where, book | **You** |
| 3 | Energy curve | Calm open, a lift at "we come to you", strongest at "our work", calm close | Assumed |
| 4 | Feeling per stage, and the one moment | Recognised, relieved, curious, convinced, decided. Peak: "you drag the iron across the shirt and the creases go" | **You** |
| 5 | One thing no other site does | Visitor presses a real creased shirt photo by dragging across it; the pressed photo appears under the cursor or finger | **You** |
| 6 | How far from premium-minimal | Playful but tidy; not brutalist | **You** |
| 7 | One world or distinct scenes | Distinct scenes, because the content is a process with stages | Assumed |
| 8 | Assets you already have | Logo and brand kit (`packages/brand`), app screens (14 Nov), december-2026-pack posters and photos. Missing: real footage and before/after photos | **You**: film the six clips in the Instagram plan |

### Journey and sections

| Beat | Section | What it shows | How someone books from here |
| --- | --- | --- | --- |
| Recognition | Hero: the Sunday pile | Real photo of a chair heaped with clothes, layered so the pile, the room and the window move at slightly different speeds | Header button "Book a pickup" |
| Turn | At your door | Bag handed over at a door (no faces), the three pickup windows | Store buttons |
| Substance (peak) | Our work | Counted, pressed, folded, packed: real footage. The drag-to-press shirt is the signature moment | |
| Substance | Before and after | 4 to 6 real pairs: shirt, saree with zari, trousers, bedsheet | |
| Range | Services and areas | Ironing, wash and iron, dry cleaning; the 12 localities and 7 PIN codes, with a "Is my area covered?" PIN check that works without the app | Store buttons |
| Commitment | Book | Three ways: app (QR on desktop, store buttons on phone), WhatsApp 79934 34932 with a prefilled message, call. Second number 70329 90632 | All three |

Guides (`/blog`), support and the policy pages stay as they are.

### Booking on the website

- **Phase 1 (with the redesign):** book through the app, WhatsApp or a call. The PIN check runs in the page from the 7 PIN codes, no server needed.
- **Phase 2 (later):** a real web booking form. It needs phone OTP sign-in on the website (the same Firebase setup as the admin) and the API's place-order endpoint opened to the web origin. Treat it as a separate project, about a week of work, because payments, slots and capacity must behave exactly as in the app.

### Before building

- Real photos and clips (from 19 and 20 November filming). No generated "our work" images: the section only works if it is real.
- Prices confirmed (see section 3). The redesign shows a rate card only after that.
- Then build on a preview URL, check it on a real phone, and only then move irondost.in to it.

## 3. SEO setup and the first five guides

### SEO project setup

The OpenSEO connector is not connected in this session, so nothing was saved to an OpenSEO project. The answers it would hold are already in [blog-and-search-plan.md](blog-and-search-plan.md): the business, who searches, the areas, the writing rules. Connect OpenSEO and run the setup again to store them there; then connect Google Search Console once irondost.in is live.

### Published in the code (not yet live)

Five guides under `/blog` in `apps/web`, linked from the header ("Guides") and listed in the sitemap:

| URL | Answers |
| --- | --- |
| `/blog/how-doorstep-ironing-pickup-works` | What happens after I book? |
| `/blog/areas-we-serve-around-lb-nagar` | Do you pick up in my area? (12 localities, 7 PIN codes) |
| `/blog/silk-saree-dry-cleaning-what-to-tell-us` | How do I get a silk saree cleaned safely? |
| `/blog/ironing-for-pg-and-hostel-residents-dilsukhnagar` | Where can I get shirts ironed near my PG? |
| `/blog/will-laundry-bill-change-after-pickup` | Will the bill change after pickup? |

Each has an Article schema, FAQ schema where it has visible questions, a booking box with both store buttons and the phone number, and links to the other guides.

**Left out on purpose:** the rate-card page (`/prices`) and every price in the guides. The production catalogue still equals the placeholder seed in `apps/api/prisma/seed.ts`. **You** confirm that shirt ₹15, saree ₹50, suit ₹350 and the rest are the real prices; then add `/prices` and a price line to the PG guide.

**To make them live:** deploy the website (step 1 of section 1). They go live at the current `web.app` address too, but they only start to build search value on irondost.in.

## 4. Store links on the website (done in code)

- Google Play now opens `com.irondost.customer` ("IronDost: Laundry & Ironing"). It used to open the old "cloud ironing" listing.
- App Store button is live: `https://apps.apple.com/in/app/irondost-laundry-ironing/id6819166862` (version 2.0.0, India). It used to say "coming soon".
- Phone on the website changed to 79934 34932 (was 90632 90012).

Live once the website is deployed.

## 5. Instagram: bio, highlights, today

The only Instagram account connected to a posting tool here is `akvegadigital`, not IronDost, so nothing was scheduled or changed. To let me schedule: connect the IronDost Instagram (a Business or Creator account) in Zernio. Or schedule it yourself in Meta Business Suite with the details below.

### Bio

- **Name field** (searchable): `IronDost | Ironing & Laundry LB Nagar`
- **Bio** (under 150 characters):

  ```
  Ironing, laundry & dry cleaning pickup 🧺
  LB Nagar · Dilsukhnagar · Nagole · Vanasthalipuram
  7am–8pm daily · Call/WhatsApp 79934 34932
  ```

  Add "Shirt ironing from ₹15" in place of the area line once the price is confirmed.
- **Links** (Instagram allows five): `irondost.in` first once it is live; until then Google Play, App Store, and WhatsApp `https://wa.me/917993434932`.
- **Contact buttons:** Call and WhatsApp on 79934 34932; category "Laundromat" or "Dry cleaner".

### Highlights (in this order)

| Highlight | What goes in first | Cover |
| --- | --- | --- |
| Book | How to book: app screens, WhatsApp, the three windows (7–11, 11–4, 4–8) | Phone icon on brand blue |
| Our work | Real clips from the 19 and 20 Nov filming: counting, pressing, folding, packing; before and after | Folded shirt icon |
| Areas | `stories/poster-areas-story.jpg` plus a frame per PIN code | Map pin |
| Prices | `stories/poster-price-story.jpg` (after prices are confirmed) | ₹ sign |
| FAQ | Answers from the Wednesday question boxes; the 5 guides as link stickers once the site is live | Question mark |
| Reviews | Real customer messages, with permission. Leave empty until the first one | Star |

All covers on one background colour with a white icon, no text.

### Today, Thursday 19 November

| Time | What | Asset | Caption |
| --- | --- | --- | --- |
| 7:30 pm | Reel | `december-2026-pack/reels/reel-01-price.mp4` | The 19 Nov caption in [irondost-november-19-30-plan.md](irondost-november-19-30-plan.md) |
| After the reel | Stories | Share the reel; poll "Who irons at your home? Me / Someone else" | n/a |
| Daytime | Filming | The six real clips (handover, counting, pressing, folding, packing, app) | n/a |

The reel and its caption carry prices (shirt ₹15, trousers ₹15, saree ₹50). Post them only if those are the real prices; if not, post `reel-03-how` today instead and keep the price reel for after the check. The rest of the month (20 to 30 November) is already scheduled day by day in the 19–30 plan.
