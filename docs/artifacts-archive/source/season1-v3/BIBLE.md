# Dost Undi Ga! Season 1 v3 · writing bible

Rewrite of a 10-episode Telugu/Hyderabadi comedy reel series for IronDost (doorstep ironing and laundry, LB Nagar, Hyderabad). Every clip is AI video. No real footage, no screen recordings.

## Format
- Each episode = exactly **4 clips of 10 seconds** (C1 0–10 s, C2 10–20 s, C3 20–30 s, C4 30–40 s). A 4 s end card (graphics) is laid over C4's last frame in the edit.
- Each clip's beats must cover the full 0–10 s with action, no dead time: 4–6 beats like "0–2 s", "2–4.5 s", ... "8.5–10 s".
- C1 is the hook: frame 1 already in motion, a sound hit at 0.0 s.
- C4 ends on the cliffhanger for the next episode (Ep 10 ends on the Season 2 tease).
- At most 2–3 short dialogue lines per clip, each ≤ 2.5 s spoken. Lines must leave the last 0.5 s silent. Give each line a time window ("at").
- One location per clip. No cuts inside a clip. One continuous camera move.
- Phones always face away from the camera. The app is shown only as a royal-blue glow from the phone. Never show a screen, bill text, prices, logo or any writing: those are edit text (put them in `edit_text`).

## Cast (use these keys)
- RAVI: Telugu man, 28, slim, light stubble, friendly tired eyes. Hero. Speaks Telugu.
- BUNTY: Hyderabadi roommate, 27, round cheerful face, short beard, slightly chubby. Speaks Hyderabadi Hindi (Dakhni). Doubter who becomes a believer; burns his Eid silk kurta in Ep 6, causes the Express emergency, pays the bill.
- DOST: Srinu, IronDost pickup person, 30, neat moustache, calm smile, royal-blue polo with blank chest, black sling bag, plain royal-blue garment bags. Gentle Telugu.
- LUCKY: Ravi's navy-blue checked lucky shirt with a stitched face on the chest below the pocket (thread eyes with white highlights, thread eyebrows, stitched mouth). Never speaks; only expressions and tiny sounds (gasp, whimper, happy sigh). He can be worn by Ravi, on a hanger, folded, or in a bag. His face moves like a Pixar character but stays made of thread on real cloth.
- BHOOTHAM: the Battala Bhootham, a hulking creature made of tangled crumpled dirty clothes (shirts, sarees, towels, socks, lungis) with brownish stains, two glowing amber eyes in the gaps, no teeth, more funny-scary than horror. Appears in Ep 1 (born from the almirah avalanche), Ep 4 (fights Dost at the unit and is beaten by steam), Ep 8 (grows out of the stain on the saree), Ep 10 (a tiny defeated sock-sized version in the tease). Never gory.
- Voice-only (never show a face): AMMA (Ravi's mother, on the phone, or seen from behind with jasmine in her bun), DIVYA (sister, the bride, seen from behind or face out of focus), MANAGER (Ravi's boss, off screen).

## Sets (keys)
FLAT (Nagole 2BHK), UNIT (IronDost laundry unit), HALL (engagement function hall), OFFICE (HITEC City IT office), RESTO (biryani restaurant), BUS (state bus on a wet highway).

## Props (keys)
lucky_shirt (= LUCKY), ring_box (small red velvet ring box), saree (maroon Kanchipuram pattu saree, wide gold zari border), pancha (cream silk dhoti, thin gold border), kurta (Bunty's cream silk Eid kurta), bag (plain royal-blue zip garment bag, no print).

## Facts that must stay true
Laundry 3 days · Ironing 2 days · Express 6 hours at 2× price · ₹500+ gets 10% off with code DOST10 · pickup slots 7–11, 11–4, 4–8 · every pocket checked · loose buttons noted and stitched · care notes read · owner checks every load by hand · silk and pattu go to dry cleaning. Prices and codes only as edit text.

## Story (keep the v1 story; the v1 data is in ep_data.json)
1 Kondalu: clothes avalanche, Amma: 10 days to Divya's engagement, dhobi gone, Amma sends the app, Ravi books, "naa lucky shirt, jagratta", Bunty: online loses clothes.
2 7:02: Dost rings at 7:02 am in the 7–11 slot, Bunty shocked he's on time, counts every item, notes a loose button, finds something in a pocket.
3 Pocket: it's the engagement ring; Ravi panics; Dost hands it back ("we check every pocket"); timings; Amma is sending her pattu sarees and Nanna's pancha by bus.
4 Lopala: inside the unit, big machines, owner hand-checks, steam press, button stitched, Dost read the note; Ravi caught on his phone by the manager.
5 Delivery: on time, shirts like showroom, button fixed, Bunty jealous of the fabric, date message, "Baigan…" (Bunty plotting).
6 Dhuvvam: Bunty irons his silk Eid kurta at home and burns it; Ravi: silk and pattu need dry cleaning; Bunty sulks.
7 Biryani: Bunty steals the lucky shirt at night for a date, drops biryani on it; "it's a design"; Amma's parcel arrives: engagement day after tomorrow.
8 Express: emergency; Bunty calls IronDost for Express, 6 hours at double price, pickup 12:30; Bunty pays; Dost: steam press for the saree, special wash for the stain, at the hall by 6:30.
9 Countdown: evening at the hall, Amma asks where Ravi is, Dost arrives on time, stain gone, saree like new, handed to Divya.
10 Nischitartham: hero walk, Divya's saree, Amma's blessing, Ravi credits Bunty and Dost, Bunty apologises, Dost invited to eat, banana-leaf meal, the ring, taglines "Battala tension? IronDost undi ga!" / "Kapdon ki tension? Dost hai na!", Season 2 tease.

## JSON schema (one file per episode: epNN.json)
```json
{
 "n": 1, "name": "Kondalu", "en": "The Mountain",
 "hook_formula": "...", "hook_text": "on-screen hook text for the edit, ≤ 8 words",
 "cliff": "cliffhanger edit text", "caption": "Instagram caption with ≤ 5 hashtags",
 "clips": [
  {
   "id": "E1-C1", "title": "short title", "set": "FLAT",
   "cast": ["RAVI", "BUNTY", "LUCKY"], "props": ["lucky_shirt"],
   "hook": true,
   "beats": [["0–2 s", "..."], ["2–4.5 s", "..."], ["4.5–7 s", "..."], ["7–10 s", "..."]],
   "camera": "one continuous move ...",
   "lines": [
     {"spk": "BUNTY", "mode": "ON", "at": "5–7 s",
      "native": "Devanagari for BUNTY, Telugu script for everyone else",
      "roman": "romanised line", "en": "English meaning"}
   ],
   "sound": "specific sound effects with timings; never music",
   "first": "first frame description", "last": "last frame description",
   "edit_text": "kinetic caption / overlays added in the edit",
   "neg_extra": ["clip-specific things to avoid"]
  }
 ]
}
```
`mode` is "ON" (speaker's face visible, lip-synced) or "OFF" (voice only, nobody on screen moves their lips). Keep v1's dialogue lines where they still fit (they are in ep_data.json) and reuse their wording; you may trim. Native script must be accurate Telugu / Hindi.

## Quality bar
- Concrete, filmable beats: who is where, what moves, what the face does, what Lucky's face does.
- Small physical actions near faces (big actions break faces). Big action is fine for the Bhootham, clothes flying and steam.
- Each beat names who is on screen. Never more than 3 people in a clip.
- `neg_extra` lists the specific failure risks of that clip (e.g. "the ring box turning into a phone", "Lucky's face appearing on Ravi's vest").
