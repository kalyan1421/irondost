"""Rebuild Dost Undi Ga! Season 1 as one-block Veo prompts (INDYUG Gemini Clips format)."""
import json, re, sys

DATA = json.load(open(sys.argv[1]))
OUT = sys.argv[2]

# ---------- shared blocks ----------
STYLE = {
 "FLAT": "a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair piled with clothes, a small dining table, mosaic floor, pale green walls. Light: warm afternoon window light, golden tones, gentle shadows",
 "UNIT": "the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright white LED light, clean tiled floor",
 "HALL": "a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs, pillars wrapped in marigolds",
 "OFFICE": "an open-plan IT office in HITEC City, Hyderabad: rows of desks with dual monitors, glass meeting rooms behind, cool daylight",
 "RESTO": "a busy Hyderabadi biryani restaurant at night: warm yellow lights, steel plates, a table for two with a copper handi of biryani and a bowl of mirchi ka salan",
 "BUS": "a red-and-white state transport bus on a wet highway near Hyderabad in light rain, a cardboard parcel tied with plastic rope on the roof carrier, grey sky",
}
SET_REF = {"FLAT": "set-flat.png", "UNIT": "set-unit.png", "HALL": "set-hall.png", "OFFICE": "set-office.png", "RESTO": "set-restaurant.png", "BUS": "set-bus.png"}
CHAR_REF = {"RAVI": "ravi-ref.png", "BUNTY": "bunty-ref.png", "DOST": "dost-ref.png"}

CHARS = {
 "RAVI": "RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes, 5'8\". Home clothes: plain grey cotton vest and a white-and-blue checked lungi, unless the shot names other clothes.",
 "BUNTY": "BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby, 5'7\". Clothes: loose maroon printed half-sleeve shirt and black track pants, unless the shot names other clothes. Speaks Hyderabadi Hindi (Dakhni).",
 "DOST": "DOST (Srinu, the IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build, 5'9\". Always: plain royal-blue polo T-shirt with a BLANK chest, dark grey trousers, black sling bag over one shoulder.",
}

PRODUCT = ("IRONDOST LOOK (the 'product' in this series): IronDost garment bags are plain royal-blue (#1F4FD1) zip garment bags with NO print, NO logo and NO text (the logo is added in the edit). "
 "DOST's polo is the same royal blue with a blank chest. Clothes coming back from IronDost are crisp, flat, neatly folded or on hangers, never wrinkled. "
 "Never draw a phone screen, a bill, a logo or any writing: those are added in the edit.")
PROPS = {
 "lucky shirt": "RAVI's LUCKY SHIRT: navy-blue cotton men's shirt with thin white checks, collar and one chest pocket. Same shirt, same pattern, every time.",
 "ring": "RING BOX: small red velvet ring box.",
 "saree": "THE SAREE: maroon Kanchipuram pattu silk saree with a wide gold zari border; NANNA's PANCHA: cream silk dhoti with a thin gold border.",
 "kurta": "BUNTY's EID KURTA: cream silk kurta (the one that gets the iron-shaped burn in Ep 6).",
}
PROP_TRIGGERS = {"lucky shirt": r"lucky shirt|navy.{0,20}check", "ring": r"ring box|velvet", "saree": r"saree|pattu|pancha", "kurta": r"kurta"}

NEG_BASE = ("background music, music score, humming, singing, laughing or coughing over a spoken line, a line said twice, a changed word, "
 "the listening person moving their lips, lips moving during an off-screen voice, any speech after the last line, silent pauses longer than one second, "
 "a cut to a different room or location, faces changing between shots, different actors, extra people not described, "
 "on-screen text, subtitles, captions, letters or digits anywhere, phone screen UI, logos, printed text or logos on the garment bags or polo, watermark, "
 "garment bags in any colour other than royal blue, wrinkled clothes after IronDost, extra or missing fingers, distorted hands, plastic skin, cartoon, anime, "
 "3D render look, oversaturated colours, neon, blue colour cast, dirty or messy set beyond what is described, foreign city, snow")

# ---------- lines: native script, speaker, on/off screen ----------
L = {
 1:("RAVI","ON","అమ్మాఆ…!","Ammaaa…! (muffled, under the clothes)"),
 2:("BUNTY","ON","क्या रे, कपड़ों का चारमीनार बना दिया क्या?",None),
 3:("AMMA","OFF","రవీ, దివ్య నిశ్చితార్థానికి ఇంకా పది రోజులే! నీ బట్టలు రెడీ నా?",None),
 4:("RAVI","ON","హా… రెడీ అమ్మా, ఫుల్ రెడీ.",None),
 5:("BUNTY","ON","गली के धोबी को दे दे.",None),
 6:("RAVI","OFF","ధోబీ అన్న ఊరికి వెళ్ళిపోయాడు రా.",None),
 7:("AMMA","OFF","ఈ యాప్ చూడు రా, ఎల్ బి నగర్ లో ఇంటికొచ్చి తీసుకెళ్తారు.",None),
 8:("RAVI","ON","ఇది నా లక్కీ షర్ట్. జాగ్రత్త.",None),
 9:("BUNTY","ON","ऑनलाइन वाले कपड़े गायब कर देते, देख लेना.",None),
 10:("RAVI","ON","ఇంత పొద్దున్నే ఎవరు రా?!",None),
 11:("DOST","ON","నమస్కారం సర్, ఐరన్ దోస్త్ నుంచి. సెవెన్ టు ఎలెవెన్ స్లాట్.",None),
 12:("BUNTY","ON","टाइम पे आए? हैदराबाद में?",None),
 13:("DOST","ON","పద్దెనిమిది షర్ట్స్, నాలుగు ప్యాంట్స్, రెండు బెడ్‌షీట్స్…",None),
 14:("DOST","ON","సర్, ఈ బటన్ లూజ్ ఉంది. నోట్ చేస్తాను.",None),
 15:("DOST","ON","సర్… పాకెట్ లో ఏదో ఉంది.",None),
 16:("RAVI","ON","పట్టుకో…!",None),
 17:("RAVI","ON","అమ్మ చంపేస్తుంది…",None),
 18:("DOST","ON","మేము ప్రతి పాకెట్ చెక్ చేస్తాం సర్. మీ వస్తువులు మీ దగ్గరే ఉండాలి.",None),
 19:("BUNTY","ON","भाई… ये बंदे सच्चे हैं.",None),
 20:("DOST","ON","ఐరనింగ్ రెండు రోజుల్లో, లాండ్రీ మూడు రోజుల్లో, సర్.",None),
 21:("AMMA","OFF","రవీ, నా పట్టు చీరలు, నాన్న పంచ బస్ లో పంపుతున్నా. అవి కూడా రెడీ చెయ్యి!",None),
 22:("BUNTY","ON","अब तो दोस्त ही बचाएगा.",None),
 23:("RAVI","ON","నా షర్ట్స్ ఏం చేస్తున్నాయో…",None),
 24:("DOST","OFF","ఇదే మా యూనిట్. పెద్ద మెషీన్లు…",None),
 25:("DOST","OFF","…ప్రతి లోడ్ ని ఓనర్ చేత్తో చెక్ చేస్తారు.",None),
 26:("DOST","OFF","మీ నోట్ చదివాం సర్.",None),
 27:("MANAGER","OFF","రవీ! ఫోన్ కింద పెట్టు!",None),
 28:("RAVI","ON","అహాఆ…",None),
 29:("DOST","ON","ఐరనింగ్ ఆర్డర్, రెండు రోజుల్లో, చెప్పినట్టు.",None),
 30:("RAVI","ON","ఇవి నా షర్ట్స్ ఆ? షోరూమ్ లాగ ఉన్నాయి!",None),
 31:("RAVI","ON","బటన్ కూడా?!",None),
 32:("BUNTY","ON","हौ… मस्त है.",None),
 33:("BUNTY","ON","बैगन…",None),
 34:("BUNTY","ON","या अल्लाह! बैगन!",None),
 35:("RAVI","ON","సిల్క్ ని ఇంట్లో ఐరన్ చేస్తారా రా?!",None),
 36:("BUNTY","ON","अम्मी ने ईद पे दिया था…",None),
 37:("RAVI","ON","సిల్క్, పట్టు — ఇవి డ్రై క్లీనింగ్ కి ఇవ్వాలి. పెద్ద మెషీన్లు, కరెక్ట్ హీట్.",None),
 38:("BUNTY","ON","अब बोल के क्या फ़ायदा.",None),
 39:("BUNTY","ON","सिर्फ़ एक दिन, भाई… सॉरी.",None),
 40:("BUNTY","ON","नक्को…!",None),
 41:("BUNTY","ON","ये… डिज़ाइन है.",None),
 42:("RAVI","ON","రా బంటీ…!!",None),
 43:("BUNTY","ON","भाई, माफ़ कर. एकदम दिल से.",None),
 44:("AMMA","OFF","పార్సెల్ వచ్చిందా? ఎంగేజ్‌మెంట్ ఎల్లుండి! నా పట్టు చీర, నాన్న పంచ, నీ లక్కీ షర్ట్ — అన్నీ రెడీ నా?",None),
 45:("RAVI","ON","ఎల్లుండి… అన్నీ ఎల్లుండి…",None),
 46:("BUNTY","ON","एक्सप्रेस! छह घंटे में!",None),
 47:("RAVI","ON","ఐరనింగ్ కి రెండు రోజులు, లాండ్రీ కి మూడు కదా?",None),
 48:("BUNTY","ON","नॉर्मल में, हौ. लेकिन एक्सप्रेस है — छह घंटे.",None),
 49:("BUNTY","ON","हेलो, आयरन दोस्त? एक्सप्रेस चाहिए, इमरजेंसी है!",None),
 50:("DOST","ON","ఎక్స్‌ప్రెస్ — ఆరు గంటల్లో, డబుల్ ప్రైస్ సర్. పన్నెండున్నరకి పికప్.",None),
 51:("BUNTY","ON","बिल मेरा. ग़लती मेरी थी.",None),
 52:("RAVI","ON","నువ్వు పిచ్చోడివి రా.",None),
 53:("DOST","ON","చీర కోసం స్టీమ్ ప్రెస్, స్టెయిన్ కోసం స్పెషల్ వాష్. ఆరున్నర లోపు మీరు ఫంక్షన్ హాల్ లో.",None),
 54:("AMMA","OFF","రవీ ఎక్కడ?!",None),
 55:("RAVI","ON","రాలేదు రా…",None),
 56:("BUNTY","ON","आएगा. दोस्त है ना.",None),
 57:("DOST","ON","సర్, చెప్పిన టైమ్ లోపల.",None),
 58:("RAVI","ON","స్టెయిన్… లేదు!",None),
 59:("BUNTY","ON","या अल्लाह, नया जैसा!",None),
 60:("DIVYA","OFF","హాఆ…!",None),
 61:("BUNTY","ON","भाई… हीरो लग रहे हम.",None),
 62:("DIVYA","OFF","అమ్మా! కొత్త చీర లాగ ఉంది!",None),
 63:("AMMA","OFF","బాగా చేశావ్ రా.",None),
 64:("RAVI","ON","కాదు అమ్మా, బంటీ అండ్ దోస్త్.",None),
 65:("BUNTY","ON","आंटी, ग़लती मेरी थी, दोस्त ने बचा लिया.",None),
 66:("AMMA","OFF","బాబూ! భోజనం చేసి వెళ్ళు.",None),
 67:("RAVI","ON","బట్టల టెన్షన్? ఐరన్ దోస్త్ ఉంది గా!",None),
 68:("BUNTY","ON","कपड़ों की टेंशन? दोस्त है ना!",None),
 69:("BUNTY","ON","भाई… सीज़न 2.",None),
}
VOICE_DESC = {"AMMA": "AMMA (Ravi's mother, about 55, warm Telugu voice, on the phone or off screen)",
              "DIVYA": "DIVYA (Ravi's younger sister, about 24, off screen)",
              "MANAGER": "MANAGER (Ravi's boss, stern man's voice, off screen)"}
LANG = {"BUNTY": "Hyderabadi Hindi (Dakhni)"}

def strip_prefix(t):
    return re.sub(r"^\([^)]*\)\s*", "", t).strip()

def secs(m):
    m2 = re.search(r"(\d+)\s*seconds?\.?\s*$", m)
    return m2

lines_iter = iter(sorted(L))
md = []
P = md.append

P("# Dost Undi Ga! Season 1 · Veo prompts v2")
P("IronDost reel series · 10 episodes · 94 clips · rewritten 23 Nov 2026 in the INDYUG Gemini Clips format.\n")
P("**Battala tension? IronDost undi ga!** · **Kapdon ki tension? Dost hai na!**\n")
P("Facts on screen: Laundry 3 days · Ironing 2 days · Express 6 hrs at 2× price · ₹500+ gets 10% off with DOST10 · Call / WhatsApp 79934 34932 · 70329 90632 · post daily 7:30 pm IST.\n")
P("## What changed from v1")
P("- **One block per clip.** Every prompt is complete on its own: style, cast, the IronDost look, what happens second by second, camera, dialogue, sound, first and last frame, what to attach and a negative prompt. Copy it, paste it, generate.")
P("- **Veo makes the voice too.** Dialogue is written in Telugu script (Bunty in Devanagari), then romanised, then the English meaning, so Veo pronounces it properly. If a voice still sounds wrong, mute it and dub a real voice (the v1 plan).")
P("- **Ingredients to Video, not keyframes.** Attach the reference images listed on each clip (Flow allows 3). No separate keyframe step.")
P("- **The IronDost look is locked** like a product: plain royal-blue garment bags and polo with no print, crisp clothes after IronDost, and story props described the same way every time.")
P("- **Speaker rules** from the INDYUG audit: each line once, the listener's mouth stays closed, nothing after the last line, no silent gap over 1 s, no music.")
P("- **Clip length.** Veo makes 8 s. Each clip says how many seconds the reel uses; the action and lines finish inside that, and the rest is a quiet hold you trim.\n")

P("## How to make them")
P("1. **Make the reference images once** (prompts below, already generated into `videos/dost-undi-ga/refs/`). Check the faces, then keep them.")
P("2. **Flow → Ingredients to Video**, Veo at the highest quality you have, 9:16, audio on. Upload the images in the clip's Attach line, paste the whole prompt.")
P("3. **Generate every clip fresh.** Don't use Extend across clips with different people or rooms; that is how the INDYUG Ep 2 take broke.")
P("4. **Check before you keep a take:** right faces, Dost's polo and bags plain royal blue with no print, each line said once by the right lips, no music, no text drawn by the AI.")
P("5. **Real clips** (phone screens, app, bills) are screen recordings or edit graphics. Record them from the real app.")
P("6. **Save** as `videos/dost-undi-ga/epNN/E{n}-C{k}.mp4` and cut in CapCut: trim to the reel length, add the on-screen text, English subtitles, the logo on Dost's polo and bags, and the end card. Turn on the AI-content label when posting.\n")

P("## Reference images (make once)")
REFS = [
 ("ravi-ref.png", "RAVI", "Character reference sheet, photoreal, plain light-grey background, soft even studio light, 16:9 image. One person shown four times side by side: front view, three-quarter view, side view and full body. " + CHARS["RAVI"] + " Exactly the same face in every view. Realistic skin texture, no makeup, no text, no logo, no watermark."),
 ("bunty-ref.png", "BUNTY", "Character reference sheet, photoreal, plain light-grey background, soft even studio light, 16:9 image. One person shown four times side by side: front view, three-quarter view, side view and full body. " + CHARS["BUNTY"].replace(" Speaks Hyderabadi Hindi (Dakhni).", "") + " Exactly the same face in every view. Realistic skin texture, no text, no logo, no watermark."),
 ("dost-ref.png", "DOST", "Character reference sheet, photoreal, plain light-grey background, soft even studio light, 16:9 image. One person shown four times side by side: front view, three-quarter view, side view and full body, holding two plain royal-blue zip garment bags in the full-body view. " + CHARS["DOST"] + " The polo chest and the bags are completely blank. Exactly the same face in every view. Realistic skin texture, no text, no logo, no watermark."),
 ("set-flat.png", "SET", "Photoreal interior reference, vertical 9:16, no people: " + STYLE["FLAT"] + ". No text."),
 ("set-unit.png", "SET", "Photoreal interior reference, vertical 9:16, no people: " + STYLE["UNIT"] + ". No text, no logos. (Replace with real photos of your unit when you have them.)"),
 ("set-hall.png", "SET", "Photoreal interior reference, vertical 9:16, no people: " + STYLE["HALL"] + ". No text."),
 ("set-office.png", "SET", "Photoreal interior reference, vertical 9:16, no people: " + STYLE["OFFICE"] + ". No readable text on screens."),
 ("set-restaurant.png", "SET", "Photoreal interior reference, vertical 9:16, no people: " + STYLE["RESTO"] + ". No text."),
 ("set-bus.png", "SET", "Photoreal exterior reference, vertical 9:16: " + STYLE["BUS"] + ". No readable text or logos."),
 ("props-ref.png", "PROPS", "Photoreal product reference sheet on a plain light-grey background, soft studio light, 16:9, items laid out separately: (1) " + PROPS["lucky shirt"] + " On a hanger. (2) " + PROPS["ring"] + " Closed. (3) " + PROPS["saree"] + " Folded, side by side. (4) " + PROPS["kurta"] + " Folded, undamaged. (5) one plain royal-blue (#1F4FD1) zip garment bag with no print. No text, no logos."),
]
for fn, kind, prompt in REFS:
    P(f"### `{fn}`")
    P("```text\n" + prompt + "\n```")
json.dump([{"file": f, "prompt": p} for f, _, p in REFS], open(OUT.replace(".md", "-refs.json"), "w"), ensure_ascii=False, indent=1)

total = 0
for e in DATA["EPS"]:
    n = e["n"]
    P(f"\n## Episode {n} / 10 · {e['name']} ({e['en']})")
    P(f"**Hook formula:** {e['formula']} · **Hook:** {e['hook']}  ")
    P(f"**Hook text on screen (edit):** {e['hookText']} · **Cliffhanger:** {e['cliff']}  ")
    P(f"**Caption:** {e['caption']}  ")
    P(f"**Save in:** `videos/dost-undi-ga/ep{n:02d}/`\n")
    t0 = 0
    for k, c in enumerate(e["clips"], 1):
        total += 1
        d = c["d"]; cid = f"E{n}-C{k}"
        rng = f"{t0}–{t0+d} s"; t0 += d
        lines = []
        for a in c.get("a", []):
            lines.append((next(lines_iter), a))
        P(f"### {cid} · {rng} · {c['t']}")
        if not c.get("s"):
            P(f"**Real clip, no AI.** {c['img']}  ")
            if c.get("mov"): P(f"Motion in the edit: {c['mov']}  ")
            for lid, a in lines:
                spk, mode, native, _ = L[lid]
                P(f"Voice over ({spk}): {native} · *{strip_prefix(a[0])}* · ({a[1]})  ")
            if c.get("ost"): P(f"On screen: {c['ost']}  ")
            if c.get("sfx"): P(f"Sound: {c['sfx']}  ")
            P("")
            continue
        who = c.get("c", [])
        scene = c["img"]
        props = [p for p, rx in PROP_TRIGGERS.items() if re.search(rx, scene + " " + c.get("mov", ""), re.I)]
        attach = [CHAR_REF[x] for x in who] + [SET_REF[c["s"]]]
        if props: attach.append("props-ref.png")
        attach = attach[:3]
        mov = re.sub(r"\s*\d+\s*seconds?\.?\s*$", "", c.get("mov", "")).strip()
        ends = max(1, d - 0.5)
        # dialogue block
        dl = []
        for lid, a in lines:
            spk, mode, native, roman = L[lid]
            roman = roman or strip_prefix(a[0])
            lang = LANG.get(spk, "Telugu, natural Hyderabad accent")
            name = VOICE_DESC.get(spk, spk)
            how = "lip-synced, face visible" if mode == "ON" else "voice only, off screen: nobody on screen moves their lips"
            dl.append(f"{name}: \"{native}\" ({roman}) [meaning: {a[1]}]  — spoken in {lang}, {how}.")
        listeners = [x for x in who if x not in [L[l][0] for l, _ in lines]]
        absent = [x for x in ("RAVI", "BUNTY", "DOST") if x not in who]
        neg = NEG_BASE + "".join(f", {x} appearing in the shot" for x in absent)
        hook = c.get("hook")
        sound = (c.get("sfx") or "Natural room sound only") + ". No music of any kind: no background score, no humming, no singing."
        prompt = [
         f"IronDost reel 'Dost Undi Ga!' · Ep {n} · {cid} · generate exactly 8 seconds · vertical 9:16 · 1080p · audio on",
         "",
         "STYLE:",
         f"Photoreal cinematic live-action, vertical 9:16, 1080p, 24 fps, natural lip-synced speech. Setting: {STYLE[c['s']]}. Lens: 35 mm, shallow depth of field, slight handheld feel, warm cinematic grade. Realistic skin, hands with five fingers, honest everyday Hyderabad mood.",
         "",
         "CHARACTERS (same faces, hair and clothes as the attached reference sheets; only these people are on screen):" if who else "CHARACTERS: none on screen except hands or bodies described in the shot; no faces.",
         *[CHARS[x] for x in who],
         "",
         PRODUCT,
         *[PROPS[p] for p in props],
         "",
         "SHOT, SECOND BY SECOND:",
         f"0–1 s: {'Frame 1 is already moving, with a sound hit at 0.0 s. ' if hook else ''}{scene}",
         f"1–{d} s: {mov}",
         f"{d}–8 s: Hold the same moment with a slow camera drift, no new action{', no speech' if lines else ''}. (This tail is trimmed in the edit; the reel uses 0–{d} s.)",
         "",
         "CAMERA: " + ("Starts mid-action on the first frame, " if hook else "") + "one continuous shot, no cuts inside the clip; small movements only so faces stay stable.",
         "",
         *( [f"DIALOGUE (all lines finished by {ends:g} s; each line said exactly once; nothing is said after the last line):", *dl,
             *( [f"Listening: {' and '.join(listeners)} {'keeps their mouth' if len(listeners)==1 else 'keep their mouths'} closed while others speak."] if listeners else [] ), ""] if dl else ["DIALOGUE: none. Nobody speaks.", ""] ),
         "SOUND: " + sound,
         "",
         f"FIRST FRAME: {scene}",
         f"LAST FRAME: the end of this action: {mov}",
         "",
         "ATTACH: " + " + ".join(attach) + "  (from videos/dost-undi-ga/refs/)",
         "",
         "NEGATIVE PROMPT: " + neg,
        ]
        P(f"Attach: **{' + '.join(attach)}**  ")
        if c.get("ost"): P(f"On screen (edit): {c['ost']}  ")
        for lid, a in lines:
            spk, mode, native, _ = L[lid]
            P(f"- **{spk}{'' if mode=='ON' else ' (voice)'}** {native} · *{strip_prefix(a[0])}* · ({a[1]})")
        P("\n```text\n" + "\n".join(prompt) + "\n```\n")

P("## End card (6 s, layout B)")
P("Two big screens: logo and 'Battala tension? IronDost undi ga!', then Call / WhatsApp 79934 34932 · 70329 90632 with the Play Store and App Store QR codes (QR goes to irondost.in/app). Made in the edit from `videos/dost-undi-ga/endcard-b/`.\n")
P("## Before episode 1 goes out")
P("- Create code DOST10 in admin and decide whether it applies to Express (Express is booked by phone only).")
P("- Screen-record the real app for the Real clips.")
P("- Generate Ep 1 and check one full take against the rules above before making the rest.")
open(OUT, "w").write("\n".join(md))
assert next(lines_iter, None) is None, "unused lines"
print(total, "clips")
