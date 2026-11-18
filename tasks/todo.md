# IronDost on irondost.in: tasks

Plan: [plan.md](plan.md). Website checks for every web task: `pnpm --filter @laundry/web build`, `lint`, `typecheck`.

## Owner inputs (blocking)

- [ ] Answer the scroll-craft questions and pick draft A or B (`docs/marketing/website-redesign-drafts.md`)
- [ ] Confirm prices (shirt ₹15 offer / ₹20, saree ₹50, suit ₹350 …) or send the real list
- [ ] Fill the Google Business Profile missing-information list (`docs/marketing/seo/gmb-profile-pack.md`)
- [ ] Buy irondost.shop (or drop it)
- [ ] Add the DNS records at Hostinger (task 1 and 3), or share access
- [ ] Add a payment method in Zernio (or decide to post manually)
- [ ] Film the six real clips and before/after photos (list in task 7)

## Phase 1: Foundation

### Task 1: Admin on admin.irondost.in (S)
- [ ] Hostinger DNS for irondost.in: `CNAME admin → 79772770eb22b953.vercel-dns-017.com`
- [ ] Firebase console → Authentication → Settings → Authorized domains: add `admin.irondost.in` and `irondost-admin.vercel.app`
- [ ] Render `irondost-api` → Environment: `CORS_ORIGINS` gains `https://admin.irondost.in,https://irondost-admin.vercel.app` (see the risk in plan.md: this redeploys the API)
- [ ] Revoke the stray automation bypass in Vercel → irondost-admin → Settings → Deployment Protection
- **Verify:** `https://admin.irondost.in/login` loads over HTTPS; email + password sign-in reaches the dashboard and the orders list loads (no CORS error in the console)
- **Depends on:** none

### Task 2: Website on a Vercel preview (S)
- [ ] Commit the website changes (store links, guides, robots, llms)
- [ ] Create Vercel project `irondost-web` from `apps/web`, env `NEXT_PUBLIC_SITE_URL=https://irondost.in`
- [ ] Preview deploy
- **Verify:** preview shows both store buttons opening the IronDost listings; `/blog`, `/llms.txt`, `/robots.txt`, `/sitemap.xml` load
- **Depends on:** none

### Task 3: Domains attached with redirects (S)
- [ ] Vercel `irondost-web`: add irondost.in (primary), www.irondost.in, irondost.com, www.irondost.com, irondost.shop, www.irondost.shop → 301 to irondost.in
- [ ] Hostinger DNS for each: the A/CNAME values Vercel shows; remove the parking records
- **Verify:** `curl -sI` on each non-primary returns 301 to `https://irondost.in/...` with the path kept; HTTPS valid on all
- **Depends on:** 2; irondost.in stays on the current site or a holding page until task 10

### Checkpoint: Foundation
- [ ] Admin works on its domain; all domains resolve with HTTPS; owner reviewed

## Phase 2: Redesign

### Task 4: Choose the direction (XS)
- [ ] Owner picks A or B and answers the questions; write the final BRIEF.md
- **Depends on:** drafts delivered

### Task 5: Homepage hero and journey sections (M)
- [ ] Hero with layered depth, "at your door", pickup windows, from the chosen draft, into `apps/web/src/app/page.tsx` and components
- **Verify:** builds; desktop and 390 px screenshots at every scroll position; no text over busy image without a scrim
- **Depends on:** 4

### Task 6: "Our work" section and the signature move (M)
- [ ] Process sequence (count, press, fold, pack) and the signature interaction; works with touch, keyboard and reduced motion
- **Verify:** scroll-craft shoot script passes; tested by hand on a phone
- **Depends on:** 5

### Task 7: Real photos replace generated ones (S)
- [ ] Shoot: door handover (no faces or door numbers), counting, shirt pressing close-up, saree folding, packed order, app screens; 4 to 6 before/after pairs
- [ ] Grade, crop for desktop and portrait, replace every generated image in the "our work" and before/after sections
- **Verify:** no generated image remains where the page claims to show our work
- **Depends on:** 6

### Task 8: Services, areas with PIN check, booking section (M)
- [ ] PIN check from the 7 codes (client-side); app, WhatsApp (`wa.me/917993434932` with a prefilled message), call; QR on desktop
- **Verify:** each of the 7 PINs says yes; 500036 says no; all three booking links open the right place on a phone
- **Depends on:** 5

### Task 9: Quality pass (S)
- [ ] Lighthouse mobile ≥ 90 for performance, accessibility, SEO; real iPhone and Android check; reduced-motion check
- **Depends on:** 6, 7, 8

### Checkpoint: Redesign
- [ ] Owner approves the preview on their own phone

## Phase 3: Launch

### Task 10: irondost.in goes live (XS)
- [ ] Promote the redesign to production on Vercel
- **Verify:** irondost.in serves the new site; the five guides, policies and `/delete-account` are still at the same paths
- **Depends on:** 3, 9

### Task 11: Search Console and Bing (S)
- [ ] Verify irondost.in by DNS TXT; submit the sitemap; request indexing for the home page and the 5 guides; Bing Webmaster import
- **Depends on:** 10

### Task 12: Store listings and old site point to irondost.in (S)
- [ ] Play Console and App Store Connect: privacy, support and marketing URLs on irondost.in
- [ ] Firebase Hosting `irondost-app.web.app`: redirect every path to irondost.in
- **Verify:** both listings' links open irondost.in pages
- **Depends on:** 10

## Phase 4: Local and social

### Task 13: Google Business Profile (S)
- [ ] Create or claim with `docs/marketing/seo/gmb-profile-pack.md`; video verification; services, areas, photos, first post
- **Depends on:** owner's missing information, real photos

### Task 14: Organization schema with sameAs (XS)
- [ ] Homepage JSON-LD: Organization/LocalBusiness (service-area, no street address), `areaServed`, phone, `sameAs` GBP, Instagram, YouTube, Play, App Store
- **Depends on:** 13

### Task 15: Prices page and prices in guides (S)
- [ ] `/prices` from the confirmed list with a date; price line in the PG guide; llms.txt picks it up
- **Depends on:** prices confirmed

### Task 16: Photos in the guides (S)
- [ ] 2 to 3 real photos per guide with alt text that states what is shown
- **Depends on:** 7

### Task 17: Zernio: Instagram and YouTube (XS)
- [ ] After the payment method: connect IronDost Instagram (Business) and the YouTube channel; confirm both appear in the account list
- **Depends on:** owner payment method

### Task 18: Schedule 20 to 30 November posts (S)
- [ ] From `docs/marketing/irondost-november-19-30-plan.md`; reels also as YouTube Shorts; owner approves each caption before scheduling; price posts only after task 15's confirmation
- **Depends on:** 17

### Checkpoint: Complete
- [ ] irondost.in live with the redesign; admin on its domain; GBP verified; social connected and scheduled
