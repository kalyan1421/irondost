# IronDost 3-Day Reel Series: "Pickup extra ah?"

Three reels, one a day. Reference: the pophub3d "golden card" reel (someone gets looked down on, shows one thing, and everyone's attitude flips).

| Day | Reel | Job | Length |
|---|---|---|---|
| 1 | **Pickup extra ah?** | Intro. The trend format: a laundry shop owner mocks Ravi, Ravi opens IronDost, Dost arrives like a hero. | 4 × 8 s + 3 s end card ≈ 35 s |
| 2 | **Ninna em jarigindi?** | Explains everything from Day 1, step by step: book → pickup → wash and iron → hand check → next-day drop → pay. | 5 × 8 s + 3 s ≈ 43 s |
| 3 | **Attitude change** | Payoff: the same shop owner secretly books IronDost. Ends on prices, areas and how to book. | 3 × 8 s + 4 s ≈ 28 s |

Look: **photoreal live action**, the same cast and royal-blue brand look as *Dost Undi Ga!* (`videos/dost-undi-ga/refs/`). A real-looking cast is what makes Veo's voices sound like real people. The reference reel is 3D; if you want that look, see "3D option" at the end.

---

## 0. Before you start (read once)

### Check these facts first (they go on screen)
- **"Free pickup & drop."** The app has an admin setting, *free delivery above ₹X* (`freeDeliveryAbovePaise`), plus a *minimum order*. If travel is not free on every order, change the Day 1 line and caption to "₹X పైన ఫ్రీ పికప్".
- **Prices** (Day 3) are from the rate card dated 19 Nov 2026: Wash & Iron shirt ₹35, trousers ₹40; Ironing shirt ₹15 (offer, regular ₹20), saree ₹50. Re-check in the admin on posting day.
- **Pickup slots:** 7–11 am, 11 am–4 pm, 4–8 pm, every day. **Area:** within 6 km of LB Nagar Circle. **Payment:** UPI, card, netbanking or cash at delivery. **Return:** usually next day.

### Tools (all in your Google AI Ultra plan)
| Step | Tool | Setting |
|---|---|---|
| New reference images | **Gemini app → Nano Banana Pro** (or Flow → Images) | Upload the refs listed, paste the prompt |
| Every video clip | **Google Flow → Veo 3.1 (Quality)** | *Ingredients to Video*, 9:16, 2 outputs, audio on |
| If a clip's first frame comes out wrong | Flow → *Frames to Video* | Make the clip's FIRST FRAME as an image with Nano Banana, then use it as the start frame |
| Narration fallback (Day 2 only) | **Google AI Studio → Generate speech** (Gemini TTS) | Single speaker, prompts in section 5 |
| Final assembly | Instagram editor or CapCut | Put the clips in order, add text, logo, trending audio |

### What the prompts already edit for you
Each prompt includes the **cuts, speed ramps, whip pans, slow motion, impact sound effects and dialogue timing**. Each clip's last frame is set up to match the next clip's first frame, so you only have to line them up. Only three things go on top afterwards, for good reasons:
1. **Telugu on-screen text.** Every video model misspells Telugu script, so it's typed in the editor (text and timings are given).
2. **The IronDost logo** on the polo, bag and end card. AI logos come out warped.
3. **Trending music.** Instagram only boosts a reel when the trending audio is attached inside Instagram. Clips are generated without music so the dialogue stays clean underneath it.

### Voice: how to get real-sounding Telugu (best first)
1. **Veo 3.1's own voices (start here).** Veo records the dialogue with the picture, lip-synced, with room sound. Done right it sounds like actors on set, not text-to-speech. Each prompt pins down every character's voice (age, pitch, accent, pace) so it stays the same across clips. Keep a take only if the Telugu words are right and the accent sounds Hyderabadi. Regenerate up to 3 times.
2. **A real person's voice (the only truly non-AI option).** For any line Veo gets wrong, record it yourself or a friend on a phone: a quiet room with curtains or a wardrobe, 20–30 cm from the mouth, Voice Memos. Clean it with CapCut *Enhance voice* or Adobe Podcast *Enhance Speech*. Replace the clip's audio. Lip-sync is close enough on short lines. Day 2's narration lines are mostly off-camera, so they need no lip-sync at all.
3. **Gemini TTS (fallback for narration only).** Section 5 has the exact director prompts. It is still AI. Add light room tone and keep it under the music.

Never use a robotic "reels voice" from CapCut text-to-speech; locals spot it at once.

---

## 1. New reference images (Nano Banana Pro)

You already have `ravi-ref.png`, `dost-ref.png`, `set-flat.png` and `set-unit.png`. Make these three new ones once and save them in `videos/dost-undi-ga/refs/`.

### owner-ref.png: the laundry shop owner (Day 1 and Day 3)
Upload `dost-ref.png` as a style reference, then:
```text
Photoreal character reference sheet in exactly the same style, lighting, grey studio background and four-view layout as the attached image (front, three-quarter, side profile, full body). New character: PRASAD, a Hyderabad laundry shop owner, Telugu man, 46, medium-brown skin, slightly heavy build with a small belly, receding black hair combed back with a little grey at the temples, thick black moustache, reading glasses pushed down his nose, a thin gold chain, a shiny cream-coloured half-sleeve shirt with a subtle sheen tucked into dark brown trousers, a gold wristwatch. Expression: smug, one eyebrow raised, slight smirk. Real skin texture, natural pores, five fingers on each hand. No text, no logos, no watermark.
```

### set-shop.png: Prasad's laundry shop on an LB Nagar road (Day 1 and Day 3)
```text
Photoreal wide establishing photo, vertical 9:16, daytime. A small, over-decorated dry-cleaning shop on a busy main road in LB Nagar, Hyderabad. Inside: a glass-top counter with a bell, plastic-wrapped clothes hanging on a steel rail behind it, a small Ganesha photo frame with a garland, tube lights, a calendar on the wall, a steel stool. The open shutter looks out on the road: the grey concrete pillars and elevated track of the Hyderabad Metro, autorickshaws, two-wheelers, a fruit cart. Warm afternoon sun, slight haze. Realistic, lived-in, slightly dusty. All signboards blank or blurred, no readable text anywhere, no logos, no people.
```

### ravi-outfit-ref.png: Ravi's outfits for this series
Upload `ravi-ref.png`, then:
```text
Same man as the attached image, same face, hair and stubble, photoreal, same grey studio background and layout. Show him in two outfits side by side. Left: a badly wrinkled, faded sky-blue cotton full-sleeve shirt, untucked, sleeves pushed up, blue jeans, brown chappals. Right: the same man in a crisp, perfectly ironed plain white cotton shirt, tucked into dark navy trousers, standing confidently with a small smile. No text, no logos.
```

---

## 2. Shared blocks

### Voices (already inside each prompt; listed here so you can check takes)
- **RAVI:** Telugu man, 28. Medium pitch, soft and friendly, natural Hyderabad Telugu accent, relaxed pace, slight smile in the voice.
- **DOST (Srinu):** Telugu man, 30. Calm, warm, low baritone, Telangana Telugu accent, unhurried and confident, says "anna" and "sir" softly.
- **PRASAD (shop owner):** Telugu man, 46. Slightly raspy, nasal, sarcastic sing-song Hyderabadi Telugu with a Dakhni lilt, drags out vowels when mocking.

### Shared negative block
Flow has no negative box, so paste this at the very end of every prompt, after the clip's own AVOID line. If you use Veo through AI Studio or the API, put it in the `negativePrompt` field instead.
```text
AVOID ALSO: background music, music score, singing, humming, laugh track; a line said twice, extra or changed words, English or Hindi instead of Telugu, robotic, echoey or text-to-speech sounding voices, the wrong person's lips moving, lips moving with no sound, the listener mouthing words; any text, subtitles, captions, letters, numbers, logos, watermarks, brand names or readable signboards in the picture; readable phone screens or app UI; printing on the royal-blue polo or bags; faces changing between shots, a different actor, twins of one person, extra or missing fingers, fused hands, extra limbs, warped teeth, crossed eyes, waxy or plastic skin, frozen smiles; extra people looking at the camera; outfits or prop colours changing; objects appearing from nowhere; morphing, melting or warping objects; flicker, jitter, frozen frames; cartoon, anime or 3D-render look; neon or oversaturated colours, blue colour cast; blurry faces, low resolution; other brands' logos; alcohol, cigarettes, injuries.
```

---

## 3. DAY 1: "Pickup extra ah?" (intro)

**Hook text (0.2–2 s, big, top third):** "పికప్ కి ఎక్స్‌ట్రా అంట 😏"
**Trending audio:** a Telugu mass/attitude BGM; put its beat drop on **16.0 s** (start of Clip 3).
**Caption:**
> పికప్ కి ఎక్స్‌ట్రా అన్నారు 😏 మేము అన్నాం… ఫ్రీ అని 😎
> IronDost: LB Nagar, Dilsukhnagar, Nagole, Saroornagar, Vanasthalipuram లో ఫ్రీ పికప్ & డ్రాప్ 🚚 Wash, iron, hand-checked ✅
> రేపు full process చూపిస్తాం 👀 Follow అవ్వండి!
> ఏ సీన్ బాగా నచ్చింది? 👇
> #IronDost #LBNagar #Dilsukhnagar #Hyderabad #HyderabadLaundry #TeluguReels #LaundryService #FreePickup

### D1-C1 · 0–8 s · The insult
**Ingredients:** ravi-ref.png · owner-ref.png · set-shop.png
**Edit text:** 0.2 s hook text (above)
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, warm afternoon sunlight, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. Location: a small over-decorated dry-cleaning shop on a busy LB Nagar main road in Hyderabad, glass-top counter with a bell, plastic-wrapped clothes on a rail behind, the grey pillars of the elevated Hyderabad Metro visible through the open shutter, autos and bikes passing.

Cast, matching the reference images exactly:
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim, friendly eyes, wearing a badly wrinkled faded sky-blue cotton shirt, untucked, and blue jeans.
PRASAD: shop owner, Telugu man, 46, heavy build, receding combed-back hair, thick moustache, reading glasses low on his nose, thin gold chain, shiny cream half-sleeve shirt.

Timeline (edited inside the clip):
0.0–2.5 s: Low tracking shot from the road following RAVI from behind as he walks into the shop hugging a huge knotted bedsheet bundle stuffed with crumpled clothes, a sock dangling out. Traffic sound, a horn.
2.5–3.5 s: Hard cut to a side angle at counter height. RAVI drops the bundle on the glass counter with a heavy thud; the counter bell jingles.
3.5–8.0 s: Cut to a low-angle medium close-up of PRASAD behind the counter. He looks at the bundle over his glasses, slowly raises one eyebrow, leans back and folds his arms with a smug smirk while he speaks. Slow push-in on his face.

Dialogue, said exactly once, word for word:
At 4.0 s PRASAD, lip-synced, slightly raspy, sarcastic sing-song Hyderabadi Telugu, dragging out the first word: "ఇన్ని బట్టలా? పికప్, డెలివరీ కావాలంటే ఎక్స్‌ట్రా చార్జ్ సార్." (Inni battala? Pickup, delivery kavalante extra charge sir.)
Silence after the line except room sound.

Sound: street traffic and a distant horn, footsteps, a heavy cloth thud with the bell jingling at 2.8 s, a ceiling fan hum inside the shop. No music.

First frame: RAVI from behind on the road, the bundle in his arms, the shop's open shutter ahead, metro pillars to the side.
Last frame: tight low-angle close-up of PRASAD smirking with folded arms, eyebrow raised.

AVOID: PRASAD shouting or angry (he is amused and smug), customers in the shop, readable shop signboard, clothes falling out of the bundle in big amounts, RAVI speaking in this clip.
```
*Then paste the shared negative block.*

### D1-C2 · 8–16 s · The calm before
**Ingredients:** ravi-ref.png · owner-ref.png · set-shop.png
**Edit text:** 5.5 s "ఒక్క యాప్ ఓపెన్ చేశాడు…" (centre, small)
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, warm afternoon sunlight, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. Same small dry-cleaning shop on an LB Nagar road, glass counter, the knotted bedsheet bundle of crumpled clothes lying on it.

Cast, matching the reference images exactly:
RAVI: Telugu man, 28, slim, short black hair, light stubble, wrinkled faded sky-blue shirt.
PRASAD: shop owner, 46, heavy build, thick moustache, reading glasses low on his nose, gold chain, shiny cream shirt.

Timeline (edited inside the clip):
0.0–2.5 s: Over-the-shoulder shot from behind PRASAD toward RAVI. PRASAD flicks the bundle's knot with two fingers, unimpressed, and speaks.
2.5–5.0 s: Cut to a medium close-up of RAVI. He looks down for a beat, takes a slow calm breath, then a small confident smile appears and he speaks quietly.
5.0–8.0 s: Speed ramp into slow motion. RAVI slowly pulls a smartphone out of his jeans pocket and raises it. The back of the phone faces the camera; a soft royal-blue glow from the screen lights his face from below. Dust in the sunbeam floats in slow motion. A deep low bass rumble rises.

Dialogue, each line exactly once, word for word:
At 0.5 s PRASAD, lip-synced, raspy sarcastic Hyderabadi Telugu: "మా దగ్గర ఫ్రీగా ఏమీ రాదు సార్." (Maa daggara free ga emi raadu sir.)
At 3.2 s RAVI, lip-synced, soft friendly medium-pitch voice, calm and quiet, natural Hyderabad Telugu: "సరే… నేను చూసుకుంటా." (Sare… nenu choosukunta.)
Nothing is said after RAVI's line.

Sound: fan hum, faint street noise, a soft bass rumble building from 5 s and peaking at 8 s. No music.

First frame: over-the-shoulder from behind PRASAD, RAVI facing him across the counter.
Last frame: slow-motion close-up of RAVI's calm face lit royal blue from below, phone back to camera.

AVOID: a visible phone screen, any app interface, RAVI looking angry, PRASAD's lips moving during RAVI's line, real-speed motion after 5 s.
```
*Then paste the shared negative block.*

### D1-C3 · 16–24 s · Hero entry (beat drop)
**Ingredients:** dost-ref.png · ravi-ref.png · set-shop.png
**Edit text:** 0.0 s white flash (2 frames) · 0.3 s "FREE PICKUP 🚚" (big, punch-in) · logo patch on DOST's polo, tracked
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, golden afternoon backlight, anamorphic feel, shallow depth of field, natural lip-synced Telugu speech. The LB Nagar main road outside the small dry-cleaning shop, metro pillars behind, autos passing.

Cast, matching the reference images exactly:
DOST (Srinu, IronDost pickup person): Telugu man, 30, medium-dark skin, neat moustache, clean-shaven, short side-parted black hair, calm kind smile, fit build, plain royal-blue polo with a completely blank chest, dark grey trousers, black sling bag, carrying folded plain royal-blue zip garment bags.
RAVI: Telugu man, 28, slim, wrinkled faded sky-blue shirt.

Timeline (edited inside the clip):
0.0–3.0 s: Beat-drop hero entry in slow motion. Ground-level low-angle shot: a black electric scooter glides to a stop at the shop's shutter, a gust of wind lifts dust and a few dry leaves, sunlight flares behind. DOST swings off the scooter and pulls off his helmet, hair settling, calm half-smile. A deep bass impact boom at 0.0 s and a whoosh.
3.0–4.0 s: Fast whip pan into the shop.
4.0–8.0 s: Back to real speed. Medium shot at the counter: DOST lifts the heavy bedsheet bundle off the counter with one easy swing onto his shoulder, nods at RAVI and speaks, then turns toward the shutter. RAVI grins.

Dialogue, exactly once, word for word:
At 4.8 s DOST, lip-synced, calm warm low baritone, unhurried Telangana Telugu: "పికప్ ఫ్రీ అన్నా. రేపు ఇంటికే తెస్తా." (Pickup free anna. Repu intike testa.)
Nothing is said after this line.

Sound: bass impact boom and whoosh at 0.0 s, scooter hum stopping, wind gust, helmet click, a whip-pan swoosh at 3.0 s, a cloth thump as he shoulders the bundle. No music.

First frame: ground-level shot of the scooter's front wheel rolling into frame, dust rising, the shop's shutter behind.
Last frame: DOST turning toward the open shutter with the bundle on his shoulder, RAVI grinning behind him.

AVOID: sunglasses, a logo or any print on the polo, helmet or scooter, the scooter crashing, DOST running, more than one DOST, PRASAD speaking in this clip.
```
*Then paste the shared negative block.*

### D1-C4 · 24–32 s · Next day, attitude flips
**Ingredients:** ravi-outfit-ref.png · dost-ref.png · owner-ref.png
**Edit text:** 0.0 s "మరుసటి రోజు…" (small, top) · 6.5 s freeze-frame feel, end card follows
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, soft morning sunlight, 35mm lens, shallow depth of field, natural lip-synced Telugu speech.

Cast, matching the reference images exactly:
RAVI: Telugu man, 28, slim, short black hair, light stubble, now in a crisp perfectly ironed plain white shirt.
DOST: Telugu man, 30, neat moustache, plain royal-blue polo with a blank chest, dark grey trousers, black sling bag.
PRASAD: shop owner, 46, heavy build, thick moustache, reading glasses, gold chain, shiny cream shirt.

Timeline (edited inside the clip):
0.0–3.0 s: Morning, the doorway of a Hyderabad apartment with a rangoli on the floor and potted plants. DOST hands RAVI a plain royal-blue zip garment bag; RAVI unzips it a little to reveal crisp, perfectly pressed shirts on hangers, and grins.
3.0–5.5 s: Cut to across the lane: PRASAD, holding a steel tea glass, has stopped mid-sip, peering over his glasses at them. His jaw slowly drops; his glasses slide down his nose. He speaks under his breath.
5.5–8.0 s: Cut to a medium two-shot of RAVI and DOST at the door. RAVI, adjusting his crisp white collar, glances toward PRASAD and answers with a relaxed smile, then puts an arm around DOST's shoulder; both look at the camera. Slow push-in, hold.

Dialogue, each line exactly once, word for word:
At 3.8 s PRASAD, lip-synced, raspy Hyderabadi Telugu, stunned whisper: "వాడు… ఎవరు?" (Vaadu… evaru?)
At 6.0 s RAVI, lip-synced, soft friendly medium-pitch voice, proud and relaxed, natural Hyderabad Telugu: "మన దోస్త్." (Mana Dost.)
Nothing is said after RAVI's line; the last second is room sound only.

Sound: morning birds, a pressure-cooker whistle far away, a zip sound at 1.5 s, a soft slurp then silence for PRASAD. No music.

First frame: the apartment doorway with rangoli, DOST holding out a royal-blue garment bag to RAVI.
Last frame: RAVI and DOST side by side at the door looking at the camera, RAVI's arm on DOST's shoulder, clean space above their heads for text.

AVOID: wrinkled clothes in the garment bag, PRASAD in the same frame as RAVI and DOST, tea spilling, anyone else speaking.
```
*Then paste the shared negative block.*

### D1 end card (3 s, made in the editor)
Royal-blue background · IronDost logo · "ఎల్‌బీ నగర్‌లో ఫ్రీ పికప్ & డ్రాప్" · "IronDost app · Google Play | App Store" · "రేపు: Full process 👀"

---

## 4. DAY 2: "Ninna em jarigindi?" (explains Day 1)

DOST walks the viewer through what happened to Ravi's clothes. Lines are short so Veo can say them cleanly in 8 seconds.

**Hook text (0.2–2 s):** "నిన్న రవి బట్టలకి ఏం జరిగింది? 👇"
**Trending audio:** a soft, upbeat Telugu instrumental at low volume (the voice is the hero today).
**Caption:**
> నిన్న రీల్ లో Dost ఏం చేశాడు? Full process ఇదే 👇
> 1️⃣ App లో బుక్ 2️⃣ ఇంటికే పికప్ 3️⃣ మా సొంత మెషిన్లలో వాష్ & ఐరన్ 4️⃣ ఓనర్ హ్యాండ్ చెక్ 5️⃣ సాధారణంగా మరుసటి రోజే డెలివరీ
> Pickup slots: 7–11 | 11–4 | 4–8 · UPI / Card / Cash
> Save చేసుకోండి, ఫ్రెండ్ కి పంపండి 📲
> #IronDost #HowItWorks #LBNagar #Hyderabad #LaundryService #TeluguReels

### D2-C1 · 0–8 s · Callback
**Ingredients:** dost-ref.png · ravi-outfit-ref.png · set-flat.png
**Edit text:** 0.2 s hook · 5 s "Step by step 👇"
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, soft morning light, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. The doorway and front room of a small lived-in Hyderabad flat: mosaic floor, pale green walls, iron-grill window.

Cast, matching the reference images exactly:
DOST: Telugu man, 30, medium-dark skin, neat moustache, short side-parted black hair, calm kind smile, plain royal-blue polo with a blank chest, dark grey trousers, black sling bag.
RAVI: Telugu man, 28, slim, crisp ironed plain white shirt.

Timeline (edited inside the clip):
0.0–1.0 s: Quick rewind-style whoosh: a fast blurred push-in toward the doorway.
1.0–8.0 s: DOST stands in the doorway holding a plain royal-blue garment bag, turns from RAVI (who walks out of frame behind him smiling) and talks straight to the camera, friendly, like explaining to a neighbour, with one open-hand gesture.

Dialogue, exactly once, word for word:
At 1.5 s DOST, lip-synced, calm warm low baritone, unhurried Telangana Telugu, looking into the lens: "నిన్న చూశారు కదా… ఇప్పుడు అసలు ఎలా పని చేస్తుందో చెప్తా." (Ninna choosaaru kada… ippudu asalu ela pani chestundo cheptha.)
Nothing is said after this line.

Sound: a rewind whoosh at 0.0 s, soft room tone, distant traffic. No music.

First frame: blurred fast push-in toward the flat's doorway.
Last frame: DOST mid-gesture, looking into the lens, medium shot, the doorway behind him.

AVOID: RAVI speaking, DOST holding a phone, a printed logo on the bag or polo.
```
*Then paste the shared negative block.*

### D2-C2 · 8–16 s · Book in the app
**Ingredients:** ravi-ref.png · set-flat.png
**Edit text:** 1 s "1️⃣ App లో బుక్" · 4 s three chips pop in one by one: "7–11 AM" "11–4 PM" "4–8 PM" · 6.5 s "ధర ముందే కనిపిస్తుంది ✅"
**Optional:** cover the phone with a real 2-second screen recording of the booking flow (`docs/marketing/december-2026-pack/screens/` has the schedule and basket screens).
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, warm evening lamp light, 35mm lens, shallow depth of field. The same small Hyderabad flat, a sofa, a pile of crumpled clothes on a plastic chair beside it.

Cast, matching the reference image exactly:
RAVI: Telugu man, 28, slim, short black hair, light stubble, plain grey cotton vest, relaxed on the sofa.

Timeline (edited inside the clip):
0.0–3.0 s: Medium shot: RAVI on the sofa scrolls his phone, the back of the phone toward the camera, royal-blue glow on his face. He glances at the pile of clothes on the chair.
3.0–5.5 s: Cut to a macro close-up of his thumb tapping three times on the phone (the phone's edge only, the screen not visible), each tap with a soft click.
5.5–8.0 s: Cut back to medium: RAVI tosses the phone onto the sofa cushion, leans back with his hands behind his head and smiles, relieved.

Dialogue (voice-over, nobody on screen moves their lips), exactly once, word for word:
From 0.5 s, DOST's voice off-screen, calm warm low baritone, unhurried Telangana Telugu, friendly explaining tone: "IronDost యాప్ లో బట్టలు ఎంచుకోండి… పొద్దున, మధ్యాహ్నం, సాయంత్రం… మీకు నచ్చిన టైమ్." (IronDost app lo battalu enchukondi… podduna, madhyaahnam, saayantram… meeku nachina time.)

Sound: three soft taps at 3.2, 3.9 and 4.6 s, a cushion thump at 6 s, a ceiling fan hum. No music.

First frame: RAVI on the sofa in his grey vest, phone back to camera, blue glow on his face.
Last frame: RAVI leaning back relaxed with hands behind his head.

AVOID: a visible phone screen or any interface, RAVI's lips moving, DOST on screen.
```
*Then paste the shared negative block.*

### D2-C3 · 16–24 s · Doorstep pickup, counted in front of you
**Ingredients:** dost-ref.png · ravi-ref.png · set-flat.png
**Edit text:** 0.5 s "2️⃣ ఇంటికే పికప్" · 4 s counter ticking "1… 2… 3… 12 pieces" next to the bag
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, soft morning light from the door, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. The front door of the small Hyderabad flat, a rangoli on the floor outside.

Cast, matching the reference images exactly:
DOST: Telugu man, 30, neat moustache, plain royal-blue polo with a blank chest, dark grey trousers, black sling bag.
RAVI: Telugu man, 28, slim, plain grey cotton vest.

Timeline (edited inside the clip):
0.0–2.0 s: A doorbell rings; RAVI opens the door; DOST stands there smiling with an empty plain royal-blue zip bag.
2.0–6.0 s: Cut to a close-up of DOST's hands: he counts RAVI's crumpled shirts one at a time, folding each once and placing it into the royal-blue bag, lips moving as he speaks to RAVI.
6.0–8.0 s: Cut to medium: DOST zips the bag shut and gives RAVI a thumbs-up; RAVI nods.

Dialogue, exactly once, word for word:
At 2.5 s DOST, lip-synced, calm warm low baritone, Telangana Telugu, looking up at the camera once mid-line: "మీ ముందే లెక్కపెట్టి తీసుకెళ్తాం. పికప్ కి ఎక్స్‌ట్రా ఏమీ లేదు." (Mee munde lekkapetti teesukeltaam. Pickup ki extra emi ledu.)
Nothing is said after this line.

Sound: doorbell at 0.2 s, door latch, soft cloth rustles with each shirt, a zip at 6.5 s. No music.

First frame: the closed flat door, rangoli outside, the doorbell ringing.
Last frame: DOST with the zipped royal-blue bag giving a thumbs-up, RAVI nodding in the doorway.

AVOID: more than 12 shirts, shirts changing colour while counted, RAVI speaking, printed text on the bag.
```
*Then paste the shared negative block. If pickup is not free on every order, change the second sentence to "యాప్ లో చూపించిన ధరే." (Yaap lo choopinchina dhare.: "the price shown in the app").*

### D2-C4 · 24–32 s · Own machines + hand check
**Ingredients:** set-unit.png · dost-ref.png
**Edit text:** 0.3 s "3️⃣ మా సొంత మెషిన్లు" · 4.5 s "4️⃣ ఓనర్ హ్యాండ్ చెక్ ✅"
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, bright clean white LED light, macro and 50mm lenses, shallow depth of field. The IronDost laundry unit in LB Nagar: stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, tiled floor.

Timeline (edited inside the clip, satisfying fast cuts):
0.0–1.5 s: Macro: clothes tumbling behind the round glass door of a washer, soap foam swirling.
1.5–3.0 s: Cut: a steam iron glides across a white shirt collar on the press table, a burst of steam, wrinkles vanishing.
3.0–4.5 s: Cut: hands fold the white shirt into a perfect crisp square, a soft fabric snap.
4.5–8.0 s: Cut: close-up of an older man's hands (only hands and the cuff of a plain white shirt visible) holding a pressed shirt up to the light, checking the collar and every button, then giving a small approving pat and laying it on a neat stack.

Dialogue (voice-over, nobody's lips visible), exactly once, word for word:
From 0.5 s, DOST's voice off-screen, calm warm low baritone, Telangana Telugu, proud tone: "మా సొంత మెషిన్లలో వాష్, ఐరన్… ప్రతి లోడ్ ఓనర్ గారే చేత్తో చెక్ చేస్తారు." (Maa sonta mishanlalo wash, iron… prathi load owner gaare chetto check chestaaru.)

Sound: washer drum hum, a steam hiss at 1.6 s, fabric snap at 3.5 s, a soft pat at 7 s. No music.

First frame: macro of clothes tumbling behind a washer's glass door.
Last frame: a neat stack of crisp folded white shirts with a hand resting on top.

AVOID: faces in this clip, dirty or wet floors, damaged or burnt clothes, brand names on the machines, any readable labels.
```
*Then paste the shared negative block.*

### D2-C5 · 32–40 s · Next-day drop + pay your way
**Ingredients:** dost-ref.png · ravi-outfit-ref.png · set-flat.png
**Edit text:** 0.3 s "5️⃣ సాధారణంగా మరుసటి రోజే" · 4 s "UPI • Card • Cash 💸" · end card follows
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, soft morning sunlight, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. The front door of the small Hyderabad flat with a rangoli outside.

Cast, matching the reference images exactly:
DOST: Telugu man, 30, neat moustache, plain royal-blue polo with a blank chest, dark grey trousers, black sling bag, holding a plain royal-blue zip garment bag.
RAVI: Telugu man, 28, slim, crisp ironed plain white shirt.

Timeline (edited inside the clip):
0.0–3.0 s: DOST hands RAVI the garment bag at the door; RAVI unzips it partway to show crisp pressed shirts on hangers and smiles.
3.0–5.0 s: Cut to a close-up: RAVI holds his phone out to pay (the phone's back toward camera) and a soft success chime plays.
5.0–8.0 s: Cut to medium: DOST turns to the camera with a warm smile and says his line, then gives a small wave as RAVI closes the door behind him.

Dialogue, exactly once, word for word:
At 5.3 s DOST, lip-synced, calm warm low baritone, Telangana Telugu, looking into the lens: "రేపే మీ ఇంటికి. UPI అయినా, క్యాష్ అయినా… మీ ఇష్టం." (Repe mee intiki. UPI ayina, cash ayina… mee ishtam.)
Nothing is said after this line.

Sound: zip at 1.5 s, a soft payment chime at 3.5 s, birds outside, door closing softly at 7.5 s. No music.

First frame: DOST at the door holding out the royal-blue garment bag to RAVI.
Last frame: DOST waving at the camera in the doorway, door half-closed behind him, clean space above for text.

AVOID: a visible phone screen, cash notes with readable numbers, RAVI speaking.
```
*Then paste the shared negative block.* Note: "రేపే" says "tomorrow", and the business promise is *usually* next day. The on-screen text says "సాధారణంగా" (usually) to keep it honest.

### D2 end card (3 s)
IronDost logo · "Pickup: 7–11 | 11–4 | 4–8" · "LB Nagar 6 km లోపల" · "Download IronDost" · "రేపు: ఆ షాప్ ఓనర్ కి ఏం అయ్యింది? 😂"

---

## 5. Gemini TTS fallback (Day 2 narration only)

Use this only if Veo's narration in D2-C2 or D2-C4 sounds wrong. **AI Studio → Generate media → Speech**, model: the newest *Gemini Pro TTS*, mode: single speaker. Try voices **Charon**, **Algenib** and **Orus**; keep the one that sounds like a real 30-year-old Hyderabad man. Use the same voice for every line.

Paste this as the style instructions:
```text
Read this like a real 30-year-old man from Hyderabad talking to a neighbour, not an announcer. Telangana Telugu accent, warm and low, calm, unhurried, a small smile in the voice. Natural pauses at the "…", slight breath before each phrase, no dramatic emphasis, no radio voice, conversational pace of about 2.5 words per second.
```
Then the text, one line per take:
```text
IronDost యాప్ లో బట్టలు ఎంచుకోండి… పొద్దున, మధ్యాహ్నం, సాయంత్రం… మీకు నచ్చిన టైమ్.
```
```text
మా సొంత మెషిన్లలో వాష్, ఐరన్… ప్రతి లోడ్ ఓనర్ గారే చేత్తో చెక్ చేస్తారు.
```
Download the WAV, lay it under the clip, add a little room tone (−30 dB) and cut Veo's voice. If any word sounds off, spell it the way it's spoken in Telugu script; don't use English letters.

---

## 6. DAY 3: "Attitude change" (payoff + offer)

**Hook text (0.2–2 s):** "ఆ షాప్ ఓనర్ గుర్తున్నాడా? 😂"
**Trending audio:** the same mass BGM as Day 1 (series feel); beat drop on **8.0 s**.
**Caption:**
> పికప్ కి ఎక్స్‌ట్రా అన్న అన్న… ఇప్పుడు మా కస్టమర్ 😂
> IronDost prices (per piece): Shirt wash & iron ₹35 · Shirt iron only ₹15 · Saree iron ₹50
> LB Nagar circle నుండి 6 km లోపల: Dilsukhnagar, Nagole, Saroornagar, Vanasthalipuram, Karmanghat, Champapet, Santosh Nagar…
> IronDost app download చేసి బుక్ చేయండి 📲
> #IronDost #LBNagar #Hyderabad #HyderabadLaundry #TeluguComedy #TeluguReels

### D3-C1 · 0–8 s · The secret booking
**Ingredients:** owner-ref.png · set-shop.png
**Edit text:** 0.2 s hook · 6 s "అర్ధరాత్రి 11:30 🤫"
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, night, a single warm tube light, deep shadows, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. The same small dry-cleaning shop on the LB Nagar road, shutter half-down, the street outside dark and empty.

Cast, matching the reference image exactly:
PRASAD: shop owner, Telugu man, 46, heavy build, receding combed-back hair, thick moustache, reading glasses low on his nose, thin gold chain, a plain white vest now instead of his shiny shirt.

Timeline (edited inside the clip):
0.0–2.5 s: Wide: PRASAD alone in the shop, behind the counter piled high with his own family's crumpled clothes: sarees, shirts, kids' school uniforms. He sighs and wipes his forehead.
2.5–5.0 s: Cut to a medium close-up: he looks left, then right, to check nobody is watching, then takes out his phone; the back of the phone faces the camera and a royal-blue glow lights his face.
5.0–8.0 s: Push-in to a close-up: he taps the phone and whispers his line straight into the lens with a guilty little smile, one finger on his lips.

Dialogue, exactly once, word for word:
At 5.5 s PRASAD, lip-synced, raspy Hyderabadi Telugu, a guilty whisper: "ఎవరికీ చెప్పకండి…" (Evariki cheppakandi…)
Nothing is said after this line.

Sound: tube light buzz, crickets, a distant dog bark, phone tap. No music until the edit.

First frame: wide night shot of PRASAD behind a counter piled with crumpled clothes, tube light above.
Last frame: close-up of PRASAD with a finger on his lips, face lit royal blue from below.

AVOID: other people, a visible phone screen, daylight, PRASAD in the cream shirt.
```
*Then paste the shared negative block.*

### D3-C2 · 8–16 s · Caught (beat drop)
**Ingredients:** owner-ref.png · dost-ref.png · ravi-outfit-ref.png
**Edit text:** 0.0 s white flash · 0.3 s "Next morning…" · logo patch on DOST's polo
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, bright morning sun, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. Outside the small dry-cleaning shop on the LB Nagar road, metro pillars behind.

Cast, matching the reference images exactly:
DOST: Telugu man, 30, neat moustache, plain royal-blue polo with a blank chest, dark grey trousers, black sling bag.
PRASAD: shop owner, 46, heavy build, thick moustache, reading glasses, gold chain, shiny cream shirt.
RAVI: Telugu man, 28, slim, crisp ironed plain white shirt.

Timeline (edited inside the clip):
0.0–2.5 s: Beat-drop slow motion: DOST walks up to the shop shutter, a gust of wind; PRASAD hurriedly hands him a big bundle of clothes while glancing around nervously. Bass impact boom at 0.0 s.
2.5–4.5 s: Real speed. RAVI, walking past on the footpath, stops dead, slowly turns his head toward PRASAD with a teasing raised eyebrow and speaks.
4.5–8.0 s: Cut to PRASAD's close-up: he freezes, gives an awkward embarrassed grin, scratches the back of his head and answers; DOST, beside him, presses his lips together, trying not to laugh.

Dialogue, each line exactly once, word for word:
At 2.8 s RAVI, lip-synced, soft friendly medium-pitch voice, teasing, Hyderabad Telugu: "ఏంటన్నా… పికప్ ఎక్స్‌ట్రా కదా?" (Entanna… pickup extra kada?)
At 5.2 s PRASAD, lip-synced, raspy Hyderabadi Telugu, sheepish and fast: "అది… ఫ్రీ అంట కదా…" (Adi… free anta kada…)
Nothing is said after PRASAD's line.

Sound: bass impact boom and wind whoosh at 0.0 s, street traffic, a record-scratch-style stop at 2.6 s, a soft snort of suppressed laughter from DOST at 7 s. No music.

First frame: slow-motion DOST walking toward the shop shutter in morning sun.
Last frame: PRASAD's embarrassed grin scratching his head, DOST holding back laughter beside him.

AVOID: sunglasses on anyone, DOST speaking, PRASAD angry, crowds.
```
*Then paste the shared negative block.*

### D3-C3 · 16–24 s · The offer (talk to camera)
**Ingredients:** dost-ref.png · set-shop.png
**Edit text:** price cards pop in on each spoken price: 1.5 s "Shirt wash & iron ₹35" · 3.5 s "Shirt iron only ₹15" · 5.5 s "LB Nagar 6 km 📍" · 7 s "Download IronDost 📲" · end card follows
```text
8-second clip, vertical 9:16, photoreal cinematic live action, premium Indian TV-commercial look, bright morning sun, 35mm lens, shallow depth of field, natural lip-synced Telugu speech. The LB Nagar main road with metro pillars softly blurred behind.

Cast, matching the reference image exactly:
DOST: Telugu man, 30, medium-dark skin, neat moustache, short side-parted black hair, calm kind smile, plain royal-blue polo with a blank chest, dark grey trousers, black sling bag, a plain royal-blue garment bag over his shoulder.

Timeline (edited inside the clip):
0.0–8.0 s: One shot. DOST walks two steps toward the camera and stops in a medium close-up, speaking directly into the lens, warm and confident, counting on his fingers for the two prices, then pointing at the viewer at the end. Very slow push-in.

Dialogue, exactly once, word for word:
At 0.8 s DOST, lip-synced, calm warm low baritone, Telangana Telugu, clear and friendly: "షర్ట్ వాష్, ఐరన్ ముప్పై ఐదు రూపాయలు. ఐరన్ మాత్రమే పదిహేను. ఎల్బీ నగర్ చుట్టుపక్కల… యాప్ డౌన్లోడ్ చేయండి." (Shirt wash, iron muppai aidu roopaayalu. Iron maatrame padihenu. LB Nagar chuttupakkala… app download cheyandi.)
Nothing is said after this line.

Sound: soft street ambience, distant metro train passing. No music.

First frame: DOST two steps from the camera on the LB Nagar road, garment bag over his shoulder.
Last frame: DOST in medium close-up pointing at the viewer with a smile, clean space above his head for text.

AVOID: wrong numbers spoken, DOST holding a phone, printed text on the bag or polo, people walking between him and the camera.
```
*Then paste the shared negative block.* If the shirt ironing offer has ended, change "పదిహేను" (15) to "ఇరవై" (20) in the line and the text.

### D3 end card (4 s)
IronDost logo · "Wash & Iron · Ironing · Dry cleaning" · "ఫ్రీ పికప్ & డ్రాప్ · LB Nagar" · "Google Play | App Store" · "WhatsApp: +91 79934 34932"

---

## 7. Assembly checklist (per day, ~15 minutes)
1. Pick the best of 2–4 takes per clip: faces match the refs, the Telugu words are exactly right, there's no AI text and the polo and bags are blank.
2. Drop clips in order in Instagram's editor (or CapCut, then export 1080×1920).
3. Lower the clip audio to 100%, add the trending audio at 15–25% under dialogue, and line its beat drop to the time given for that day.
4. Type the edit text at the given times (bold Telugu font, white with a black outline). Add Telugu + English captions for dialogue.
5. Add the logo patch on DOST's polo with motion tracking (CapCut → Tracking) and the end card.
6. Cover: Day 1 → PRASAD's smirk; Day 2 → DOST at the door; Day 3 → PRASAD's embarrassed grin. Big Telugu hook text on the cover.
7. Post: Day 1, 2 and 3 on consecutive evenings, 7–9 pm. Pin Day 1. Reply to every comment for the first hour.

## 3D option
To match the reference's 3D cartoon look, replace "photoreal cinematic live action, premium Indian TV-commercial look" with "high-end 3D animated film look, stylised Indian characters, soft subsurface skin, Pixar-quality lighting", and in the shared negative block remove "cartoon, anime or 3D-render look". First turn each reference image into 3D with Nano Banana Pro: "Turn the attached person into a 3D animated film character, same face shape, hair, moustache and clothes, same four-view layout." Voices still come out natural in 3D; lip-sync is a little looser.
