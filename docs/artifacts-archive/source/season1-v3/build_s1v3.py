"""Build Dost Undi Ga! Season 1 v3: 40 all-AI clips of 10 s, one complete prompt each."""
import json, os, re, sys

D = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1]
EPS = [json.load(open(os.path.join(D, f"ep{n:02d}.json"))) for n in range(1, 11)]

SETS = {
 "FLAT": "a small lived-in Hyderabad 2BHK flat in Nagole: grey steel almirah with a mirror, ceiling fan, white tube light, a window with iron grills looking out at the elevated metro line, a plastic chair, a small dining table, a sofa, mosaic floor, pale green walls. Light: warm window light, golden tones, gentle shadows (at night: warm tube light and lamp)",
 "UNIT": "the IronDost laundry unit in LB Nagar: a row of stainless-steel front-loading industrial washers and tumble dryers, a large industrial steam-press table, metal shelves of plain royal-blue garment bags, bright clean white LED light, tiled floor",
 "HALL": "a South Indian engagement (nischitartham) function hall in Hyderabad in the evening: stage with marigold and jasmine garlands, banana-leaf arches, brass oil lamps, warm fairy lights, rows of chairs with cream covers, pillars wrapped in marigolds",
 "OFFICE": "an open-plan IT office in HITEC City, Hyderabad: rows of desks with dual monitors (screens out of focus), glass meeting rooms behind, cool daylight",
 "RESTO": "a busy Hyderabadi biryani restaurant at night: warm yellow lights, steel plates, a table for two with a copper handi of biryani and a bowl of mirchi ka salan",
 "BUS": "a red-and-white state transport bus on a wet highway near Hyderabad in light rain, a cardboard parcel tied with plastic rope on the roof carrier, grey sky",
}
SET_REF = {"FLAT": "set-flat.png", "UNIT": "set-unit.png", "HALL": "set-hall.png", "OFFICE": "set-office.png", "RESTO": "set-restaurant.png", "BUS": "set-bus.png"}
CAST = {
 "RAVI": ("ravi-ref.png", "RAVI: Telugu man, 28, medium-brown skin, short neat black hair, light stubble, slim build, friendly tired eyes. Wears exactly what the timeline says (at home: plain grey cotton vest and a white-and-blue checked lungi)."),
 "BUNTY": ("bunty-ref.png", "BUNTY: Hyderabadi man, 27, warm brown skin, round cheerful face, thick black hair with a side part, short trimmed beard, slightly chubby. Wears exactly what the timeline says (default: loose maroon printed half-sleeve shirt and black track pants)."),
 "DOST": ("dost-ref.png", "DOST (Srinu, IronDost pickup person): Telugu man, 30, medium-dark skin, clean-shaven with a neat moustache, short side-parted black hair, calm kind smile, fit build. Always a plain royal-blue polo with a BLANK chest, dark grey trousers, black sling bag."),
}
PROPS = {
 "ring_box": "RING BOX: a small red velvet ring box (with a gold ring inside when opened).",
 "saree": "THE SAREE: Amma's maroon Kanchipuram pattu silk saree with a wide gold zari border.",
 "pancha": "NANNA's PANCHA: a cream silk dhoti with a thin gold border.",
 "kurta": "BUNTY's EID KURTA: a cream silk kurta.",
 "bag": "GARMENT BAG: plain royal-blue (#1F4FD1) zip garment bag, no print, no logo, no text.",
 "lucky_shirt": "RAVI's LUCKY SHIRT: navy-blue cotton shirt with thin white checks, collar and one chest pocket; a plain shirt with no face or print.",
}
VOICE = {"OWNER": "OWNER (the unit owner, hands only, face never shown)", "AMMA": "AMMA (Ravi's mother, warm Telugu voice, off screen or on the phone)", "DIVYA": "DIVYA (Ravi's sister, off screen)", "MANAGER": "MANAGER (Ravi's boss, stern voice, off screen)"}
LANG = {"BUNTY": "Hyderabadi Hindi (Dakhni)"}

BRAND = ("CRITICAL BRAND CONSISTENCY: IronDost is shown only through DOST's plain royal-blue polo and plain royal-blue zip garment bags, both completely blank (no print, no logo, no text; the logo is added in the edit). "
 "Clothes that come back from IronDost are crisp, flat and spotless. Phones always face away from the camera; the IronDost app appears only as a soft royal-blue glow on the face. "
 "Never draw a phone screen, a bill, prices, a logo or any writing.")

NEG_GLOBAL = [
 ("Faces and bodies", "face changing during the clip, a different actor, two versions of the same person, extra or missing fingers, fused or melted hands, extra limbs, warped teeth, crossed eyes, plastic or waxy skin, uncanny frozen smile, a face, eyes or a mouth on any clothing"),
 ("People", "extra people or a crowd that is not described, AMMA's or DIVYA's face visible, background people looking at the camera"),
 ("Speech and sound", "background music, music score, humming, singing, laugh track, a line said twice, changed or extra words, English instead of Telugu or Hindi, the wrong person's lips moving, lips moving with no voice, the listener mouthing along, speech after the last line, silent gaps longer than one second, echoey or robotic voices"),
 ("Text", "any text, subtitles, captions, letters or digits anywhere in the picture, logos, watermarks, brand names, readable phone screens, app UI, chat bubbles, printed text or logos on the bags or the polo, readable signage"),
 ("Continuity", "cuts, jump cuts or scene changes inside the clip, the location changing, time of day changing, outfits changing, props changing colour or pattern, the check pattern on the lucky shirt changing, garment bags in any colour other than royal blue, objects appearing from nowhere"),
 ("Image quality", "morphing, warping or melting objects, flicker, jitter, stutter, frozen frames, unintended slow motion or fast-forward, cartoon, anime or 3D-render look on people, oversaturated or neon colours, blue colour cast, blur on faces, low resolution"),
 ("Content", "creatures or monsters, horror, gore, blood, large fire or flames, injuries, other brands' logos or packaging, alcohol, cigarettes"),
]

def on(c):
    return [k for k in c["cast"] if k in CAST]

def neg_for(c):
    absent = [k for k in ("RAVI", "BUNTY", "DOST") if k not in on(c)]
    first = list(c.get("neg_extra", [])) + [f"{k} appearing in the shot" for k in absent]
    return "; ".join(first) + ". " + " ".join(f"{h}: {t}." for h, t in NEG_GLOBAL)

def attach_for(c):
    a = [CAST[k][0] for k in on(c)] + [SET_REF[c["set"]]]
    if any(p in PROPS and PROPS[p] for p in c.get("props", [])):
        a.append("props-ref.png")
    return a

def prompt_for(ep, c):
    p = []
    A = p.append
    A(f"IronDost · 'Dost Undi Ga!' Ep {ep['n']} · {c['id']} · ONE continuous 10-second shot · vertical 9:16 · 1080p · 24 fps · audio on")
    A("")
    A("STYLE:")
    A(f"Photoreal cinematic live-action, premium Indian TV-commercial look, natural lip-synced speech. Setting: {SETS[c['set']]}. Lens 35 mm, shallow depth of field, gentle handheld feel, warm cinematic grade, realistic skin and fabric texture, hands with five fingers.")
    A("")
    A("CAST (only these appear; match the attached reference images exactly: same face, hair and clothes for the whole clip):")
    for k in on(c):
        A("- " + CAST[k][1])
    A("")
    A(BRAND)
    props = [PROPS[x] for x in c.get("props", []) if PROPS.get(x)]
    if props:
        A("PROPS (keep exactly as described the whole clip): " + " ".join(props))
    A("")
    A("TIMELINE (the action fills all 10 seconds; no frozen or empty moments):")
    for t, b in c["beats"]:
        A(f"{t}: {b}")
    A("")
    A("CAMERA: " + c["camera"] + " No cuts.")
    A("")
    if c.get("lines"):
        A("DIALOGUE (each line exactly once, word for word, inside its time window; whoever is listening keeps their mouth closed; nothing is said after the last line; the last half-second is silent):")
        for l in c["lines"]:
            who = VOICE.get(l["spk"], l["spk"])
            how = "on screen, lip-synced" if l["mode"] == "ON" else "voice only, off screen; nobody on screen moves their lips"
            lang = LANG.get(l["spk"], "Telugu with a natural Hyderabad accent")
            A(f"{l['at']} · {who} ({how}), in {lang}: \"{l['native']}\" ({l['roman']}) [meaning: {l['en']}]")
    else:
        A("DIALOGUE: none. Nobody speaks; only the sounds below.")
    A("")
    snd = re.sub(r"\s*No music[^.]*\.?", "", c["sound"]).strip().rstrip(".")
    A("SOUND: " + snd + ". No music of any kind.")
    A("")
    A("FIRST FRAME: " + c["first"])
    A("LAST FRAME: " + c["last"])
    A("")
    A("ATTACH: " + " + ".join(attach_for(c)))
    A("")
    A("NEGATIVE PROMPT: " + neg_for(c))
    return "\n".join(p)

md = []
P = md.append
P("# Dost Undi Ga! Season 1 · v3 · all-AI, 10-second prompts")
P("IronDost reel series · 10 episodes · 40 clips of 10 seconds · every shot AI-generated · rewritten 23 Nov 2026 after studying four reference reels (see the research and reach plan).\n")
P("**Battala tension? IronDost undi ga!** · **Kapdon ki tension? Dost hai na!**\n")
P("## What changed from v2")
P("- **Every clip is 10 seconds and AI.** 4 clips per episode, 40 seconds, plus a 4-second end card laid over the last frame. No screen recordings or real footage anywhere.")
P("- **Same Season 1 concept.** Same story, same cast (Ravi, Bunty, Dost; Amma and Divya as voices), same hook, hook text and cliffhanger for every episode. Only the shots changed: every one is now AI.")
P("- **Commercial-grade prompt layout** (from the Surf Excel reel): style, cast, a brand-consistency paragraph, a timeline that fills all 10 seconds, camera, timed dialogue, sound, first and last frame, attach list.")
P("- **A much stronger negative prompt** on every clip: the clip's own risks first, then 7 groups (faces, people, speech, text, continuity, image quality, content) covering every failure seen in the INDYUG audit.")
P("- **The app without a screen.** Phones always face away; the app is a royal-blue glow. All writing (prices, bills, codes, countdowns, captions) is added in the edit.\n")
P("## Which tool")
P("| Tool | Use it for | Settings |")
P("|---|---|---|")
P("| **Seedance 2.0** (through invideo, Dreamina or Higgsfield) | First choice. Both big reference creators used it. 10-second clips with reference images | Reference-to-video, 9:16, 1080p, 10 s, audio on |")
P("| **Kling 2.x** | Second choice if Seedance mangles a face | Elements / multi-image reference, 9:16, 10 s, professional mode |")
P("| **Google Flow (Veo)** | Best Telugu lip-sync, but only 8 s | Ingredients to Video (3 images), then Extend once with the same prompt's last two beats |\n")
P("## How to make one clip")
P("1. Upload the images in the clip's **Attach** line (the first three if your tool only takes three).")
P("2. Paste the **whole prompt**. If the tool has a separate negative box, paste the **negative prompt** there too.")
P("3. Generate 2–3 takes. Keep a take only if: faces match, bags and polo are blank royal blue, each line is said once by the right lips, no music, no AI-drawn text.")
P("4. If the voice sounds wrong, keep the picture and dub the line with a real voice.")
P("5. Save as `videos/dost-undi-ga/epNN/E{n}-C{k}.mp4`. In CapCut: word-by-word captions (Telugu on top, English below), the hook text, the logo on the polo and bags, then the end card.\n")
P("## Reference images (attach these)")
REFS = [("ravi-ref", "RAVI"), ("bunty-ref", "BUNTY"), ("dost-ref", "DOST (Srinu)"), ("props-ref", "Props: lucky shirt, ring box, saree and pancha, kurta, bag"),
        ("set-flat", "Set: the flat"), ("set-unit", "Set: IronDost unit"), ("set-hall", "Set: function hall"), ("set-office", "Set: IT office"), ("set-restaurant", "Set: biryani restaurant"), ("set-bus", "Set: bus")]
for f, label in REFS:
    P(f"- **{f}.png** · {label}")
P("\nAll in `videos/dost-undi-ga/refs/` and `~/Downloads/Irondost-Clip-Assets/11_Dost-Undi-Ga-S1/`.\n")

P("## Season at a glance")
P("| Ep | Title | Hook | Cliffhanger |")
P("|---|---|---|---|")
for e in EPS:
    P(f"| {e['n']} | {e['name']} ({e['en']}) | {e['hook_text']} | {e['cliff']} |")
P("")

for e in EPS:
    P(f"\n## Episode {e['n']} / 10 · {e['name']} ({e['en']})")
    P(f"**Hook formula:** {e['hook_formula']} · **Hook text (edit):** {e['hook_text']} · **Cliffhanger:** {e['cliff']}  ")
    P(f"**Caption:** {e['caption']}  ")
    P(f"**Save in:** `videos/dost-undi-ga/ep{e['n']:02d}/`\n")
    for k, c in enumerate(e["clips"]):
        s0 = k * 10
        P(f"### {c['id']} · {s0}–{s0+10} s of the reel · {c['title']}")
        P(f"Attach: **{' + '.join(attach_for(c))}**  ")
        if c.get("edit_text"):
            P(f"Edit text: {c['edit_text']}  ")
        for l in c.get("lines", []):
            P(f"- {l['at']} · **{l['spk']}{'' if l['mode']=='ON' else ' (voice)'}** {l['native']} · *{l['roman']}* · ({l['en']})")
        P("\n**Full prompt**\n")
        P("```text\n" + prompt_for(e, c) + "\n```\n")
        P("**Negative prompt only** (for a separate negative box)\n")
        P("```text\n" + neg_for(c) + "\n```\n")

P("## End card (4 s, over the last frame of C4)")
P("Logo, 'Battala tension? IronDost undi ga!', Call / WhatsApp 79934 34932 · 70329 90632, and the Play Store and App Store QR codes (irondost.in/app). Graphics only, made in the edit.\n")
P("## Before Episode 1 goes out")
P("- Create code DOST10 in admin and decide whether it applies to Express (Express is booked by phone only today).")
P("- Generate Ep 1 and check all 4 clips against the keep rules before making the rest.")
P("- Set up the 'Comment DOST' auto-DM (see the reach plan).")
open(OUT, "w").write("\n".join(md))

# checks
n = 0
for e in EPS:
    assert len(e["clips"]) == 4, e["n"]
    for c in e["clips"]:
        n += 1
        assert c["beats"][-1][0].replace(" ", "").endswith("10s"), c["id"]
        assert c["set"] in SETS and all(x in CAST or x in VOICE for x in c["cast"]), c["id"]
        assert len(attach_for(c)) <= 7
print(n, "clips OK")
