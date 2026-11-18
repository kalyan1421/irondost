# IronDost website redesign: two draft directions

Written 19 November 2026. These are **drafts for choosing a direction**, not the final site. Both briefs are self-authored (the owner has not been interviewed yet), every photo is an AI stand-in made with Codex, and no prices appear anywhere. Nothing here is deployed or touches `apps/web`.

| | Draft A: "Sunday, two ways" | Draft B: "The LB Nagar edition" |
| --- | --- | --- |
| Folder | `scrollcraft/builds/irondost-draft-a/` | `scrollcraft/builds/irondost-draft-b/` |
| Grammar | Split stage: two sides held all the way down, resolved at the end | Chaptered editorial: a printed local edition, hard cuts between chapters |
| Feel | Warm, calm, photographic, brand fonts (Outfit, Figtree) | Bold, newsy, playful, Fraunces serif headlines with Figtree |
| Navigation | The divider between the two sides is the menu: logo, "Your Sunday / With IronDost" with a progress bar, Book a pickup | A folio in the left margin showing the chapter number and title as you read; a strip on phones |
| Hero | 50/50: a chair piled with clothes ("Sunday, 6 pm. Still ironing.") next to a pressed stack ("Sunday, 6 pm. Already done.") | A front page in type only: masthead, strap line, headline, an index of chapters |
| Signature move | **Drag-to-press:** the visitor irons a creased shirt with mouse or finger; "Iron it for me" button for keyboard users | **PIN stamp:** type a PIN or tap a locality and an inked "WE COME HERE" stamp lands on a map of the 12 localities; outside PINs get "NOT YET" |
| Peak moment | "There's a shirt you iron yourself with your finger, and the creases go." | "You type your PIN code and a stamp thumps down on your area." |
| Ending | The divider slides to the left edge, "With IronDost" takes the full width, booking lives there | A colophon: booking written as a sentence with links, small store buttons |
| Brief | `irondost-draft-a/BRIEF.md` | `irondost-draft-b/BRIEF.md` |

## Draft A, section by section

| # | Section | Feeling | What it does |
| --- | --- | --- | --- |
| 1 | Two Sundays (hero) | Recognised | Pile against pressed stack, both headlines readable at once |
| 2 | The Sunday you know / could have | Tired, then relieved | Two clocks fill in as you scroll (4:00 find the iron… against 4:00 pick a window, 4:01 go out); the divider leans toward IronDost |
| 3 | Press this one yourself (peak) | Delight | The drag-to-press shirt |
| 4 | Tell us four things / On our table | Reassured | Stains, zari, colour, photo on the left; counted, pressed, folded, packed, delivered photos on the right |
| 5 | Not yet / We come to these PIN codes | Practical | Malakpet, Uppal, Balapur on the left; the 7 PIN codes and the 3 pickup windows on the right |
| 6 | Hand it over (close) | Sure | Divider collapses; Google Play, App Store, WhatsApp, both phone numbers |

## Draft B, chapter by chapter

| # | Chapter | Feeling | What it does |
| --- | --- | --- | --- |
| · | Front page | Curious | Masthead "IronDost, the LB Nagar edition", headline, chapter index |
| I | The pile | Amused recognition | Dark spread: photo column with gentle parallax, drop-cap story, pull quote |
| II | Three windows, every day | Organised | A departures board: 7 to 11, 11 to 4, 4 to 8, and three short rules (full means full, counted at your door, back usually next day) |
| III | On our table | Reassured | Five photographed steps with long captions in an uneven grid |
| IV | Your area (peak) | Delight | The PIN stamp map, locality chips, a tally (7 PIN codes, 12 localities, 6 km) |
| V | Before you hand over a silk saree | Cared for | Four numbered care points on a maroon spread |
| ¶ | How to book | Settled | Booking set as a sentence; store buttons |

## Images (Codex)

Made with the Codex CLI's built-in image generator (`codex exec`, no API key, no paid service), one fixed style line for all of them: photorealistic, natural daylight, modest Hyderabad apartment, hands only (no faces), no text. Every image was looked at before use. Masters are in `scrollcraft/builds/irondost-gen/` (PNG); each build has WebP copies in `assets/`. The generator script is `irondost-gen/gen.sh`.

| Image | Used for |
| --- | --- |
| `pile-chair` | A hero left, B chapter I |
| `pressed-stack` | A hero right |
| `shirt-pressed-flat`, `shirt-creased-flat` | A drag-to-press (the creased one is a Codex edit of the pressed one, so they line up) |
| `counting-table`, `pressing-closeup`, `saree-fold`, `packed-order`, `doorstep-handover` | "Our work" in both |

Two snags, both fixed: Codex jobs hang when stdin is left open (closed with `< /dev/null`), and when several run at once some copied each other's picture, so two files were re-matched by hand. Run them one at a time, or copy from each job's own folder.

**Later:** replace every stand-in with real photos from the filming list (handover, counting, pressing, folding, packing, app). Same file names, same crops; the pages need no other change.

## Checked

- Screenshot sheets at every scroll position, desktop and 390 px phone, plus reduced motion, using the skill's harness: no dead scroll, and in A every line of text over a photo clears 4.5:1 contrast.
  - A: `irondost-draft-a/lab/shots/sheet.png`, `lab/mobile/sheet.png`, `lab/reduced/sheet.png`
  - B: `irondost-draft-b/lab/shots/sheet.png`, `lab/mobile/sheet.png`, `lab/reduced/sheet.png`
- The signature moves were driven in a headless browser on desktop and phone:
  - A: "Iron it for me" presses the whole shirt and shows "Pressed. We do the rest." (`lab/press-before-*.png`, `lab/press-after-*.png`)
  - B: 500060 stamps Chaitanyapuri and Dilsukhnagar; 500039 says "Not yet: Uppal" (`lab/stamp-*.png`)
- No page errors in the console. No sideways scrolling at 390 px (B had some; fixed).

**Not checked:** a real phone (iPhone Safari and Android Chrome touch dragging on the shirt), real-photo versions, accessibility with a screen reader, and load speed on mobile data. The B map is schematic (approximate positions), not surveyed.

## Preview locally

```bash
node ~/.claude/skills/scroll-craft/scripts/serve.mjs --root scrollcraft/builds/irondost-draft-a --port 4501
```

```bash
node ~/.claude/skills/scroll-craft/scripts/serve.mjs --root scrollcraft/builds/irondost-draft-b --port 4502
```

Then open http://localhost:4501 and http://localhost:4502.

## Questions for you (the scroll-craft interview)

Answer in your own words; short answers are fine. Your answers replace the guesses in the two BRIEF.md files, and then one direction (or a mix of ideas, on one grammar) gets built for real.

**About the feel**

1. Describe the feeling of the site in three to five words. Name up to three things it should remind people of: a film, a shop, a magazine, an advert, anything (not other websites).
2. In your own order, what should a visitor see first, next, and last on the page?
3. Where should the page feel calm, and where should it feel exciting?
4. How should someone feel at each stage while scrolling, and what is the ONE moment you want them to remember and tell a friend about?
5. One thing this site should do that you have never seen another site do. (Draft A's guess: press a shirt yourself. Draft B's guess: stamp your PIN on a map.)
6. How far from "clean and premium" do you want to go? Options: premium-minimal, editorial (like B), playful, bold, retro, packed with detail.
7. One continuous journey, or separate scenes or chapters? (A is two sides side by side; B is chapters.)
8. What real material do you have or can you shoot? Photos of your work, short videos, staff (with permission), your shop or workroom, customer messages you may show.

**About the business**

9. In one or two sentences: what is IronDost, and who is it for?
10. What must a visitor believe by the end of the page? One sentence.
11. What is the ONE thing they should do next? Pick one label for it everywhere (for example "Book a pickup", "Download the app" or "WhatsApp us").
12. Which brand material should be used as is, and what may change? (Logo, blue and yellow colours, the Outfit font, app screens.)
13. Photos: keep the AI stand-ins until real ones exist, or wait for real ones before launching the redesign?

**To decide**

14. Draft A, draft B, or ideas from both on one structure?
15. Can prices go on the site yet? (They are left out until you confirm the live price list.)
16. Book on the website itself later (needs sign-in and payment on the web), or keep booking through the app, WhatsApp and phone?
