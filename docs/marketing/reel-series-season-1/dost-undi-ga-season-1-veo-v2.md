# Dost Undi Ga! Season 1 · Veo prompts v2
IronDost reel series · 10 episodes · 94 clips · rewritten 23 Nov 2026 in the INDYUG Gemini Clips format.

**Battala tension? IronDost undi ga!** · **Kapdon ki tension? Dost hai na!**

Facts on screen: Laundry 3 days · Ironing 2 days · Express 6 hrs at 2× price · ₹500+ gets 10% off with DOST10 · Call / WhatsApp 79934 34932 · 70329 90632 · post daily 7:30 pm IST.

## What changed from v1
- **One block per clip.** Every prompt is complete on its own: style, cast, the IronDost look, what happens second by second, camera, dialogue, sound, first and last frame, what to attach and a negative prompt. Copy it, paste it, generate.
- **Veo makes the voice too.** Dialogue is written in Telugu script (Bunty in Devanagari), then romanised, then the English meaning, so Veo pronounces it properly. If a voice still sounds wrong, mute it and dub a real voice (the v1 plan).
- **Ingredients to Video, not keyframes.** Attach the reference images listed on each clip (Flow allows 3). No separate keyframe step.
- **The IronDost look is locked** like a product: plain royal-blue garment bags and polo with no print, crisp clothes after IronDost, and story props described the same way every time.
- **Speaker rules** from the INDYUG audit: each line once, the listener's mouth stays closed, nothing after the last line, no silent gap over 1 s, no music.
- **Clip length.** Veo makes 8 s. Each clip says how many seconds the reel uses; the action and lines finish inside that, and the rest is a quiet hold you trim.

## How to make them
1. **Make the reference images once** (prompts below, already generated into `videos/dost-undi-ga/refs/`). Check the faces, then keep them.
2. **Flow → Ingredients to Video**, Veo at the highest quality you have, 9:16, audio on. Upload the images in the clip's Attach line, paste the whole prompt.
3. **Generate every clip fresh.** Don't use Extend across clips with different people or rooms; that is how the INDYUG Ep 2 take broke.
4. **Check before you keep a take:** right faces, Dost's polo and bags plain royal blue with no print, each line said once by the right lips, no music, no text drawn by the AI.
5. **Real clips** (phone screens, app, bills) are screen recordings or edit graphics. Record them from the real app.
6. **Save** as `videos/dost-undi-ga/epNN/E{n}-C{k}.mp4` and cut in CapCut: trim to the reel length, add the on-screen text, English subtitles, the logo on Dost's polo and bags, and the end card. Turn on the AI-content label when posting.

## Reference images (make once)
### `ravi-ref.png`
```text
Character reference sheet, photoreal, plain light-grey background, soft even studio light, 16:9 image. One person shown four times side by side: front view, three-quarter view, side view and full body. RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes. Exactly the same face in every view. Realistic skin texture, no makeup, no text, no logo, no watermark.
```
### `bunty-ref.png`
```text
Character reference sheet, photoreal, plain light-grey background, soft even studio light, 16:9 image. One person shown four times side by side: front view, three-quarter view, side view and full body. BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Exactly the same face in every view. Realistic skin texture, no text, no logo, no watermark.
```
### `dost-ref.png`
```text
Character reference sheet, photoreal, plain light-grey background, soft even studio light, 16:9 image. One person shown four times side by side: front view, three-quarter view, side view and full body, holding two plain royal-blue zip garment bags in the full-body view. DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder. The polo chest and the bags are completely blank. Exactly the same face in every view. Realistic skin texture, no text, no logo, no watermark.
```
### `set-flat.png`
```text
Photoreal interior reference, vertical 9:16, no people: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. No text.
```
### `set-unit.png`
```text
Photoreal interior reference, vertical 9:16, no people: the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor. No text, no logos. (Replace with real photos of your unit when you have them.)
```
### `set-hall.png`
```text
Photoreal interior reference, vertical 9:16, no people: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. No text.
```
### `set-office.png`
```text
Photoreal interior reference, vertical 9:16, no people: an open-plan IT office in HITEC City, Hyderabad: rows of desks with dual monitors, glass meeting rooms behind, cool daylight. No readable text on screens.
```
### `set-restaurant.png`
```text
Photoreal interior reference, vertical 9:16, no people: a busy Hyderabadi biryani restaurant at night: warm yellow lights, steel plates, a table for two with a copper handi of biryani and a bowl of mirchi ka salan. No text.
```
### `set-bus.png`
```text
Photoreal exterior reference, vertical 9:16: a red-and-white state transport bus on a wet highway near Hyderabad in light rain, a cardboard parcel tied with plastic rope on the roof carrier, grey sky. No readable text or logos.
```
### `props-ref.png`
```text
Photoreal product reference sheet on a plain light-grey background, soft studio light, 16:9, items laid out separately: (1) RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time. On a hanger. (2) RING BOX: small red velvet ring box. Closed. (3) THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border. Folded, side by side. (4) BUNTY's EID KURTA: cream silk kurta (the one that gets the iron-shaped burn in Ep 6). Folded, undamaged. (5) one plain royal-blue (#1F4FD1) zip garment bag with no print. No text, no logos.
```

## Episode 1 / 10 · Kondalu (The Mountain)
**Hook formula:** Pattern interrupt + stakes number · **Hook:** A cupboard explodes with clothes straight at the lens and buries Ravi.  
**Hook text on screen (edit):** 10 rojullo chelli engagement. Clean battalu: 0 · **Cliffhanger:** Repu udayam 7 gantalaki…  
**Caption:** Ep 1/10 — 10 rojullo chelli engagement, almirah lo kondalu 😭 #DostUndiGa #IronDost #Hyderabad #LBNagar #TeluguReels  
**Save in:** `videos/dost-undi-ga/ep01/`

### E1-C1 · 0–3 s · Almirah avalanche
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
On screen (edit): 10 rojullo chelli engagement. Clean battalu: 0  
- **RAVI** అమ్మాఆ…! · *Ammaaa…! (muffled)* · (Mummyyy…!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 1 · E1-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Camera placed inside a grey steel almirah looking out at the opening door. A huge mass of crumpled shirts, sarees, towels and lungis is bursting out toward the lens, frozen mid-air. Behind the flying clothes, Ravi in a grey vest and white-and-blue checked lungi, mouth open in shock, arms raised.
1–3 s: The almirah door swings open fast and the clothes avalanche flies toward the lens in slow motion, then Ravi disappears under the pile. Quick push-in toward Ravi.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "అమ్మాఆ…!" (Ammaaa…! (muffled, under the clothes)) [meaning: Mummyyy…!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Door creak, whoosh, heavy thud at 0.0 s. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Camera placed inside a grey steel almirah looking out at the opening door. A huge mass of crumpled shirts, sarees, towels and lungis is bursting out toward the lens, frozen mid-air. Behind the flying clothes, Ravi in a grey vest and white-and-blue checked lungi, mouth open in shock, arms raised.
LAST FRAME: the end of this action: The almirah door swings open fast and the clothes avalanche flies toward the lens in slow motion, then Ravi disappears under the pile. Quick push-in toward Ravi.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E1-C2 · 3–7 s · Clothes mountain
Attach: **ravi-ref.png + bunty-ref.png + set-flat.png**  
- **BUNTY** क्या रे, कपड़ों का चारमीनार बना दिया क्या? · *Kya re, kapdon ka Charminar bana diya kya?* · (What, did you build a Charminar of clothes?)

```text
IronDost reel 'Dost Undi Ga!' · Ep 1 · E1-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Wide shot of the flat: only Ravi's head and one arm stick out of a waist-high mountain of crumpled clothes on the floor. Bunty in a maroon printed half-sleeve shirt and black track pants sits on the sofa behind, holding an open foil biryani parcel, laughing.
1–4 s: Bunty laughs and points at Ravi with his spoon; Ravi blinks and blows a sock off his face. Slow dolly-in.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "क्या रे, कपड़ों का चारमीनार बना दिया क्या?" (Kya re, kapdon ka Charminar bana diya kya?) [meaning: What, did you build a Charminar of clothes?]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Bunty laugh. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Wide shot of the flat: only Ravi's head and one arm stick out of a waist-high mountain of crumpled clothes on the floor. Bunty in a maroon printed half-sleeve shirt and black track pants sits on the sofa behind, holding an open foil biryani parcel, laughing.
LAST FRAME: the end of this action: Bunty laughs and points at Ravi with his spoon; Ravi blinks and blows a sock off his face. Slow dolly-in.

ATTACH: ravi-ref.png + bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E1-C3 · 7–11 s · Amma calls
Attach: **ravi-ref.png + set-flat.png**  
On screen (edit): Add phone caller ID 'Amma ❤️' in edit  
- **AMMA (voice)** రవీ, దివ్య నిశ్చితార్థానికి ఇంకా పది రోజులే! నీ బట్టలు రెడీ నా? · *Ravi, Divya nischitartham ki inka padi rojule! Nee battalu ready na?* · (Ravi, only ten days to Divya's engagement! Are your clothes ready?)

```text
IronDost reel 'Dost Undi Ga!' · Ep 1 · E1-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Close-up of Ravi still half-buried in clothes, holding a phone to his ear with both hands, eyes wide with panic. Phone screen faces away from the camera.
1–4 s: Ravi presses the phone to his ear and his eyes widen as he listens. Very slow push-in.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
AMMA (Ravi's mother, about 55, warm Telugu voice, on the phone or off screen): "రవీ, దివ్య నిశ్చితార్థానికి ఇంకా పది రోజులే! నీ బట్టలు రెడీ నా?" (Ravi, Divya nischitartham ki inka padi rojule! Nee battalu ready na?) [meaning: Ravi, only ten days to Divya's engagement! Are your clothes ready?]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Ringtone. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Close-up of Ravi still half-buried in clothes, holding a phone to his ear with both hands, eyes wide with panic. Phone screen faces away from the camera.
LAST FRAME: the end of this action: Ravi presses the phone to his ear and his eyes widen as he listens. Very slow push-in.

ATTACH: ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E1-C4 · 11–14 s · Fake smile
Attach: **ravi-ref.png + set-flat.png**  
- **RAVI** హా… రెడీ అమ్మా, ఫుల్ రెడీ. · *Ha… ready Amma, full ready.* · (Yes… ready, Mummy, fully ready.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 1 · E1-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Tight close-up of Ravi's face forcing a big fake smile while sweating, phone at his ear, clothes around his shoulders.
1–3 s: Ravi forces a wide smile, then gulps nervously. Static camera.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "హా… రెడీ అమ్మా, ఫుల్ రెడీ." (Ha… ready Amma, full ready.) [meaning: Yes… ready, Mummy, fully ready.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Gulp. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Tight close-up of Ravi's face forcing a big fake smile while sweating, phone at his ear, clothes around his shoulders.
LAST FRAME: the end of this action: Ravi forces a wide smile, then gulps nervously. Static camera.

ATTACH: ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E1-C5 · 14–17 s · Bunty's advice
Attach: **bunty-ref.png + set-flat.png**  
- **BUNTY** गली के धोबी को दे दे. · *Gali ke dhobi ko de de.* · (Give it to the street dhobi.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 1 · E1-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Medium close-up of Bunty on the sofa, cheeks full of biryani, holding up a chicken leg piece like a pointer.
1–3 s: Bunty chews and waves the chicken piece while talking. Static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "गली के धोबी को दे दे." (Gali ke dhobi ko de de.) [meaning: Give it to the street dhobi.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Medium close-up of Bunty on the sofa, cheeks full of biryani, holding up a chicken leg piece like a pointer.
LAST FRAME: the end of this action: Bunty chews and waves the chicken piece while talking. Static.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E1-C6 · 17–21 s · Dhobi stall closed
**Real clip, no AI.** Daytime street in an LB Nagar colony: a small roadside ironing stall with a coal iron on a wooden table, its blue rolling shutter pulled down and locked with a padlock, a blank white paper taped on the shutter.  
Motion in the edit: Slow pan from the coal iron to the locked shutter and the paper. 4 seconds.  
Voice over (RAVI): ధోబీ అన్న ఊరికి వెళ్ళిపోయాడు రా. · *Dhobi anna ooruki vellipoyadu ra.* · (The dhobi went to his village.)  
On screen: Write on the paper in edit: 'Ooruki vellanu — 15 days'  

### E1-C7 · 21–25 s · Amma's WhatsApp
**Real clip, no AI.** REAL / EDIT: phone screen mock-up of a WhatsApp chat from 'Amma ❤️' forwarding the IronDost poster, plus a voice-note bubble.  
Motion in the edit: Screen recording or CapCut mock-up; the poster pops in with a ping.  
Voice over (AMMA): ఈ యాప్ చూడు రా, ఎల్ బి నగర్ లో ఇంటికొచ్చి తీసుకెళ్తారు. · *Ee app chudu ra, LB Nagar lo intikochi teeskeltaru.* · (Look at this app, they pick up from home in LB Nagar.)  
Sound: WhatsApp ping  

### E1-C8 · 25–30 s · Booking in the app
**Real clip, no AI.** REAL: screen-record the live IronDost app on a phone: home → add shirts and pants → choose pickup slot 'Tomorrow 7–11 am' → Confirm.  
Motion in the edit: Real screen recording, sped up 2×, with a finger tap overlay.  
On screen: Pickup slots: 7–11 · 11–4 · 4–8  
Sound: Soft ping on Confirm  

### E1-C9 · 30–34 s · Lucky shirt
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
- **RAVI** ఇది నా లక్కీ షర్ట్. జాగ్రత్త. · *Idi naa lucky shirt. Jagratta.* · (This is my lucky shirt. Careful.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 1 · E1-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Ravi kneels on the floor stuffing clothes into a big laundry bag; he holds up a navy-blue cotton shirt with thin white checks and kisses it gently.
1–4 s: Ravi lifts the navy checked shirt, kisses it and places it carefully on top of the bag. Slow push-in.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "ఇది నా లక్కీ షర్ట్. జాగ్రత్త." (Idi naa lucky shirt. Jagratta.) [meaning: This is my lucky shirt. Careful.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi kneels on the floor stuffing clothes into a big laundry bag; he holds up a navy-blue cotton shirt with thin white checks and kisses it gently.
LAST FRAME: the end of this action: Ravi lifts the navy checked shirt, kisses it and places it carefully on top of the bag. Slow push-in.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E1-C10 · 34–38 s · Cliffhanger
Attach: **bunty-ref.png + ravi-ref.png + set-flat.png**  
On screen (edit): Repu udayam 7 gantalaki…  
- **BUNTY** ऑनलाइन वाले कपड़े गायब कर देते, देख लेना. · *Online wale kapde gayab kar dete, dekh lena.* · (Online people make clothes disappear, you'll see.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 1 · E1-C10 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Bunty leans into the frame from the left in close-up, eyes narrowed and suspicious; behind him, out of focus, Ravi holds the navy checked shirt with a worried face.
1–4 s: Bunty leans in slowly and narrows his eyes; focus racks from Bunty to Ravi's worried face, then the frame freezes.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "ऑनलाइन वाले कपड़े गायब कर देते, देख लेना." (Online wale kapde gayab kar dete, dekh lena.) [meaning: Online people make clothes disappear, you'll see.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Suspense sting on freeze. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty leans into the frame from the left in close-up, eyes narrowed and suspicious; behind him, out of focus, Ravi holds the navy checked shirt with a worried face.
LAST FRAME: the end of this action: Bunty leans in slowly and narrows his eyes; focus racks from Bunty to Ravi's worried face, then the frame freezes.

ATTACH: bunty-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```


## Episode 2 / 10 · 7:02 (7:02 am)
**Hook formula:** Flash-forward · **Hook:** Open on the ring box being pulled out of the pocket, then jump back 15 minutes.  
**Hook text on screen (edit):** Ee okka pocket… oka engagement ni aapesedi · **Cliffhanger:** Adi… Divya engagement ring!  
**Caption:** Ep 2/10 — Pocket lo engagement ring marchipoyadu 😱 #DostUndiGa #IronDost #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep02/`

### E2-C1 · 0–3 s · Flash-forward: the ring
Attach: **set-flat.png + props-ref.png**  
On screen (edit): Ee okka pocket… oka engagement ni aapesedi. → '15 nimishalu mundu…'  

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RING BOX: small red velvet ring box.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Extreme macro close-up: a man's fingers slowly pulling a small red velvet ring box out of the chest pocket of a navy-blue shirt with thin white checks. Dramatic side light, dark background.
1–3 s: The fingers pull the red ring box out of the pocket very slowly; the light flickers.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Heartbeat, music cuts out. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Extreme macro close-up: a man's fingers slowly pulling a small red velvet ring box out of the chest pocket of a navy-blue shirt with thin white checks. Dramatic side light, dark background.
LAST FRAME: the end of this action: The fingers pull the red ring box out of the pocket very slowly; the light flickers.

ATTACH: set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E2-C2 · 3–6 s · 7:02 doorbell
Attach: **ravi-ref.png + set-flat.png**  
- **RAVI** ఇంత పొద్దున్నే ఎవరు రా?! · *Intha poddunne evaru ra?!* · (Who comes this early?!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi asleep face-down on a bed in a grey vest, blanket half off; a round wall clock above shows 7:02. Early morning light.
1–3 s: Ravi's eyes snap open and he lifts his head in shock. Static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "ఇంత పొద్దున్నే ఎవరు రా?!" (Intha poddunne evaru ra?!) [meaning: Who comes this early?!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Doorbell twice at 0.0 s. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi asleep face-down on a bed in a grey vest, blanket half off; a round wall clock above shows 7:02. Early morning light.
LAST FRAME: the end of this action: Ravi's eyes snap open and he lifts his head in shock. Static.

ATTACH: ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E2-C3 · 6–10 s · Dost at the door
Attach: **ravi-ref.png + dost-ref.png + set-flat.png**  
- **DOST** నమస్కారం సర్, ఐరన్ దోస్త్ నుంచి. సెవెన్ టు ఎలెవెన్ స్లాట్. · *Namaskaram sir, IronDost nunchi. 7 to 11 slot.* · (Hello sir, from IronDost. Your 7–11 slot.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi opens the flat's front door in a grey vest and checked lungi, toothbrush in mouth with white foam. Dost stands in the corridor smiling politely, holding folded royal-blue garment bags.
1–4 s: Dost gives a small polite nod and smile; Ravi freezes with the toothbrush. Slow push past Ravi's shoulder.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "నమస్కారం సర్, ఐరన్ దోస్త్ నుంచి. సెవెన్ టు ఎలెవెన్ స్లాట్." (Namaskaram sir, IronDost nunchi. 7 to 11 slot.) [meaning: Hello sir, from IronDost. Your 7–11 slot.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi opens the flat's front door in a grey vest and checked lungi, toothbrush in mouth with white foam. Dost stands in the corridor smiling politely, holding folded royal-blue garment bags.
LAST FRAME: the end of this action: Dost gives a small polite nod and smile; Ravi freezes with the toothbrush. Slow push past Ravi's shoulder.

ATTACH: ravi-ref.png + dost-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot
```

### E2-C4 · 10–13 s · Bunty shocked
Attach: **bunty-ref.png + set-flat.png**  
- **BUNTY** टाइम पे आए? हैदराबाद में? · *Time pe aaye? Hyderabad mein?* · (On time? In Hyderabad?)

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty behind Ravi in the hallway, a blanket wrapped over his shoulders, hair messy, mouth open in disbelief.
1–3 s: Bunty's jaw drops and he rubs his eyes. Static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "टाइम पे आए? हैदराबाद में?" (Time pe aaye? Hyderabad mein?) [meaning: On time? In Hyderabad?]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty behind Ravi in the hallway, a blanket wrapped over his shoulders, hair messy, mouth open in disbelief.
LAST FRAME: the end of this action: Bunty's jaw drops and he rubs his eyes. Static.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E2-C5 · 13–18 s · Counting every item
Attach: **dost-ref.png + ravi-ref.png + set-flat.png**  
- **DOST** పద్దెనిమిది షర్ట్స్, నాలుగు ప్యాంట్స్, రెండు బెడ్‌షీట్స్… · *Paddenimidi shirts, naalugu pants, rendu bedsheets…* · (Eighteen shirts, four pants, two bedsheets…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost kneels on the floor sorting clothes into neat counted stacks (shirts, pants, bedsheets) while Ravi stands watching. Top-down three-quarter angle.
1–5 s: Dost places each shirt on a stack, counting with his finger. Slow overhead drift.
5–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–5 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 4.5 s; each line said exactly once; nothing is said after the last line):
DOST: "పద్దెనిమిది షర్ట్స్, నాలుగు ప్యాంట్స్, రెండు బెడ్‌షీట్స్…" (Paddenimidi shirts, naalugu pants, rendu bedsheets…) [meaning: Eighteen shirts, four pants, two bedsheets…]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost kneels on the floor sorting clothes into neat counted stacks (shirts, pants, bedsheets) while Ravi stands watching. Top-down three-quarter angle.
LAST FRAME: the end of this action: Dost places each shirt on a stack, counting with his finger. Slow overhead drift.

ATTACH: dost-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot
```

### E2-C6 · 18–22 s · Loose button
Attach: **dost-ref.png + set-flat.png + props-ref.png**  
- **DOST** సర్, ఈ బటన్ లూజ్ ఉంది. నోట్ చేస్తాను. · *Sir, ee button loose undi. Note chestanu.* · (Sir, this button is loose. I'll note it.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C6 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Close-up of Dost's hands holding the navy checked shirt, his thumb pointing to a loose hanging button.
1–4 s: Dost's thumb gently wiggles the loose button. Static macro.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "సర్, ఈ బటన్ లూజ్ ఉంది. నోట్ చేస్తాను." (Sir, ee button loose undi. Note chestanu.) [meaning: Sir, this button is loose. I'll note it.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Close-up of Dost's hands holding the navy checked shirt, his thumb pointing to a loose hanging button.
LAST FRAME: the end of this action: Dost's thumb gently wiggles the loose button. Static macro.

ATTACH: dost-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E2-C7 · 22–26 s · Order detail + care note
**Real clip, no AI.** REAL: screen-record the order detail screen showing the itemised list and the care note 'button loose'.  
Motion in the edit: Real screen recording, slow scroll.  
Sound: Soft ping  

### E2-C8 · 26–30 s · Pocket check
Attach: **dost-ref.png + ravi-ref.png + set-flat.png**  
- **DOST** సర్… పాకెట్ లో ఏదో ఉంది. · *Sir… pocket lo edo undi.* · (Sir… there's something in the pocket.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Dost slips two fingers into the chest pocket of the navy checked shirt and frowns slightly; Ravi in the background, unaware, brushing teeth.
1–4 s: Dost's fingers feel something inside the pocket; his eyebrows lift. Slow push-in.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "సర్… పాకెట్ లో ఏదో ఉంది." (Sir… pocket lo edo undi.) [meaning: Sir… there's something in the pocket.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost slips two fingers into the chest pocket of the navy checked shirt and frowns slightly; Ravi in the background, unaware, brushing teeth.
LAST FRAME: the end of this action: Dost's fingers feel something inside the pocket; his eyebrows lift. Slow push-in.

ATTACH: dost-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot
```

### E2-C9 · 30–33 s · Cliffhanger
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
On screen (edit): Adi… Divya engagement ring!  

```text
IronDost reel 'Dost Undi Ga!' · Ep 2 · E2-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RING BOX: small red velvet ring box.

SHOT, SECOND BY SECOND:
0–1 s: Tight close-up of Ravi's face going pale, toothbrush hanging from his mouth, staring at a small red velvet ring box held up in the foreground (out of focus).
1–3 s: Ravi's toothbrush slowly drops out of his mouth; freeze frame.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Music stops dead, then a sting. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Tight close-up of Ravi's face going pale, toothbrush hanging from his mouth, staring at a small red velvet ring box held up in the foreground (out of focus).
LAST FRAME: the end of this action: Ravi's toothbrush slowly drops out of his mouth; freeze frame.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```


## Episode 3 / 10 · Pocket (The Pocket)
**Hook formula:** Slow-motion action · **Hook:** The ring box flies through the air and Ravi dives for it like a cricket fielder.  
**Hook text on screen (edit):** Chelli engagement ring. 1 second. · **Cliffhanger:** Amma parcel… daarilo undi.  
**Caption:** Ep 3/10 — Every pocket checked ✅ Amma parcel vastundi 😅 #DostUndiGa #IronDost #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep03/`

### E3-C1 · 0–3 s · The dive
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
On screen (edit): Chelli engagement ring. 1 second.  
- **RAVI** పట్టుకో…! · *Pattukooo!* · (Catch it!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RING BOX: small red velvet ring box.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Ravi in a grey vest and checked lungi, fully horizontal mid-air in a cricket-fielder dive across the flat's hallway, one hand stretched toward a small red velvet ring box tumbling in the air.
1–3 s: Super slow motion: the ring box tumbles, Ravi stretches and catches it just before it hits the floor.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "పట్టుకో…!" (Pattukooo!) [meaning: Catch it!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Whoosh, slow-mo bass hit. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi in a grey vest and checked lungi, fully horizontal mid-air in a cricket-fielder dive across the flat's hallway, one hand stretched toward a small red velvet ring box tumbling in the air.
LAST FRAME: the end of this action: Super slow motion: the ring box tumbles, Ravi stretches and catches it just before it hits the floor.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E3-C2 · 3–6 s · Saved
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
- **RAVI** అమ్మ చంపేస్తుంది… · *Amma champestundi…* · (Mummy would have killed me…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RING BOX: small red velvet ring box.

SHOT, SECOND BY SECOND:
0–1 s: Ravi lying flat on his back on the mosaic floor, clutching the red ring box to his chest, breathing hard, eyes closed in relief.
1–3 s: Ravi's chest heaves, he exhales and laughs weakly. Top-down static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "అమ్మ చంపేస్తుంది…" (Amma champestundi…) [meaning: Mummy would have killed me…]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi lying flat on his back on the mosaic floor, clutching the red ring box to his chest, breathing hard, eyes closed in relief.
LAST FRAME: the end of this action: Ravi's chest heaves, he exhales and laughs weakly. Top-down static.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E3-C3 · 6–11 s · Every pocket
Attach: **dost-ref.png + ravi-ref.png + set-flat.png**  
- **DOST** మేము ప్రతి పాకెట్ చెక్ చేస్తాం సర్. మీ వస్తువులు మీ దగ్గరే ఉండాలి. · *Memu prathi pocket check chestam sir. Mee vasthuvulu mee daggare undali.* · (We check every pocket, sir. Your things should stay with you.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost kneels calmly beside Ravi on the floor, one hand on his own chest, sincere expression.
1–5 s: Dost speaks calmly and gives a small reassuring nod. Slow push-in on Dost.
5–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–5 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 4.5 s; each line said exactly once; nothing is said after the last line):
DOST: "మేము ప్రతి పాకెట్ చెక్ చేస్తాం సర్. మీ వస్తువులు మీ దగ్గరే ఉండాలి." (Memu prathi pocket check chestam sir. Mee vasthuvulu mee daggare undali.) [meaning: We check every pocket, sir. Your things should stay with you.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost kneels calmly beside Ravi on the floor, one hand on his own chest, sincere expression.
LAST FRAME: the end of this action: Dost speaks calmly and gives a small reassuring nod. Slow push-in on Dost.

ATTACH: dost-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot
```

### E3-C4 · 11–14 s · Bunty impressed
Attach: **bunty-ref.png + set-flat.png**  
- **BUNTY** भाई… ये बंदे सच्चे हैं. · *Bhai… ye bande sachche hain.* · (Bro… these people are honest.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty leaning on the doorframe with arms folded and the blanket still on his shoulders, slowly nodding, impressed.
1–3 s: Bunty nods slowly and raises his eyebrows. Static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "भाई… ये बंदे सच्चे हैं." (Bhai… ye bande sachche hain.) [meaning: Bro… these people are honest.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty leaning on the doorframe with arms folded and the blanket still on his shoulders, slowly nodding, impressed.
LAST FRAME: the end of this action: Bunty nods slowly and raises his eyebrows. Static.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E3-C5 · 14–18 s · Turnaround
Attach: **dost-ref.png + set-flat.png**  
On screen (edit): Ironing: 2 days · Laundry: 3 days  
- **DOST** ఐరనింగ్ రెండు రోజుల్లో, లాండ్రీ మూడు రోజుల్లో, సర్. · *Ironing rendu rojullo, laundry moodu rojullo, sir.* · (Ironing in two days, laundry in three, sir.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost at the open front door lifting two full royal-blue laundry bags onto his shoulder, turning back to speak.
1–4 s: Dost lifts the bags and turns to smile back. Static.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "ఐరనింగ్ రెండు రోజుల్లో, లాండ్రీ మూడు రోజుల్లో, సర్." (Ironing rendu rojullo, laundry moodu rojullo, sir.) [meaning: Ironing in two days, laundry in three, sir.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost at the open front door lifting two full royal-blue laundry bags onto his shoulder, turning back to speak.
LAST FRAME: the end of this action: Dost lifts the bags and turns to smile back. Static.

ATTACH: dost-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E3-C6 · 18–22 s · Timeline: picked up
**Real clip, no AI.** REAL: screen-record the order timeline with 'Picked up ✓'.  
Motion in the edit: Real screen recording.  
Sound: Ping  

### E3-C7 · 22–26 s · Amma's new demand
Attach: **ravi-ref.png + set-flat.png**  
- **AMMA (voice)** రవీ, నా పట్టు చీరలు, నాన్న పంచ బస్ లో పంపుతున్నా. అవి కూడా రెడీ చెయ్యి! · *Ravi, naa pattu cheeralu, naanna pancha bus lo pamputunna. Avi kooda ready cheyyi!* · (Ravi, I'm sending my silk sarees and Dad's dhoti on the bus. Get them ready too!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C7 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi standing by the window grills with his phone to his ear, face falling as he listens.
1–4 s: Ravi's smile fades into worry as he listens. Slow push-in.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
AMMA (Ravi's mother, about 55, warm Telugu voice, on the phone or off screen): "రవీ, నా పట్టు చీరలు, నాన్న పంచ బస్ లో పంపుతున్నా. అవి కూడా రెడీ చెయ్యి!" (Ravi, naa pattu cheeralu, naanna pancha bus lo pamputunna. Avi kooda ready cheyyi!) [meaning: Ravi, I'm sending my silk sarees and Dad's dhoti on the bus. Get them ready too!]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi standing by the window grills with his phone to his ear, face falling as he listens.
LAST FRAME: the end of this action: Ravi's smile fades into worry as he listens. Slow push-in.

ATTACH: ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E3-C8 · 26–29 s · Bunty's line
Attach: **bunty-ref.png + ravi-ref.png + set-flat.png**  
- **BUNTY** अब तो दोस्त ही बचाएगा. · *Ab toh Dost hi bachayega.* · (Now only Dost can save you.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Two-shot: Ravi looks helplessly at Bunty, who shrugs with both palms up.
1–3 s: Bunty shrugs and grins. Static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "अब तो दोस्त ही बचाएगा." (Ab toh Dost hi bachayega.) [meaning: Now only Dost can save you.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Two-shot: Ravi looks helplessly at Bunty, who shrugs with both palms up.
LAST FRAME: the end of this action: Bunty shrugs and grins. Static.

ATTACH: bunty-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E3-C9 · 29–33 s · Cliffhanger: the bus
Attach: **set-bus.png**  
On screen (edit): Amma parcel… daarilo undi.  

```text
IronDost reel 'Dost Undi Ga!' · Ep 3 · E3-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a red-and-white state transport bus on a wet highway near Hyderabad in light rain, a cardboard parcel tied with plastic rope on the roof carrier, grey sky. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: A red-and-white state transport bus driving on a wet highway in light rain, a cardboard parcel tied with plastic rope bouncing on the roof carrier.
1–4 s: Tracking shot alongside the bus; the parcel bounces as rain falls; freeze on the parcel.
4–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Rain, bus horn. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: A red-and-white state transport bus driving on a wet highway in light rain, a cardboard parcel tied with plastic rope bouncing on the roof carrier.
LAST FRAME: the end of this action: Tracking shot alongside the bus; the parcel bounces as rain falls; freeze on the parcel.

ATTACH: set-bus.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```


## Episode 4 / 10 · Lopala (Inside)
**Hook formula:** Impossible POV + curiosity question · **Hook:** POV from inside a giant washing-machine drum as clothes tumble at the lens.  
**Hook text on screen (edit):** Mee battalu ekkadiki veltayi? · **Cliffhanger:** Bunty em chestunnadu…?  
**Caption:** Ep 4/10 — IronDost lopala ela untundo chudandi 👀 Pedda machines, owner check #DostUndiGa #IronDost #Laundry #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep04/`

### E4-C1 · 0–3 s · Inside the drum
Attach: **set-unit.png**  
On screen (edit): Mee battalu ekkadiki veltayi?  

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Point of view from inside a large stainless-steel industrial washing machine drum: white and blue shirts and foamy water tumbling toward the lens, light coming through the round glass door.
1–3 s: The drum spins, clothes and water rush at the lens, then a hard cut to black.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Deep machine rumble, water splash at 0.0 s. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Point of view from inside a large stainless-steel industrial washing machine drum: white and blue shirts and foamy water tumbling toward the lens, light coming through the round glass door.
LAST FRAME: the end of this action: The drum spins, clothes and water rush at the lens, then a hard cut to black.

ATTACH: set-unit.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E4-C2 · 3–6 s · Ravi at the office
Attach: **ravi-ref.png + set-office.png**  
- **RAVI** నా షర్ట్స్ ఏం చేస్తున్నాయో… · *Naa shirts em chestunnayo…* · (What are my shirts up to…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: an open-plan IT office in HITEC City, Hyderabad: rows of desks with dual monitors, glass meeting rooms behind, cool daylight. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi in a light-blue formal shirt at an office desk with dual monitors, secretly looking at his phone under the desk.
1–3 s: Ravi glances around, then back at his phone under the desk. Static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "నా షర్ట్స్ ఏం చేస్తున్నాయో…" (Naa shirts em chestunnayo…) [meaning: What are my shirts up to…]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi in a light-blue formal shirt at an office desk with dual monitors, secretly looking at his phone under the desk.
LAST FRAME: the end of this action: Ravi glances around, then back at his phone under the desk. Static.

ATTACH: ravi-ref.png + set-office.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E4-C3 · 6–10 s · The machines
Attach: **set-unit.png**  
- **DOST (voice)** ఇదే మా యూనిట్. పెద్ద మెషీన్లు… · *Ide maa unit. Pedda machines…* · (This is our unit. Big machines…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Wide shot of the IronDost unit: a row of large stainless-steel front-loading industrial washer-extractors and tumble dryers all running, shelves of numbered royal-blue garment bags on the side.
1–4 s: Slow dolly along the row of running machines.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "ఇదే మా యూనిట్. పెద్ద మెషీన్లు…" (Ide maa unit. Pedda machines…) [meaning: This is our unit. Big machines…]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.

SOUND: Machine hum. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Wide shot of the IronDost unit: a row of large stainless-steel front-loading industrial washer-extractors and tumble dryers all running, shelves of numbered royal-blue garment bags on the side.
LAST FRAME: the end of this action: Slow dolly along the row of running machines.

ATTACH: set-unit.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E4-C4 · 10–14 s · Owner's hand check
Attach: **set-unit.png**  
- **DOST (voice)** …ప్రతి లోడ్ ని ఓనర్ చేత్తో చెక్ చేస్తారు. · *…prathi load ni owner chetto check chestaru.* · (…the owner checks every load by hand.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Close-up of an older man's hands under a bright white LED light turning the collar of a freshly washed white shirt, inspecting it carefully.
1–4 s: The hands turn the collar and smooth the fabric. Slow push-in.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "…ప్రతి లోడ్ ని ఓనర్ చేత్తో చెక్ చేస్తారు." (…prathi load ni owner chetto check chestaru.) [meaning: …the owner checks every load by hand.]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Close-up of an older man's hands under a bright white LED light turning the collar of a freshly washed white shirt, inspecting it carefully.
LAST FRAME: the end of this action: The hands turn the collar and smooth the fabric. Slow push-in.

ATTACH: set-unit.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E4-C5 · 14–18 s · Steam press
Attach: **set-unit.png**  

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: A worker in a royal-blue polo pressing a white cotton shirt on a large industrial steam press table, a big burst of steam rising.
1–4 s: The press comes down and a burst of steam rises; the shirt goes from crushed to sharp.
4–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Loud steam hiss. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: A worker in a royal-blue polo pressing a white cotton shirt on a large industrial steam press table, a big burst of steam rising.
LAST FRAME: the end of this action: The press comes down and a burst of steam rises; the shirt goes from crushed to sharp.

ATTACH: set-unit.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E4-C6 · 18–21 s · Button stitched
Attach: **set-unit.png**  
- **DOST (voice)** మీ నోట్ చదివాం సర్. · *Mee note chadivam sir.* · (We read your note, sir.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C6 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Macro shot of a needle and white thread stitching a button back onto a navy-blue shirt with thin white checks.
1–3 s: The needle pulls the thread through and the button sits tight.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
DOST: "మీ నోట్ చదివాం సర్." (Mee note chadivam sir.) [meaning: We read your note, sir.]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Macro shot of a needle and white thread stitching a button back onto a navy-blue shirt with thin white checks.
LAST FRAME: the end of this action: The needle pulls the thread through and the button sits tight.

ATTACH: set-unit.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E4-C7 · 21–25 s · Timeline moves
**Real clip, no AI.** REAL: screen-record the timeline moving from Washing to Ironing.  
Motion in the edit: Real screen recording.  
Sound: Ping  

### E4-C8 · 25–28 s · Caught
Attach: **ravi-ref.png + set-office.png**  
- **MANAGER (voice)** రవీ! ఫోన్ కింద పెట్టు! · *Ravi! Phone kinda pettu!* · (Ravi! Phone down!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: an open-plan IT office in HITEC City, Hyderabad: rows of desks with dual monitors, glass meeting rooms behind, cool daylight. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi smiling at his phone at his desk; behind him the blurred silhouette of a manager standing with hands on hips.
1–3 s: Ravi's smile freezes as he senses the manager; he slowly turns.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
MANAGER (Ravi's boss, stern man's voice, off screen): "రవీ! ఫోన్ కింద పెట్టు!" (Ravi! Phone kinda pettu!) [meaning: Ravi! Phone down!]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi smiling at his phone at his desk; behind him the blurred silhouette of a manager standing with hands on hips.
LAST FRAME: the end of this action: Ravi's smile freezes as he senses the manager; he slowly turns.

ATTACH: ravi-ref.png + set-office.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E4-C9 · 28–31 s · Cliffhanger
Attach: **bunty-ref.png + set-flat.png**  
On screen (edit): Bunty em chestunnadu…?  

```text
IronDost reel 'Dost Undi Ga!' · Ep 4 · E4-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dim evening light in the flat: Bunty's hand slowly opening Ravi's grey steel almirah, his face half in shadow.
1–3 s: The almirah door creaks open slowly; push-in on Bunty's sneaky eyes; freeze.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Creak, suspense sting. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dim evening light in the flat: Bunty's hand slowly opening Ravi's grey steel almirah, his face half in shadow.
LAST FRAME: the end of this action: The almirah door creaks open slowly; push-in on Bunty's sneaky eyes; freeze.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```


## Episode 5 / 10 · Delivery (Delivery Day)
**Hook formula:** Before / after transformation · **Hook:** A crumpled shirt in a fist whips into a crisp shirt snapping open in sunlight.  
**Hook text on screen (edit):** 2 rojula mundu vs ippudu · **Cliffhanger:** Kal Bunty ka date… aur shirt?  
**Caption:** Ep 5/10 — Promise chesina rojuke delivery ✅ Kaani Bunty plan enti? 🤨 #DostUndiGa #IronDost #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep05/`

### E5-C1 · 0–2 s · Before
Attach: **set-flat.png**  
On screen (edit): 2 rojula mundu…  

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Extreme close-up of a fist crushing a badly crumpled navy-blue shirt with thin white checks, harsh dull light.
1–2 s: The fist squeezes the shirt, then a fast whip-pan to the right (transition).
2–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–2 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Fabric crunch at 0.0 s, whoosh. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Extreme close-up of a fist crushing a badly crumpled navy-blue shirt with thin white checks, harsh dull light.
LAST FRAME: the end of this action: The fist squeezes the shirt, then a fast whip-pan to the right (transition).

ATTACH: set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E5-C2 · 2–4 s · After
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
On screen (edit): …ippudu  
- **RAVI** అహాఆ… · *Ahaaa…* · (Ahhh…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. The same navy checked shirt, now perfectly ironed with a sharp collar, on a hanger held up by Ravi in front of a sunny window, a soft puff of steam around it.
1–2 s: Continue the whip-pan into the crisp shirt snapping open on the hanger in slow motion, sunlight flaring behind it.
2–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–2 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 1.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "అహాఆ…" (Ahaaa…) [meaning: Ahhh…]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Fabric snap, choir 'aah'. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: The same navy checked shirt, now perfectly ironed with a sharp collar, on a hanger held up by Ravi in front of a sunny window, a soft puff of steam around it.
LAST FRAME: the end of this action: Continue the whip-pan into the crisp shirt snapping open on the hanger in slow motion, sunlight flaring behind it.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E5-C3 · 4–8 s · Delivery
Attach: **dost-ref.png + ravi-ref.png + set-flat.png**  
- **DOST** ఐరనింగ్ ఆర్డర్, రెండు రోజుల్లో, చెప్పినట్టు. · *Ironing order, rendu rojullo, cheppinattu.* · (Ironing order, in two days, as promised.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost at the flat door holding a neat stack of royal-blue garment bags and folded white bedsheets, Ravi opening the door in a formal shirt.
1–4 s: Dost hands over the bags with a smile. Static.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "ఐరనింగ్ ఆర్డర్, రెండు రోజుల్లో, చెప్పినట్టు." (Ironing order, rendu rojullo, cheppinattu.) [meaning: Ironing order, in two days, as promised.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Doorbell. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost at the flat door holding a neat stack of royal-blue garment bags and folded white bedsheets, Ravi opening the door in a formal shirt.
LAST FRAME: the end of this action: Dost hands over the bags with a smile. Static.

ATTACH: dost-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot
```

### E5-C4 · 8–12 s · Showroom shirts
Attach: **ravi-ref.png + set-flat.png**  
- **RAVI** ఇవి నా షర్ట్స్ ఆ? షోరూమ్ లాగ ఉన్నాయి! · *Ivi naa shirts aa? Showroom laga unnayi!* · (These are my shirts? They look like a showroom!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi unzipping a royal-blue garment bag on the bed, revealing a row of crisp ironed shirts on hangers with sharp collars.
1–4 s: The zip opens and Ravi's face lights up. Slow push-in.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "ఇవి నా షర్ట్స్ ఆ? షోరూమ్ లాగ ఉన్నాయి!" (Ivi naa shirts aa? Showroom laga unnayi!) [meaning: These are my shirts? They look like a showroom!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi unzipping a royal-blue garment bag on the bed, revealing a row of crisp ironed shirts on hangers with sharp collars.
LAST FRAME: the end of this action: The zip opens and Ravi's face lights up. Slow push-in.

ATTACH: ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E5-C5 · 12–15 s · Button fixed
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
- **RAVI** బటన్ కూడా?! · *Button kooda?!* · (Even the button?!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Macro close-up of Ravi's finger touching a freshly stitched button on the navy checked shirt.
1–3 s: Ravi's finger taps the firm button.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "బటన్ కూడా?!" (Button kooda?!) [meaning: Even the button?!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Macro close-up of Ravi's finger touching a freshly stitched button on the navy checked shirt.
LAST FRAME: the end of this action: Ravi's finger taps the firm button.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E5-C6 · 15–19 s · Bill and pay
**Real clip, no AI.** REAL: screen-record order bill → pay in app → 'Delivered ✓'.  
Motion in the edit: Real screen recording.  
Sound: Ping  

### E5-C7 · 19–22 s · Bunty feels the fabric
Attach: **bunty-ref.png + set-flat.png + props-ref.png**  
- **BUNTY** हौ… मस्त है. · *Hau… mast hai.* · (Yeah… it's nice.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C7 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Bunty secretly rubbing the sleeve of the navy checked shirt between his fingers, looking sideways guiltily.
1–3 s: Bunty rubs the fabric and glances around.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "हौ… मस्त है." (Hau… mast hai.) [meaning: Yeah… it's nice.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty secretly rubbing the sleeve of the navy checked shirt between his fingers, looking sideways guiltily.
LAST FRAME: the end of this action: Bunty rubs the fabric and glances around.

ATTACH: bunty-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E5-C8 · 22–25 s · Date message
**Real clip, no AI.** EDIT: phone notification mock-up 'Ayesha 💕: Kal 7 baje, Paradise?' over a shot of Bunty's surprised face (use clip E5-C7 frame).  
Motion in the edit: Notification slides down in CapCut.  
Sound: Notification ding  

### E5-C9 · 25–28 s · Baigan
Attach: **bunty-ref.png + set-flat.png**  
- **BUNTY** बैगन… · *Baigan…* · (Damn…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty looking at a plastic chair piled with his own crumpled shirts, face falling.
1–3 s: Bunty's face drops. Static.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "बैगन…" (Baigan…) [meaning: Damn…]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty looking at a plastic chair piled with his own crumpled shirts, face falling.
LAST FRAME: the end of this action: Bunty's face drops. Static.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E5-C10 · 28–31 s · Cliffhanger
Attach: **bunty-ref.png + set-flat.png + props-ref.png**  
On screen (edit): Kal Bunty ka date… aur shirt?  

```text
IronDost reel 'Dost Undi Ga!' · Ep 5 · E5-C10 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Over-the-shoulder from Bunty toward the open almirah where the crisp navy checked shirt hangs alone in a beam of light.
1–3 s: Slow push-in toward the shirt as Bunty's eyes slide to it; freeze.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Sneaky pizzicato. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Over-the-shoulder from Bunty toward the open almirah where the crisp navy checked shirt hangs alone in a beam of light.
LAST FRAME: the end of this action: Slow push-in toward the shirt as Bunty's eyes slide to it; freeze.

ATTACH: bunty-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```


## Episode 6 / 10 · Dhuvvam (Smoke)
**Hook formula:** Disaster reveal · **Hook:** An iron lifts off a silk kurta and reveals a smoking iron-shaped hole.  
**Hook text on screen (edit):** Silk ni intlo iron chesthe… · **Cliffhanger:** Lucky shirt… missing.  
**Caption:** Ep 6/10 — Silk intlo iron cheyyakandi 🔥😭 Bunty em chesadu?? #DostUndiGa #IronDost #DryCleaning #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep06/`

### E6-C1 · 0–3 s · Burnt kurta
Attach: **bunty-ref.png + set-flat.png + props-ref.png**  
On screen (edit): Silk ni intlo iron chesthe…  
- **BUNTY** या अल्लाह! बैगन! · *Ya Allah! Baigan!* · (Oh God! Damn!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 6 · E6-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
BUNTY's EID KURTA: cream silk kurta (the one that gets the iron-shaped burn in Ep 6).

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Close-up of a household electric iron lifting off a cream silk kurta on an ironing board, revealing a black iron-shaped burnt hole with smoke curling up; Bunty's horrified face behind.
1–3 s: The iron lifts, smoke rises from the hole, Bunty's eyes go wide.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "या अल्लाह! बैगन!" (Ya Allah! Baigan!) [meaning: Oh God! Damn!]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Sizzle at 0.0 s, smoke alarm beep. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Close-up of a household electric iron lifting off a cream silk kurta on an ironing board, revealing a black iron-shaped burnt hole with smoke curling up; Bunty's horrified face behind.
LAST FRAME: the end of this action: The iron lifts, smoke rises from the hole, Bunty's eyes go wide.

ATTACH: bunty-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E6-C2 · 3–6 s · Ravi rushes in
Attach: **ravi-ref.png + bunty-ref.png + set-flat.png**  
- **RAVI** సిల్క్ ని ఇంట్లో ఐరన్ చేస్తారా రా?! · *Silk ni intlo iron chestara ra?!* · (Who irons silk at home?!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 6 · E6-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi running into the room fanning smoke away with a folded newspaper, Bunty frozen holding the iron.
1–3 s: Ravi fans the smoke frantically.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "సిల్క్ ని ఇంట్లో ఐరన్ చేస్తారా రా?!" (Silk ni intlo iron chestara ra?!) [meaning: Who irons silk at home?!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: BUNTY keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi running into the room fanning smoke away with a folded newspaper, Bunty frozen holding the iron.
LAST FRAME: the end of this action: Ravi fans the smoke frantically.

ATTACH: ravi-ref.png + bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E6-C3 · 6–10 s · The hole
Attach: **bunty-ref.png + set-flat.png + props-ref.png**  
- **BUNTY** अम्मी ने ईद पे दिया था… · *Ammi ne Eid pe diya tha…* · (Mum gave it to me for Eid…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 6 · E6-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
BUNTY's EID KURTA: cream silk kurta (the one that gets the iron-shaped burn in Ep 6).

SHOT, SECOND BY SECOND:
0–1 s: Bunty holding the burnt cream silk kurta up in front of his face, one sad eye visible through the iron-shaped hole.
1–4 s: Bunty lowers the kurta slowly, lip trembling.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "अम्मी ने ईद पे दिया था…" (Ammi ne Eid pe diya tha…) [meaning: Mum gave it to me for Eid…]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty holding the burnt cream silk kurta up in front of his face, one sad eye visible through the iron-shaped hole.
LAST FRAME: the end of this action: Bunty lowers the kurta slowly, lip trembling.

ATTACH: bunty-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E6-C4 · 10–14 s · Ravi explains
Attach: **ravi-ref.png + bunty-ref.png + set-flat.png**  
- **RAVI** సిల్క్, పట్టు — ఇవి డ్రై క్లీనింగ్ కి ఇవ్వాలి. పెద్ద మెషీన్లు, కరెక్ట్ హీట్. · *Silk, pattu — ivi dry cleaning ki ivvali. Pedda machines, correct heat.* · (Silk and pattu go for dry cleaning. Big machines, correct heat.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 6 · E6-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi holding his phone out toward Bunty, explaining patiently; Bunty sulking.
1–4 s: Ravi points at the phone screen (screen faces away from camera).
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "సిల్క్, పట్టు — ఇవి డ్రై క్లీనింగ్ కి ఇవ్వాలి. పెద్ద మెషీన్లు, కరెక్ట్ హీట్." (Silk, pattu — ivi dry cleaning ki ivvali. Pedda machines, correct heat.) [meaning: Silk and pattu go for dry cleaning. Big machines, correct heat.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: BUNTY keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi holding his phone out toward Bunty, explaining patiently; Bunty sulking.
LAST FRAME: the end of this action: Ravi points at the phone screen (screen faces away from camera).

ATTACH: ravi-ref.png + bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E6-C5 · 14–18 s · Dry cleaning in the app
**Real clip, no AI.** REAL: screen-record catalogue → Dry Cleaning, with 'Silk saree ₹250' visible.  
Motion in the edit: Real screen recording.  

### E6-C6 · 18–21 s · Sulk
Attach: **bunty-ref.png + set-flat.png + props-ref.png**  
- **BUNTY** अब बोल के क्या फ़ायदा. · *Ab bolke kya faida.* · (No point telling me now.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 6 · E6-C6 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
BUNTY's EID KURTA: cream silk kurta (the one that gets the iron-shaped burn in Ep 6).

SHOT, SECOND BY SECOND:
0–1 s: Bunty slumped on the sofa hugging the burnt kurta, pouting.
1–3 s: Bunty sighs dramatically.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "अब बोल के क्या फ़ायदा." (Ab bolke kya faida.) [meaning: No point telling me now.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty slumped on the sofa hugging the burnt kurta, pouting.
LAST FRAME: the end of this action: Bunty sighs dramatically.

ATTACH: bunty-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E6-C7 · 21–25 s · Night theft
Attach: **bunty-ref.png + ravi-ref.png + set-flat.png**  
- **BUNTY** सिर्फ़ एक दिन, भाई… सॉरी. · *Sirf ek din, bhai… sorry.* · (Just one day, bro… sorry.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 6 · E6-C7 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Night, blue moonlight through the window grills: Ravi asleep on the bed in the background; Bunty tiptoeing from the almirah holding the navy checked shirt, finger on his lips, looking straight at the camera.
1–4 s: Bunty tiptoes forward and puts a finger on his lips to the camera.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "सिर्फ़ एक दिन, भाई… सॉरी." (Sirf ek din, bhai… sorry.) [meaning: Just one day, bro… sorry.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Cartoon tiptoe. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Night, blue moonlight through the window grills: Ravi asleep on the bed in the background; Bunty tiptoeing from the almirah holding the navy checked shirt, finger on his lips, looking straight at the camera.
LAST FRAME: the end of this action: Bunty tiptoes forward and puts a finger on his lips to the camera.

ATTACH: bunty-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E6-C8 · 25–28 s · Cliffhanger
Attach: **set-flat.png**  
On screen (edit): Lucky shirt… missing.  

```text
IronDost reel 'Dost Undi Ga!' · Ep 6 · E6-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Inside the almirah: an empty hanger gently swinging where a shirt used to be, in dim blue light.
1–3 s: The empty hanger swings; the almirah door closes on it; freeze.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Door click, sting. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Inside the almirah: an empty hanger gently swinging where a shirt used to be, in dim blue light.
LAST FRAME: the end of this action: The empty hanger swings; the almirah door closes on it; freeze.

ATTACH: set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```


## Episode 7 / 10 · Biryani (Biryani)
**Hook formula:** Slow-motion disaster · **Hook:** A spoon of red salan falls in slow motion onto the lucky shirt.  
**Hook text on screen (edit):** Lucky shirt. Biryani. Date night. · **Cliffhanger:** Bunty ki idea vachindi…  
**Caption:** Ep 7/10 — Lucky shirt pai biryani 😭 Engagement ki 2 rojule! Comment: Bunty ni kshaminchala? 👇 #DostUndiGa #IronDost #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep07/`

### E7-C1 · 0–3 s · The drop
Attach: **bunty-ref.png + set-restaurant.png**  
On screen (edit): Lucky shirt. Biryani. Date night.  
- **BUNTY** नक्को…! · *Nakkooo…!* · (Nooo…!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a busy Hyderabadi biryani restaurant at night: warm yellow lights, steel plates, a table for two with a copper handi of biryani and a bowl of mirchi ka salan. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Ultra macro slow motion: a spoonful of red-orange mirchi ka salan gravy falling toward the chest of a navy-blue shirt with thin white checks worn by Bunty; restaurant lights blurred behind.
1–3 s: The gravy falls in super slow motion and splashes onto the shirt.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "नक्को…!" (Nakkooo…!) [meaning: Nooo…!]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Total silence, then splat. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ultra macro slow motion: a spoonful of red-orange mirchi ka salan gravy falling toward the chest of a navy-blue shirt with thin white checks worn by Bunty; restaurant lights blurred behind.
LAST FRAME: the end of this action: The gravy falls in super slow motion and splashes onto the shirt.

ATTACH: bunty-ref.png + set-restaurant.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E7-C2 · 3–7 s · It's a design
Attach: **bunty-ref.png + set-restaurant.png + props-ref.png**  
- **BUNTY** ये… डिज़ाइन है. · *Ye… design hai.* · (This is… a design.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a busy Hyderabadi biryani restaurant at night: warm yellow lights, steel plates, a table for two with a copper handi of biryani and a bowl of mirchi ka salan. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Bunty at a restaurant table for two wearing the navy checked shirt with a big orange stain on the chest, forcing a smile and covering it with a paper napkin.
1–4 s: Bunty dabs the stain and grins awkwardly at someone off-camera.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "ये… डिज़ाइन है." (Ye… design hai.) [meaning: This is… a design.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty at a restaurant table for two wearing the navy checked shirt with a big orange stain on the chest, forcing a smile and covering it with a paper napkin.
LAST FRAME: the end of this action: Bunty dabs the stain and grins awkwardly at someone off-camera.

ATTACH: bunty-ref.png + set-restaurant.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E7-C3 · 7–11 s · Ravi finds it
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
- **RAVI** రా బంటీ…!! · *Ra Buntyyy!!* · (Buntyyy!!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Next morning: Ravi holding the stained navy checked shirt up against the window light, furious, veins on his forehead.
1–4 s: Ravi lifts the shirt and his face turns red.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "రా బంటీ…!!" (Ra Buntyyy!!) [meaning: Buntyyy!!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Dramatic zoom sound. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Next morning: Ravi holding the stained navy checked shirt up against the window light, furious, veins on his forehead.
LAST FRAME: the end of this action: Ravi lifts the shirt and his face turns red.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E7-C4 · 11–14 s · Sorry
Attach: **bunty-ref.png + set-flat.png**  
- **BUNTY** भाई, माफ़ कर. एकदम दिल से. · *Bhai, maaf kar. Ek dum dil se.* · (Bro, forgive me. From my heart.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty on his knees on the floor with hands joined in apology, big puppy eyes.
1–3 s: Bunty shuffles forward on his knees.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "भाई, माफ़ कर. एकदम दिल से." (Bhai, maaf kar. Ek dum dil se.) [meaning: Bro, forgive me. From my heart.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty on his knees on the floor with hands joined in apology, big puppy eyes.
LAST FRAME: the end of this action: Bunty shuffles forward on his knees.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E7-C5 · 14–18 s · Amma calls
Attach: **ravi-ref.png + set-flat.png**  
- **AMMA (voice)** పార్సెల్ వచ్చిందా? ఎంగేజ్‌మెంట్ ఎల్లుండి! నా పట్టు చీర, నాన్న పంచ, నీ లక్కీ షర్ట్ — అన్నీ రెడీ నా? · *Parcel vachinda? Engagement ellundi! Naa pattu cheera, naanna pancha, nee lucky shirt — anni ready na?* · (Did the parcel come? The engagement is the day after tomorrow! My silk saree, Dad's dhoti, your lucky shirt — all ready?)

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi on the phone, stained shirt in his other hand, eyes wide.
1–4 s: Ravi listens and slowly sits down.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
AMMA (Ravi's mother, about 55, warm Telugu voice, on the phone or off screen): "పార్సెల్ వచ్చిందా? ఎంగేజ్‌మెంట్ ఎల్లుండి! నా పట్టు చీర, నాన్న పంచ, నీ లక్కీ షర్ట్ — అన్నీ రెడీ నా?" (Parcel vachinda? Engagement ellundi! Naa pattu cheera, naanna pancha, nee lucky shirt — anni ready na?) [meaning: Did the parcel come? The engagement is the day after tomorrow! My silk saree, Dad's dhoti, your lucky shirt — all ready?]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi on the phone, stained shirt in his other hand, eyes wide.
LAST FRAME: the end of this action: Ravi listens and slowly sits down.

ATTACH: ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E7-C6 · 18–22 s · Amma's parcel
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C6 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Ravi opening a wet cardboard parcel on the floor: a maroon Kanchipuram pattu saree with a gold zari border and a cream silk pancha, both badly crushed with water marks.
1–4 s: The flaps open to reveal the crushed silks; Ravi's face falls.
4–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Low cello note. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi opening a wet cardboard parcel on the floor: a maroon Kanchipuram pattu saree with a gold zari border and a cream silk pancha, both badly crushed with water marks.
LAST FRAME: the end of this action: The flaps open to reveal the crushed silks; Ravi's face falls.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E7-C7 · 22–25 s · Defeated
Attach: **ravi-ref.png + set-flat.png**  
- **RAVI** ఎల్లుండి… అన్నీ ఎల్లుండి… · *Ellundi… anni ellundi…* · (The day after tomorrow… everything by then…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C7 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi sitting on the floor among the clothes, head in his hands.
1–3 s: Ravi drops his head into his hands. Slow pull-back.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "ఎల్లుండి… అన్నీ ఎల్లుండి…" (Ellundi… anni ellundi…) [meaning: The day after tomorrow… everything by then…]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi sitting on the floor among the clothes, head in his hands.
LAST FRAME: the end of this action: Ravi drops his head into his hands. Slow pull-back.

ATTACH: ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E7-C8 · 25–28 s · Cliffhanger
Attach: **bunty-ref.png + set-flat.png**  
On screen (edit): Bunty ki idea vachindi…  

```text
IronDost reel 'Dost Undi Ga!' · Ep 7 · E7-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty slowly raising his phone in the foreground, screen glow lighting his determined face, Ravi blurred behind.
1–3 s: Bunty raises the phone and a small smile appears; freeze.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Idea 'ding'. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty slowly raising his phone in the foreground, screen glow lighting his determined face, Ravi blurred behind.
LAST FRAME: the end of this action: Bunty raises the phone and a small smile appears; freeze.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```


## Episode 8 / 10 · Express (Express)
**Hook formula:** Countdown + high stakes · **Hook:** Bunty slams the table and a red 06:00:00 countdown starts.  
**Hook text on screen (edit):** 06:00:00 · **Cliffhanger:** Time saripotunda…?  
**Caption:** Ep 8/10 — 6 gantallo Express ⚡ double price, kaani tension zero. Call/WhatsApp 79934 34932 #DostUndiGa #IronDost #ExpressLaundry #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep08/`

### E8-C1 · 0–3 s · The slam
Attach: **bunty-ref.png + set-flat.png**  
On screen (edit): Big red countdown 06:00:00 (add in edit)  
- **BUNTY** एक्सप्रेस! छह घंटे में! · *Express! 6 ghante mein!* · (Express! In 6 hours!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Bunty slamming his palm on the dining table, phone in his other hand, intense determined face, low angle.
1–3 s: Bunty's palm hits the table, things jump, he leans into the lens.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "एक्सप्रेस! छह घंटे में!" (Express! 6 ghante mein!) [meaning: Express! In 6 hours!]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Table slam at 0.0 s, clock ticking starts. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty slamming his palm on the dining table, phone in his other hand, intense determined face, low angle.
LAST FRAME: the end of this action: Bunty's palm hits the table, things jump, he leans into the lens.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E8-C2 · 3–6 s · Ravi panics
Attach: **ravi-ref.png + set-flat.png + props-ref.png**  
- **RAVI** ఐరనింగ్ కి రెండు రోజులు, లాండ్రీ కి మూడు కదా? · *Ironing ki rendu rojulu, laundry ki moodu kada?* · (Isn't ironing two days, laundry three?)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Ravi in panic, hands on his head, surrounded by the crushed silk saree and stained shirt.
1–3 s: Ravi grips his head.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "ఐరనింగ్ కి రెండు రోజులు, లాండ్రీ కి మూడు కదా?" (Ironing ki rendu rojulu, laundry ki moodu kada?) [meaning: Isn't ironing two days, laundry three?]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi in panic, hands on his head, surrounded by the crushed silk saree and stained shirt.
LAST FRAME: the end of this action: Ravi grips his head.

ATTACH: ravi-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E8-C3 · 6–10 s · Bunty explains
Attach: **bunty-ref.png + set-flat.png**  
On screen (edit): Express = 6 hours  
- **BUNTY** नॉर्मल में, हौ. लेकिन एक्सप्रेस है — छह घंटे. · *Normal mein, hau. Lekin Express hai — 6 ghante.* · (Normally, yes. But there's Express — 6 hours.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty, confident for the first time, raising one finger like a professor.
1–4 s: Bunty raises his finger and smirks.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "नॉर्मल में, हौ. लेकिन एक्सप्रेस है — छह घंटे." (Normal mein, hau. Lekin Express hai — 6 ghante.) [meaning: Normally, yes. But there's Express — 6 hours.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty, confident for the first time, raising one finger like a professor.
LAST FRAME: the end of this action: Bunty raises his finger and smirks.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E8-C4 · 10–14 s · The call
Attach: **bunty-ref.png + set-flat.png**  
On screen (edit): Show dialled number 79934 34932 in edit  
- **BUNTY** हेलो, आयरन दोस्त? एक्सप्रेस चाहिए, इमरजेंसी है! · *Hello, IronDost? Express chahiye, emergency hai!* · (Hello, IronDost? Need Express, it's an emergency!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty holding the phone to his ear, pacing, urgent expression.
1–4 s: Bunty paces and talks fast.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "हेलो, आयरन दोस्त? एक्सप्रेस चाहिए, इमरजेंसी है!" (Hello, IronDost? Express chahiye, emergency hai!) [meaning: Hello, IronDost? Need Express, it's an emergency!]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Dial tone. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty holding the phone to his ear, pacing, urgent expression.
LAST FRAME: the end of this action: Bunty paces and talks fast.

ATTACH: bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E8-C5 · 14–18 s · Dost answers
Attach: **dost-ref.png + set-unit.png**  
- **DOST** ఎక్స్‌ప్రెస్ — ఆరు గంటల్లో, డబుల్ ప్రైస్ సర్. పన్నెండున్నరకి పికప్. · *Express — 6 gantallo, double price sir. 12:30 ki pickup.* · (Express — in 6 hours, double the price, sir. Pickup at 12:30.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost at the IronDost unit on the phone, calm, a steam press puffing behind him.
1–4 s: Dost speaks calmly, steam rises behind.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "ఎక్స్‌ప్రెస్ — ఆరు గంటల్లో, డబుల్ ప్రైస్ సర్. పన్నెండున్నరకి పికప్." (Express — 6 gantallo, double price sir. 12:30 ki pickup.) [meaning: Express — in 6 hours, double the price, sir. Pickup at 12:30.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost at the IronDost unit on the phone, calm, a steam press puffing behind him.
LAST FRAME: the end of this action: Dost speaks calmly, steam rises behind.

ATTACH: dost-ref.png + set-unit.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E8-C6 · 18–23 s · The honest bill
**Real clip, no AI.** EDIT GRAPHIC: list — Kanchi pattu saree, pancha, lucky shirt, kurta-pyjama → 'Express = 2× price' → '₹500+ → 10% OFF (DOST10)'.  
Motion in the edit: Items pop in one by one in CapCut.  
On screen: Express = 2× price · ₹500+ → 10% OFF · DOST10  
Sound: Pop pop pop  

### E8-C7 · 23–26 s · Bunty pays
Attach: **bunty-ref.png + ravi-ref.png + set-flat.png**  
- **BUNTY** बिल मेरा. ग़लती मेरी थी. · *Bill mera. Galti meri thi.* · (The bill's on me. It was my fault.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C7 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty pressing his wallet into Ravi's hand, serious face.
1–3 s: Bunty pushes the wallet into Ravi's palm and closes his fingers over it.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "बिल मेरा. ग़लती मेरी थी." (Bill mera. Galti meri thi.) [meaning: The bill's on me. It was my fault.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty pressing his wallet into Ravi's hand, serious face.
LAST FRAME: the end of this action: Bunty pushes the wallet into Ravi's palm and closes his fingers over it.

ATTACH: bunty-ref.png + ravi-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E8-C8 · 26–29 s · The hug
Attach: **ravi-ref.png + bunty-ref.png + set-flat.png**  
- **RAVI** నువ్వు పిచ్చోడివి రా. · *Nuvvu pichhodivi ra.* · (You're crazy.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi hugging Bunty tightly, Bunty surprised, both laughing.
1–3 s: Ravi pulls Bunty into a hug.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "నువ్వు పిచ్చోడివి రా." (Nuvvu pichhodivi ra.) [meaning: You're crazy.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: BUNTY keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi hugging Bunty tightly, Bunty surprised, both laughing.
LAST FRAME: the end of this action: Ravi pulls Bunty into a hug.

ATTACH: ravi-ref.png + bunty-ref.png + set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E8-C9 · 29–33 s · Express pickup
Attach: **dost-ref.png + set-flat.png + props-ref.png**  
- **DOST** చీర కోసం స్టీమ్ ప్రెస్, స్టెయిన్ కోసం స్పెషల్ వాష్. ఆరున్నర లోపు మీరు ఫంక్షన్ హాల్ లో. · *Saree kosam steam press, stain kosam special wash. 6:30 lopu meeru function hall lo.* · (Steam press for the saree, special wash for the stain. You'll have them at the function hall before 6:30.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Dost at the door folding the maroon Kanchi pattu saree carefully in white tissue paper into a royal-blue garment bag; wall clock behind shows 12:30.
1–4 s: Dost folds the tissue over the saree gently.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "చీర కోసం స్టీమ్ ప్రెస్, స్టెయిన్ కోసం స్పెషల్ వాష్. ఆరున్నర లోపు మీరు ఫంక్షన్ హాల్ లో." (Saree kosam steam press, stain kosam special wash. 6:30 lopu meeru function hall lo.) [meaning: Steam press for the saree, special wash for the stain. You'll have them at the function hall before 6:30.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost at the door folding the maroon Kanchi pattu saree carefully in white tissue paper into a royal-blue garment bag; wall clock behind shows 12:30.
LAST FRAME: the end of this action: Dost folds the tissue over the saree gently.

ATTACH: dost-ref.png + set-flat.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E8-C10 · 33–36 s · Cliffhanger
Attach: **set-flat.png**  
On screen (edit): 05:59:59 — Time saripotunda…?  

```text
IronDost reel 'Dost Undi Ga!' · Ep 8 · E8-C10 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Close-up of the round wall clock reading 12:31.
1–3 s: The second hand ticks; freeze.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Loud tick. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Close-up of the round wall clock reading 12:31.
LAST FRAME: the end of this action: The second hand ticks; freeze.

ATTACH: set-flat.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```


## Episode 9 / 10 · Countdown (Countdown)
**Hook formula:** Chaos + ticking clock · **Hook:** Ravi hides behind a marigold pillar in just a vest while Amma shouts his name.  
**Hook text on screen (edit):** Function 7 ki. Battalu: inka raaledu. · **Cliffhanger:** Divya ki em ayyindi…?  
**Caption:** Ep 9/10 — 6:25 ki delivery, 7 ki function ⏰ Repu finale! #DostUndiGa #IronDost #Hyderabad  
**Save in:** `videos/dost-undi-ga/ep09/`

### E9-C1 · 0–3 s · Hiding
Attach: **ravi-ref.png + set-hall.png**  
On screen (edit): Function 7 ki. Battalu: inka raaledu.  
- **AMMA (voice)** రవీ ఎక్కడ?! · *Ravi ekkada?!* · (Where's Ravi?!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Ravi in just a grey vest and white-and-blue checked lungi hiding behind a marigold-wrapped pillar in a decorated function hall, nadaswaram musicians blurred behind, a wall clock showing 6:15.
1–3 s: Ravi presses himself against the pillar as a voice calls; his eyes dart left and right.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
AMMA (Ravi's mother, about 55, warm Telugu voice, on the phone or off screen): "రవీ ఎక్కడ?!" (Ravi ekkada?!) [meaning: Where's Ravi?!]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Nadaswaram blast at 0.0 s. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi in just a grey vest and white-and-blue checked lungi hiding behind a marigold-wrapped pillar in a decorated function hall, nadaswaram musicians blurred behind, a wall clock showing 6:15.
LAST FRAME: the end of this action: Ravi presses himself against the pillar as a voice calls; his eyes dart left and right.

ATTACH: ravi-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E9-C2 · 3–6 s · Peeking
Attach: **ravi-ref.png + set-hall.png + props-ref.png**  
- **RAVI** రాలేదు రా… · *Raaledu ra…* · (He's not here yet…)

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Ravi peeking out from behind the pillar at relatives in silk sarees and veshtis.
1–3 s: Ravi leans out, sees the crowd, ducks back.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "రాలేదు రా…" (Raaledu ra…) [meaning: He's not here yet…]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi peeking out from behind the pillar at relatives in silk sarees and veshtis.
LAST FRAME: the end of this action: Ravi leans out, sees the crowd, ducks back.

ATTACH: ravi-ref.png + set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E9-C3 · 6–9 s · Bunty's calm
Attach: **bunty-ref.png + set-hall.png**  
- **BUNTY** आएगा. दोस्त है ना. · *Aayega. Dost hai na.* · (He'll come. Dost is here.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty also in a white vest behind the same pillar, calmly eating mirchi bajji from a paper plate.
1–3 s: Bunty bites a bajji and shrugs.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "आएगा. दोस्त है ना." (Aayega. Dost hai na.) [meaning: He'll come. Dost is here.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty also in a white vest behind the same pillar, calmly eating mirchi bajji from a paper plate.
LAST FRAME: the end of this action: Bunty bites a bajji and shrugs.

ATTACH: bunty-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E9-C4 · 9–13 s · Out for delivery
**Real clip, no AI.** REAL: screen-record the order timeline showing 'Out for delivery'.  
Motion in the edit: Real screen recording.  
Sound: Ping  

### E9-C5 · 13–17 s · The arrival
Attach: **dost-ref.png + set-hall.png**  

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost riding a scooter through a marigold-decorated entrance arch of the function hall at dusk, royal-blue garment bags over his shoulder.
1–4 s: The scooter pulls in and stops; music builds. Low tracking shot.
4–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Scooter, music swell. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost riding a scooter through a marigold-decorated entrance arch of the function hall at dusk, royal-blue garment bags over his shoulder.
LAST FRAME: the end of this action: The scooter pulls in and stops; music builds. Low tracking shot.

ATTACH: dost-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E9-C6 · 17–21 s · On time
Attach: **dost-ref.png + set-hall.png**  
On screen (edit): 6:25 PM  
- **DOST** సర్, చెప్పిన టైమ్ లోపల. · *Sir, cheppina time lopala.* · (Sir, within the promised time.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C6 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost walking in with garment bags, glancing at his wristwatch, calm smile.
1–4 s: Dost checks his watch and smiles.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DOST: "సర్, చెప్పిన టైమ్ లోపల." (Sir, cheppina time lopala.) [meaning: Sir, within the promised time.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost walking in with garment bags, glancing at his wristwatch, calm smile.
LAST FRAME: the end of this action: Dost checks his watch and smiles.

ATTACH: dost-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E9-C7 · 21–25 s · Stain gone
Attach: **ravi-ref.png + set-hall.png + props-ref.png**  
- **RAVI** స్టెయిన్… లేదు! · *Stain… ledu!* · (The stain… is gone!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C7 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.

SHOT, SECOND BY SECOND:
0–1 s: Ravi unzipping a royal-blue garment bag to reveal the navy checked shirt perfectly clean and ironed.
1–4 s: The zip opens; Ravi's jaw drops with joy.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "స్టెయిన్… లేదు!" (Stain… ledu!) [meaning: The stain… is gone!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi unzipping a royal-blue garment bag to reveal the navy checked shirt perfectly clean and ironed.
LAST FRAME: the end of this action: The zip opens; Ravi's jaw drops with joy.

ATTACH: ravi-ref.png + set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E9-C8 · 25–28 s · Like new
Attach: **bunty-ref.png + set-hall.png + props-ref.png**  
- **BUNTY** या अल्लाह, नया जैसा! · *Ya Allah, naya jaisa!* · (Oh God, like new!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
BUNTY's EID KURTA: cream silk kurta (the one that gets the iron-shaped burn in Ep 6).

SHOT, SECOND BY SECOND:
0–1 s: Bunty holding up a crisp white kurta-pyjama on a hanger and kissing it.
1–3 s: Bunty kisses the kurta dramatically.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "या अल्लाह, नया जैसा!" (Ya Allah, naya jaisa!) [meaning: Oh God, like new!]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty holding up a crisp white kurta-pyjama on a hanger and kissing it.
LAST FRAME: the end of this action: Bunty kisses the kurta dramatically.

ATTACH: bunty-ref.png + set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E9-C9 · 28–31 s · Saree handed in
Attach: **dost-ref.png + set-hall.png**  

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost handing a royal-blue garment bag through a half-open door to a woman's hand with gold bangles and mehendi.
1–3 s: The hand takes the bag and the door closes.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost handing a royal-blue garment bag through a half-open door to a woman's hand with gold bangles and mehendi.
LAST FRAME: the end of this action: The hand takes the bag and the door closes.

ATTACH: dost-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E9-C10 · 31–33 s · Cliffhanger
Attach: **set-hall.png**  
On screen (edit): Divya ki em ayyindi…?  
- **DIVYA (voice)** హాఆ…! · *Haaa…!* · ((a loud gasp))

```text
IronDost reel 'Dost Undi Ga!' · Ep 9 · E9-C10 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: The closed door of the bridal room decorated with a jasmine garland.
1–2 s: Hold on the door; freeze.
2–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–2 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 1.5 s; each line said exactly once; nothing is said after the last line):
DIVYA (Ravi's younger sister, about 24, off screen): "హాఆ…!" (Haaa…!) [meaning: (a loud gasp)]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.

SOUND: Gasp, sting. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: The closed door of the bridal room decorated with a jasmine garland.
LAST FRAME: the end of this action: Hold on the door; freeze.

ATTACH: set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```


## Episode 10 / 10 · Nischitartham (The Engagement)
**Hook formula:** Hero slow-motion payoff · **Hook:** Ravi and Bunty walk toward the camera in slow motion through falling jasmine.  
**Hook text on screen (edit):** FINALE · **Cliffhanger:** Bhai… Season 2.  
**Caption:** Ep 10/10 FINALE 🎉 Divya engagement, Bunty sorry, Dost hero. Season 2 kavala? Comment 'S2' 👇 Call/WhatsApp 79934 34932 #DostUndiGa #IronDost #Hyderabad #Telugu  
**Save in:** `videos/dost-undi-ga/ep10/`

### E10-C1 · 0–4 s · Hero walk
Attach: **ravi-ref.png + bunty-ref.png + set-hall.png**  
On screen (edit): FINALE  
- **BUNTY** भाई… हीरो लग रहे हम. · *Bhai… hero lag rahe hum.* · (Bro… we look like heroes.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C1 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.
BUNTY's EID KURTA: cream silk kurta (the one that gets the iron-shaped burn in Ep 6).

SHOT, SECOND BY SECOND:
0–1 s: Frame 1 is already moving, with a sound hit at 0.0 s. Ravi in a cream silk pancha with a gold border and the crisp navy checked shirt, Bunty beside him in a crisp white kurta-pyjama, walking toward the camera in the function hall, jasmine petals falling, warm fairy lights.
1–4 s: Slow-motion walk toward the lens, petals falling, slight low angle.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: Starts mid-action on the first frame, one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "भाई… हीरो लग रहे हम." (Bhai… hero lag rahe hum.) [meaning: Bro… we look like heroes.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Big beat drop at 0.0 s. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi in a cream silk pancha with a gold border and the crisp navy checked shirt, Bunty beside him in a crisp white kurta-pyjama, walking toward the camera in the function hall, jasmine petals falling, warm fairy lights.
LAST FRAME: the end of this action: Slow-motion walk toward the lens, petals falling, slight low angle.

ATTACH: ravi-ref.png + bunty-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E10-C2 · 4–8 s · The saree
Attach: **set-hall.png + props-ref.png**  
- **DIVYA (voice)** అమ్మా! కొత్త చీర లాగ ఉంది! · *Amma! Kotha cheera laga undi!* · (Mummy! It looks like a new saree!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C2 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Wide shot from behind of a young bride (Divya) in a maroon Kanchipuram pattu saree with a shining gold zari border, perfect pleats, standing at a mirror (her face soft and out of focus).
1–4 s: She turns slightly and the zari catches the light.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
DIVYA (Ravi's younger sister, about 24, off screen): "అమ్మా! కొత్త చీర లాగ ఉంది!" (Amma! Kotha cheera laga undi!) [meaning: Mummy! It looks like a new saree!]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Wide shot from behind of a young bride (Divya) in a maroon Kanchipuram pattu saree with a shining gold zari border, perfect pleats, standing at a mirror (her face soft and out of focus).
LAST FRAME: the end of this action: She turns slightly and the zari catches the light.

ATTACH: set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E10-C3 · 8–12 s · Amma's blessing
Attach: **ravi-ref.png + set-hall.png + props-ref.png**  
- **AMMA (voice)** బాగా చేశావ్ రా. · *Baga chesav ra.* · (You did well, dear.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C3 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Over-the-shoulder from an older woman in a silk saree (only her shoulder and bun with jasmine visible) toward Ravi, who smiles shyly.
1–4 s: Ravi smiles shyly and looks down.
4–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 3.5 s; each line said exactly once; nothing is said after the last line):
AMMA (Ravi's mother, about 55, warm Telugu voice, on the phone or off screen): "బాగా చేశావ్ రా." (Baga chesav ra.) [meaning: You did well, dear.]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Over-the-shoulder from an older woman in a silk saree (only her shoulder and bun with jasmine visible) toward Ravi, who smiles shyly.
LAST FRAME: the end of this action: Ravi smiles shyly and looks down.

ATTACH: ravi-ref.png + set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E10-C4 · 12–15 s · Credit
Attach: **ravi-ref.png + bunty-ref.png + set-hall.png**  
- **RAVI** కాదు అమ్మా, బంటీ అండ్ దోస్త్. · *Kaadu Amma, Bunty and Dost.* · (Not me, Mummy — Bunty and Dost.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C4 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Ravi pointing at Bunty beside him, Bunty looking embarrassed.
1–3 s: Ravi points, Bunty scratches his head.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "కాదు అమ్మా, బంటీ అండ్ దోస్త్." (Kaadu Amma, Bunty and Dost.) [meaning: Not me, Mummy — Bunty and Dost.]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.
Listening: BUNTY keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi pointing at Bunty beside him, Bunty looking embarrassed.
LAST FRAME: the end of this action: Ravi points, Bunty scratches his head.

ATTACH: ravi-ref.png + bunty-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E10-C5 · 15–18 s · Bunty's apology
Attach: **bunty-ref.png + set-hall.png + props-ref.png**  
- **BUNTY** आंटी, ग़लती मेरी थी, दोस्त ने बचा लिया. · *Aunty, galti meri thi, Dost ne bacha liya.* · (Aunty, the mistake was mine, Dost saved us.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C5 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Bunty bending to touch the feet of an older woman in a silk saree (framed from the waist down).
1–3 s: Bunty bends and touches her feet; her hand rests on his head.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "आंटी, ग़लती मेरी थी, दोस्त ने बचा लिया." (Aunty, galti meri thi, Dost ne bacha liya.) [meaning: Aunty, the mistake was mine, Dost saved us.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty bending to touch the feet of an older woman in a silk saree (framed from the waist down).
LAST FRAME: the end of this action: Bunty bends and touches her feet; her hand rests on his head.

ATTACH: bunty-ref.png + set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

### E10-C6 · 18–21 s · Stay for food
Attach: **dost-ref.png + set-hall.png**  
- **AMMA (voice)** బాబూ! భోజనం చేసి వెళ్ళు. · *Babu! Bhojanam chesi vellu.* · (Son! Eat before you go.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C6 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost walking quietly toward the hall exit with folded empty garment bags.
1–3 s: Dost stops and turns back, surprised.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
AMMA (Ravi's mother, about 55, warm Telugu voice, on the phone or off screen): "బాబూ! భోజనం చేసి వెళ్ళు." (Babu! Bhojanam chesi vellu.) [meaning: Son! Eat before you go.]  — spoken in Telugu, natural Hyderabad accent, voice only, off screen: nobody on screen moves their lips.
Listening: DOST keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost walking quietly toward the hall exit with folded empty garment bags.
LAST FRAME: the end of this action: Dost stops and turns back, surprised.

ATTACH: dost-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot
```

### E10-C7 · 21–25 s · Banana-leaf meal
Attach: **dost-ref.png + ravi-ref.png + bunty-ref.png**  

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C7 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Dost, Ravi and Bunty sitting together at a long table eating a South Indian meal on banana leaves, laughing.
1–4 s: All three laugh as Bunty serves Dost more rice.
4–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–4 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Music swells. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Dost, Ravi and Bunty sitting together at a long table eating a South Indian meal on banana leaves, laughing.
LAST FRAME: the end of this action: All three laugh as Bunty serves Dost more rice.

ATTACH: dost-ref.png + ravi-ref.png + bunty-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow
```

### E10-C8 · 25–28 s · The ring
Attach: **set-hall.png + props-ref.png**  

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C8 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS: none on screen except hands or bodies described in the shot; no faces.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RING BOX: small red velvet ring box.

SHOT, SECOND BY SECOND:
0–1 s: Close-up on the stage: hands opening the small red velvet ring box from Ep 2, a gold ring sparkling under warm lights.
1–3 s: The box opens and the ring sparkles.
3–8 s: Hold the same moment with a slow camera drift, no new action. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE: none. Nobody speaks.

SOUND: Applause. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Close-up on the stage: hands opening the small red velvet ring box from Ep 2, a gold ring sparkling under warm lights.
LAST FRAME: the end of this action: The box opens and the ring sparkles.

ATTACH: set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, BUNTY appearing in the shot, DOST appearing in the shot
```

### E10-C9 · 28–31 s · Ravi's tagline
Attach: **ravi-ref.png + set-hall.png + props-ref.png**  
- **RAVI** బట్టల టెన్షన్? ఐరన్ దోస్త్ ఉంది గా! · *Battala tension? IronDost undi ga!* · (Clothes tension? IronDost is here!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C9 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.
RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.
THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.

SHOT, SECOND BY SECOND:
0–1 s: Ravi in the pancha and lucky shirt looking straight into the camera with a big confident smile.
1–3 s: Ravi smiles and winks at the lens.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
RAVI: "బట్టల టెన్షన్? ఐరన్ దోస్త్ ఉంది గా!" (Battala tension? IronDost undi ga!) [meaning: Clothes tension? IronDost is here!]  — spoken in Telugu, natural Hyderabad accent, lip-synced, face visible.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Ravi in the pancha and lucky shirt looking straight into the camera with a big confident smile.
LAST FRAME: the end of this action: Ravi smiles and winks at the lens.

ATTACH: ravi-ref.png + set-hall.png + props-ref.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, BUNTY appearing in the shot, DOST appearing in the shot
```

### E10-C10 · 31–34 s · Bunty's tagline
Attach: **bunty-ref.png + ravi-ref.png + set-hall.png**  
- **BUNTY** कपड़ों की टेंशन? दोस्त है ना! · *Kapdon ki tension? Dost hai na!* · (Clothes tension? Dost is here!)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C10 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).
RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty pushing into the frame beside Ravi, cheek to cheek, grinning at the camera.
1–3 s: Bunty squeezes into frame and grins.
3–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–3 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 2.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "कपड़ों की टेंशन? दोस्त है ना!" (Kapdon ki tension? Dost hai na!) [meaning: Clothes tension? Dost is here!]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.
Listening: RAVI keeps their mouth closed while others speak.

SOUND: Natural room sound only. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty pushing into the frame beside Ravi, cheek to cheek, grinning at the camera.
LAST FRAME: the end of this action: Bunty squeezes into frame and grins.

ATTACH: bunty-ref.png + ravi-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, DOST appearing in the shot
```

### E10-C11 · 34–36 s · Season 2 tease (after end card)
Attach: **bunty-ref.png + set-hall.png**  
On screen (edit): Phone mock-up: 'Ayesha 💕: Ammi-Abba ko milna hai. Sunday.'  
- **BUNTY** भाई… सीज़न 2. · *Bhai… Season 2.* · (Bro… Season 2.)

```text
IronDost reel 'Dost Undi Ga!' · Ep 10 · E10-C11 · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on

STYLE:
Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.

CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):
BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).

IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.

SHOT, SECOND BY SECOND:
0–1 s: Bunty looking down at his phone, then up at the camera with a nervous grin.
1–2 s: Bunty looks up from the phone at the lens.
2–8 s: Hold the same moment with a slow camera drift, no new action, no speech. (This tail is trimmed in the edit; the reel uses 0–2 s.)

CAMERA: one continuous shot, no cuts inside the clip; small movements only so faces stay stable.

DIALOGUE (all lines finished by 1.5 s; each line said exactly once; nothing is said after the last line):
BUNTY: "भाई… सीज़न 2." (Bhai… Season 2.) [meaning: Bro… Season 2.]  — spoken in Hyderabadi Hindi (Dakhni), lip-synced, face visible.

SOUND: Comedy sting. No music of any kind: no background score, no humming, no singing.

FIRST FRAME: Bunty looking down at his phone, then up at the camera with a nervous grin.
LAST FRAME: the end of this action: Bunty looks up from the phone at the lens.

ATTACH: bunty-ref.png + set-hall.png  (from videos/dost-undi-ga/refs/)

NEGATIVE PROMPT: background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, a cut to a different room or location, faces changing between shots, different actors, extra people not described, on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, 3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow, RAVI appearing in the shot, DOST appearing in the shot
```

## End card (6 s, layout B)
Two big screens: logo and 'Battala tension? IronDost undi ga!', then Call / WhatsApp 79934 34932 · 70329 90632 with the Play Store and App Store QR codes (QR goes to irondost.in/app). Made in the edit from `videos/dost-undi-ga/endcard-b/`.

## Before episode 1 goes out
- Create code DOST10 in admin and decide whether it applies to Express (Express is booked by phone only).
- Screen-record the real app for the Real clips.
- Generate Ep 1 and check one full take against the rules above before making the rest.