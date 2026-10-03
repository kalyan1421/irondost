#!/usr/bin/env python3
"""
Generates every IronDost SVG (logo lockups, app icon sources) and the colour
tokens from one master drawing. Wordmark text is converted to outlines, so the
SVGs render identically everywhere without the font installed.

  OUTFIT_DIR=/path/to/fonts python3 scripts/build-svg.py

OUTFIT_DIR must contain Outfit-Bold.ttf and Outfit-SemiBold.ttf
(Google Fonts, SIL Open Font License). Requires: pip install fonttools
"""
import json
import os
import sys
from pathlib import Path

from fontTools.pens.boundsPen import BoundsPen
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

ROOT = Path(__file__).resolve().parent.parent

# ---------------------------------------------------------------- colours

PALETTE = {
    "ink": {"hex": "#0E1E3D", "role": "Text, outlines and dark surfaces"},
    "royal": {"hex": "#1F4FD1", "role": "Primary: buttons, links and the word Dost"},
    "sky": {"hex": "#3FB8EA", "role": "Water, fills, accents on dark backgrounds"},
    "ocean": {"hex": "#1A73B0", "role": "Text-safe partner for sky on light backgrounds"},
    "sun": {"hex": "#FFC93C", "role": "Highlights, offers and badges, always with ink text"},
    "mist": {"hex": "#E6EEF8", "role": "Panels and soft surfaces"},
    "white": {"hex": "#FFFFFF", "role": "Backgrounds, washer and iron bodies"},
}
ILLUSTRATION = {"steel": "#C9D2DD", "ring": "#DCE4EE", "glass": "#BFEAF8", "foam": "#D9F4FC", "chrome": "#F1F4F8"}
HEX = {k: v["hex"] for k, v in PALETTE.items()}

# Fill/stroke roles used by the mark. "color" draws the logo; "mask" draws a
# luminance mask (white = keep, black = cut) for single-colour versions.
MARK_COLORS = {
    "color": dict(
        O=HEX["ink"], W=HEX["white"], MIST=HEX["mist"], SK=HEX["royal"], WIN=ILLUSTRATION["glass"],
        WAT=HEX["sky"], STEEL=ILLUSTRATION["steel"], RING=ILLUSTRATION["ring"], SUN=HEX["sun"],
        HL="#FFFFFF", HLS=ILLUSTRATION["chrome"], GB="#FFFFFF", DH=HEX["ink"], FT=HEX["ink"],
        BO=HEX["ink"], BF=ILLUSTRATION["foam"], HLB="#FFFFFF",
    ),
    "mask": dict(
        O="#000", W="#fff", MIST="#fff", SK="#fff", WIN="#000", WAT="#fff", STEEL="#fff", RING="#fff",
        SUN="#fff", HL="none", HLS="none", GB="#fff", DH="#000", FT="#fff", BO="#fff", BF="#000", HLB="#fff",
    ),
}

# ---------------------------------------------------------------- the mark
# Front-load washer (left) with a steam iron parked in front of it and soap
# bubbles rising on the right. Iron strokes are pre-divided by its 0.7 scale
# so line weights match the washer.

MARK_FULL = """<g transform="translate(2 6)" stroke-linejoin="round" stroke-linecap="round">
<rect x="8" y="66" width="8" height="5" rx="1.5" fill="{FT}"/>
<rect x="44" y="66" width="8" height="5" rx="1.5" fill="{FT}"/>
<rect x="2" y="2" width="56" height="66" rx="8" fill="{W}"/>
<path d="M10 2H50Q58 2 58 10V17H2V10Q2 2 10 2Z" fill="{MIST}"/>
<rect x="2" y="2" width="56" height="66" rx="8" fill="none" stroke="{O}" stroke-width="2.5"/>
<path d="M2 17H58" fill="none" stroke="{O}" stroke-width="2"/>
<circle cx="11" cy="9.5" r="3.5" fill="{SK}" stroke="{O}" stroke-width="1.8"/>
<circle cx="20" cy="9.5" r="1.8" fill="{FT}"/>
<rect x="33" y="6.5" width="18" height="6" rx="2" fill="{WIN}" stroke="{O}" stroke-width="1.6"/>
<circle cx="30" cy="43" r="18" fill="{RING}" stroke="{O}" stroke-width="2.5"/>
<circle cx="30" cy="43" r="13" fill="{WIN}"/>
<path d="M17.04 44Q20.28 40.8 23.52 44T30 44T36.48 44T42.96 44A13 13 0 0 1 17.04 44Z" fill="{WAT}"/>
<circle cx="25" cy="49" r="1.8" fill="{GB}"/>
<circle cx="34" cy="51" r="1.3" fill="{GB}"/>
<circle cx="30" cy="43" r="13" fill="none" stroke="{O}" stroke-width="2"/>
<path d="M21 37A11 11 0 0 1 28 32.4" fill="none" stroke="{HL}" stroke-width="2"/>
<rect x="44.6" y="39" width="3.4" height="8" rx="1.7" fill="{DH}"/>
</g>
<g stroke-linecap="round">
<circle cx="103" cy="25" r="6" fill="{BF}" stroke="{BO}" stroke-width="2"/>
<path d="M99.6 24.4A3.6 3.6 0 0 1 102.4 21.6" fill="none" stroke="{HLB}" stroke-width="1.6"/>
<circle cx="116" cy="14" r="4" fill="{BF}" stroke="{BO}" stroke-width="1.8"/>
<path d="M113.7 13.6A2.4 2.4 0 0 1 115.6 11.7" fill="none" stroke="{HLB}" stroke-width="1.3"/>
<circle cx="98" cy="10.5" r="2.6" fill="{BF}" stroke="{BO}" stroke-width="1.6"/>
</g>
<g transform="translate(43.1 31.4) scale(0.7)" stroke-linejoin="round" stroke-linecap="round">
<path d="M111 46C117 46 119 50 118 55C117 60 114 62 116 67" fill="none" stroke="{O}" stroke-width="3.4"/>
<rect x="60" y="8.5" width="10" height="5" rx="2.5" fill="{SUN}" stroke="{O}" stroke-width="2.7"/>
<path d="M38 40C41 27 48 14.5 60 13L97 11.5C104 11.5 107.5 15.5 107.5 22L108 40ZM57 36C58.5 29 62 23.5 68 23L94 22.5C96 22.5 97 23.5 97 25.5L97 36Z" fill="{W}" fill-rule="evenodd" stroke="{O}" stroke-width="3.3"/>
<path d="M7 57C12 46 26 37.5 44 36L102 34Q110.5 34 111.5 43L112 57Z" fill="{SK}" stroke="{O}" stroke-width="3.3"/>
<path d="M24 44.6C30 40.8 37 38.8 44 38.2" fill="none" stroke="{HL}" stroke-opacity="0.5" stroke-width="3"/>
<path d="M15 52C19 46.5 27 42 37 41H42Q44 41 44 43V50Q44 52 42 52Z" fill="{WIN}" stroke="{O}" stroke-width="2.3"/>
<path d="M16.6 51L18 49.2Q24 47.6 30 49Q36 50.2 43 48.4V51Z" fill="{WAT}"/>
<path d="M47 51.2L110 50.6" fill="none" stroke="{HL}" stroke-opacity="0.55" stroke-width="2.3"/>
<circle cx="66" cy="44.5" r="5" fill="{W}" stroke="{O}" stroke-width="2.3"/>
<path d="M66 44.5V41" fill="none" stroke="{O}" stroke-width="2.1"/>
<path d="M3 61Q8 55 22 54H109Q114 54 114 58.75Q114 63.5 109 63.5H12Q5 63.5 3 61Z" fill="{STEEL}" stroke="{O}" stroke-width="3.3"/>
<path d="M16 58.75H104" fill="none" stroke="{HLS}" stroke-width="2"/>
</g>"""

# Simplified mark for 48px and below: no bubbles, cord or small controls,
# heavier strokes.
MARK_SMALL = """<g transform="translate(2 6)" stroke-linejoin="round" stroke-linecap="round">
<rect x="8" y="65" width="9" height="6" rx="2" fill="{FT}"/>
<rect x="43" y="65" width="9" height="6" rx="2" fill="{FT}"/>
<rect x="2" y="2" width="56" height="66" rx="9" fill="{W}"/>
<path d="M11 2H49Q58 2 58 11V18H2V11Q2 2 11 2Z" fill="{MIST}"/>
<rect x="2" y="2" width="56" height="66" rx="9" fill="none" stroke="{O}" stroke-width="3.6"/>
<path d="M2 18H58" fill="none" stroke="{O}" stroke-width="3.2"/>
<circle cx="12" cy="10" r="3.8" fill="{SK}" stroke="{O}" stroke-width="2.6"/>
<circle cx="30" cy="43" r="18" fill="{RING}" stroke="{O}" stroke-width="3.6"/>
<circle cx="30" cy="43" r="12" fill="{WIN}"/>
<path d="M18.09 44.5Q21.07 41.2 24.05 44.5T30 44.5T35.95 44.5T41.91 44.5A12 12 0 0 1 18.09 44.5Z" fill="{WAT}"/>
<circle cx="30" cy="43" r="12" fill="none" stroke="{O}" stroke-width="3.2"/>
</g>
<g transform="translate(43.1 31.4) scale(0.7)" stroke-linejoin="round" stroke-linecap="round">
<path d="M38 40C41 27 48 14.5 60 13L97 11.5C104 11.5 107.5 15.5 107.5 22L108 40ZM57 36C58.5 29 62 23.5 68 23L94 22.5C96 22.5 97 23.5 97 25.5L97 36Z" fill="{W}" fill-rule="evenodd" stroke="{O}" stroke-width="4.8"/>
<path d="M7 57C12 46 26 37.5 44 36L102 34Q110.5 34 111.5 43L112 57Z" fill="{SK}" stroke="{O}" stroke-width="4.8"/>
<path d="M3 61Q8 55 22 54H109Q114 54 114 58.75Q114 63.5 109 63.5H12Q5 63.5 3 61Z" fill="{STEEL}" stroke="{O}" stroke-width="4.8"/>
</g>"""

# Washer-only glyph for 24px and below, where the iron cannot be resolved.
MARK_GLYPH = """<g transform="translate(2 6)" stroke-linejoin="round">
<rect x="2" y="2" width="56" height="66" rx="10" fill="{W}" stroke="{O}" stroke-width="4.5"/>
<path d="M2 18H58" fill="none" stroke="{O}" stroke-width="4"/>
<circle cx="30" cy="43" r="16" fill="{WIN}"/>
<path d="M14.13 45Q18.1 41.5 22.07 45T30 45T37.93 45T45.87 45A16 16 0 0 1 14.13 45Z" fill="{WAT}"/>
<circle cx="30" cy="43" r="16" fill="none" stroke="{O}" stroke-width="4.5"/>
</g>"""

# Ink bounds of each drawing in mark units (x0, y0, x1, y1), strokes included.
MARKS = {
    "full": {"tpl": MARK_FULL, "bounds": (2.85, 6.85, 126.5, 79.2)},
    "small": {"tpl": MARK_SMALL, "bounds": (2.2, 6.2, 125.1, 77.9)},
    "glyph": {"tpl": MARK_GLYPH, "bounds": (1.75, 5.75, 62.25, 76.25)},
}


def n(v):
    """Compact number formatting for SVG output."""
    s = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if s == "-0" else s


class Canvas:
    """Collects defs and body markup for one SVG file."""

    def __init__(self, uid):
        self.uid = uid
        self.defs = []
        self.body = []
        self._count = 0

    def next_id(self):
        self._count += 1
        return f"{self.uid}-{self._count}"

    def mark(self, x, y, height, kind="full", mono=None):
        """Place a mark so its ink box starts at (x, y) with the given height.
        mono=None draws full colour; mono="#hex" draws a single-colour knockout."""
        spec = MARKS[kind]
        x0, y0, x1, y1 = spec["bounds"]
        s = height / (y1 - y0)
        tx, ty = x - x0 * s, y - y0 * s
        mid = self.next_id()
        palette = MARK_COLORS["mask" if mono else "color"]
        art = spec["tpl"].format(**palette)
        group = f'<g transform="translate({n(tx)} {n(ty)}) scale({n(s)})">{art}</g>'
        if mono:
            w, h = (x1 - x0) * s, height
            pad = 2
            self.defs.append(
                f'<mask id="{mid}-mask" maskUnits="userSpaceOnUse" x="{n(x - pad)}" y="{n(y - pad)}" '
                f'width="{n(w + 2 * pad)}" height="{n(h + 2 * pad)}">{group}</mask>'
            )
            self.body.append(
                f'<rect x="{n(x - pad)}" y="{n(y - pad)}" width="{n(w + 2 * pad)}" height="{n(h + 2 * pad)}" '
                f'fill="{mono}" mask="url(#{mid}-mask)"/>'
            )
        else:
            self.body.append(group)
        return (x1 - x0) * s

    def rect(self, x, y, w, h, fill, rx=0):
        self.body.append(f'<rect x="{n(x)}" y="{n(y)}" width="{n(w)}" height="{n(h)}" rx="{n(rx)}" fill="{fill}"/>')

    def svg(self, vx, vy, vw, vh, title, width=None, height=None):
        size = f' width="{n(width)}" height="{n(height)}"' if width else ""
        defs = f"<defs>{''.join(self.defs)}</defs>" if self.defs else ""
        return (
            f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="{n(vx)} {n(vy)} {n(vw)} {n(vh)}"{size} '
            f'role="img" aria-label="{title}"><title>{title}</title>{defs}{"".join(self.body)}</svg>\n'
        )


# ---------------------------------------------------------------- type


class Font:
    def __init__(self, path):
        self.tt = TTFont(path)
        self.gs = self.tt.getGlyphSet()
        self.cmap = self.tt.getBestCmap()
        self.upm = self.tt["head"].unitsPerEm
        self.cap = self.tt["OS/2"].sCapHeight / self.upm
        self.lookups = self._kern_lookups()

    def _kern_lookups(self):
        gpos = self.tt["GPOS"].table
        indices = set()
        for fr in gpos.FeatureList.FeatureRecord:
            if fr.FeatureTag == "kern":
                indices.update(fr.Feature.LookupListIndex)
        lookups = []
        for i in sorted(indices):
            lk = gpos.LookupList.Lookup[i]
            subs = []
            for st in lk.SubTable:
                kind = lk.LookupType
                if kind == 9:
                    kind, st = st.ExtensionLookupType, st.ExtSubTable
                if kind == 2:
                    subs.append(st)
            lookups.append(subs)
        return lookups

    def kern(self, a, b):
        total = 0
        for subs in self.lookups:
            for st in subs:
                glyphs = st.Coverage.glyphs
                if a not in glyphs:
                    continue
                value = None
                if st.Format == 1:
                    for rec in st.PairSet[glyphs.index(a)].PairValueRecord:
                        if rec.SecondGlyph == b:
                            value = rec.Value1
                            break
                else:
                    c1 = st.ClassDef1.classDefs.get(a, 0)
                    c2 = st.ClassDef2.classDefs.get(b, 0)
                    value = st.Class1Record[c1].Class2Record[c2].Value1
                adv = getattr(value, "XAdvance", 0) if value is not None else 0
                if adv:
                    total += adv
                    break
        return total

    def runs(self, runs, size, tracking=0.0):
        """Outline [(text, fill), ...] at the origin (baseline y=0).
        Returns (paths, (xmin, ymin, xmax, ymax)) of the ink."""
        s = size / self.upm
        glyphs = [(self.cmap[ord(ch)], fill) for text, fill in runs for ch in text]
        pens = {}
        bounds = BoundsPen(self.gs)
        cx = 0.0
        for i, (name, fill) in enumerate(glyphs):
            matrix = (s, 0, 0, -s, cx * s, 0)
            pen = pens.setdefault(fill, SVGPathPen(self.gs, ntos=n))
            self.gs[name].draw(TransformPen(pen, matrix))
            self.gs[name].draw(TransformPen(bounds, matrix))
            cx += self.gs[name].width
            if i < len(glyphs) - 1:
                cx += self.kern(name, glyphs[i + 1][0]) + tracking * self.upm
        paths = [(pen.getCommands(), fill) for fill, pen in pens.items()]
        return paths, bounds.bounds

    @staticmethod
    def place(canvas, paths, dx, dy):
        for d, fill in paths:
            canvas.body.append(f'<path transform="translate({n(dx)} {n(dy)})" fill="{fill}" d="{d}"/>')


# ---------------------------------------------------------------- lockups

TAGLINE = "WASH · IRON · DELIVER"
VARIANTS = {
    # name: (mono colour or None, "Iron", "Dost", tagline)
    "": (None, HEX["ink"], HEX["royal"], HEX["ocean"]),
    "-reverse": (None, HEX["white"], HEX["sky"], HEX["sky"]),
    "-mono-ink": (HEX["ink"], HEX["ink"], HEX["ink"], HEX["ink"]),
    "-mono-white": (HEX["white"], HEX["white"], HEX["white"], HEX["white"]),
}
MARK_H = 76
PAD = 1


def wordmark_runs(iron, dost):
    return [("Iron", iron), ("Dost", dost)]


def tagline_matching(font, width, size, fill):
    """Outline the tagline with tracking chosen so its ink spans `width`."""
    _, (x0, _, x1, _) = font.runs([(TAGLINE, fill)], size)
    gaps = len(TAGLINE) - 1
    tracking = (width - (x1 - x0)) / gaps / size
    tracking = max(0.06, min(tracking, 0.4))
    return font.runs([(TAGLINE, fill)], size, tracking)


def build_horizontal(bold, semi, variant, tagline):
    mono, c_iron, c_dost, c_tag = VARIANTS[variant]
    cv = Canvas("h" + ("t" if tagline else "") + variant.replace("-", ""))
    mark_w = cv.mark(0, 0, MARK_H, "full", mono)
    gap = 18
    word_size = 39 if tagline else 43
    paths, (wx0, wy0, wx1, wy1) = bold.runs(wordmark_runs(c_iron, c_dost), word_size)
    cap = bold.cap * word_size
    left = mark_w + gap
    if tagline:
        t_size, t_gap = 11.5, 9.5
        tpaths, (tx0, ty0, tx1, ty1) = tagline_matching(semi, wx1 - wx0, t_size, c_tag)
        t_cap = semi.cap * t_size
        top = MARK_H / 2 - (cap + t_gap + t_cap) / 2
        base = top + cap
        Font.place(cv, paths, left - wx0, base)
        Font.place(cv, tpaths, left - tx0, base + t_gap + t_cap)
        right = left + max(wx1 - wx0, tx1 - tx0)
    else:
        base = MARK_H / 2 + cap / 2
        Font.place(cv, paths, left - wx0, base)
        right = left + (wx1 - wx0)
    return cv.svg(-PAD, -PAD, right + 2 * PAD, MARK_H + 2 * PAD, "IronDost")


def build_stacked(bold, semi, variant):
    mono, c_iron, c_dost, c_tag = VARIANTS[variant]
    cv = Canvas("s" + variant.replace("-", ""))
    word_size, t_size, gap_v, t_gap = 40, 11.5, 16, 10
    paths, (wx0, wy0, wx1, wy1) = bold.runs(wordmark_runs(c_iron, c_dost), word_size)
    tpaths, (tx0, ty0, tx1, ty1) = tagline_matching(semi, wx1 - wx0, t_size, c_tag)
    x0, _, x1, _ = MARKS["full"]["bounds"]
    mark_w = (x1 - x0) * MARK_H / (MARKS["full"]["bounds"][3] - MARKS["full"]["bounds"][1])
    width = max(mark_w, wx1 - wx0, tx1 - tx0)
    cv.mark((width - mark_w) / 2, 0, MARK_H, "full", mono)
    cap, t_cap = bold.cap * word_size, semi.cap * t_size
    base = MARK_H + gap_v + cap
    Font.place(cv, paths, (width - (wx1 - wx0)) / 2 - wx0, base)
    t_base = base + t_gap + t_cap
    Font.place(cv, tpaths, (width - (tx1 - tx0)) / 2 - tx0, t_base)
    return cv.svg(-PAD, -PAD, width + 2 * PAD, t_base + 2 * PAD, "IronDost")


def build_mark(kind, variant):
    mono = VARIANTS[variant][0]
    cv = Canvas(f"m{kind}" + variant.replace("-", ""))
    w = cv.mark(0, 0, MARK_H, kind, mono)
    return cv.svg(-PAD, -PAD, w + 2 * PAD, MARK_H + 2 * PAD, "IronDost")


def build_wordmark(bold, variant):
    _, c_iron, c_dost, _ = VARIANTS[variant]
    cv = Canvas("w" + variant.replace("-", ""))
    paths, (x0, y0, x1, y1) = bold.runs(wordmark_runs(c_iron, c_dost), 48)
    Font.place(cv, paths, -x0, -y0)
    return cv.svg(-PAD, -PAD, (x1 - x0) + 2 * PAD, (y1 - y0) + 2 * PAD, "IronDost")


# ---------------------------------------------------------------- icons


def square_icon(uid, size, bg, mark_width, kind="full", mono=None, rx=0):
    """Mark centred on a square canvas. bg=None keeps it transparent."""
    cv = Canvas(uid)
    if bg:
        cv.rect(0, 0, size, size, bg, rx)
    x0, y0, x1, y1 = MARKS[kind]["bounds"]
    h = mark_width * (y1 - y0) / (x1 - x0)
    cv.mark((size - mark_width) / 2, (size - h) / 2, h, kind, mono)
    return cv.svg(0, 0, size, size, "IronDost", size, size)


def og_image(bold, semi):
    w, h = 1200, 630
    cv = Canvas("og")
    cv.rect(0, 0, w, h, HEX["white"])
    lockup = build_horizontal(bold, semi, "", True)
    # Nest the tagline lockup, scaled up, in the middle of the card.
    scale = 2.8
    vb = lockup.split('viewBox="')[1].split('"')[0].split()
    lw, lh = float(vb[2]) * scale, float(vb[3]) * scale
    inner_svg = lockup.replace("<svg ", f'<svg x="{n((w - lw) / 2)}" y="{n((h - lh) / 2)}" width="{n(lw)}" height="{n(lh)}" ', 1)
    cv.body.append(inner_svg.replace("\n", ""))
    return cv.svg(0, 0, w, h, "IronDost", w, h)


# ---------------------------------------------------------------- tokens


def write_tokens():
    tokens = {
        "colors": PALETTE,
        "illustration": ILLUSTRATION,
        "fonts": {
            "display": {"family": "Outfit", "weights": [600, 700, 800], "use": "Wordmark, headings, numbers in marketing"},
            "body": {"family": "Figtree", "weights": [400, 500, 600], "use": "UI and body text"},
            "devanagari": {"family": "Noto Sans Devanagari", "weights": [400, 600], "use": "Hindi copy"},
            "mono": {"family": "Geist Mono", "weights": [400, 500], "use": "Order IDs, codes"},
        },
        "appIconBackground": HEX["white"],
    }
    out = ROOT / "tokens"
    out.mkdir(exist_ok=True)
    (out / "brand.json").write_text(json.dumps(tokens, indent=2) + "\n")
    css = ["/* IronDost brand tokens. Generated by scripts/build-svg.py; do not edit by hand. */", ":root {"]
    css += [f"  --irondost-{k}: {v['hex']};" for k, v in PALETTE.items()]
    css += [f"  --irondost-{k}: {v};" for k, v in ILLUSTRATION.items()]
    css += ['  --irondost-font-display: "Outfit", system-ui, sans-serif;', '  --irondost-font-body: "Figtree", system-ui, sans-serif;', "}"]
    (out / "brand.css").write_text("\n".join(css) + "\n")
    dart = [
        "// IronDost brand colours. Generated by packages/brand/scripts/build-svg.py; do not edit by hand.",
        "import 'package:flutter/painting.dart';",
        "",
        "abstract final class BrandColors {",
    ]
    for k, v in {**{k: v["hex"] for k, v in PALETTE.items()}, **ILLUSTRATION}.items():
        dart.append(f"  static const {k} = Color(0xFF{v.lstrip('#').upper()});")
    dart.append("}")
    (out / "brand_colors.dart").write_text("\n".join(dart) + "\n")


# ---------------------------------------------------------------- main


def main():
    font_dir = os.environ.get("OUTFIT_DIR")
    if not font_dir:
        sys.exit("Set OUTFIT_DIR to a folder containing Outfit-Bold.ttf and Outfit-SemiBold.ttf")
    bold = Font(Path(font_dir) / "Outfit-Bold.ttf")
    semi = Font(Path(font_dir) / "Outfit-SemiBold.ttf")

    logo = ROOT / "logo" / "svg"
    logo.mkdir(parents=True, exist_ok=True)
    for variant in VARIANTS:
        (logo / f"irondost-logo{variant}.svg").write_text(build_horizontal(bold, semi, variant, False))
        (logo / f"irondost-logo-tagline{variant}.svg").write_text(build_horizontal(bold, semi, variant, True))
        (logo / f"irondost-logo-stacked{variant}.svg").write_text(build_stacked(bold, semi, variant))
        (logo / f"irondost-wordmark{variant}.svg").write_text(build_wordmark(bold, variant))
        if variant != "-reverse":  # the colour mark already works on dark backgrounds
            (logo / f"irondost-mark{variant}.svg").write_text(build_mark("full", variant))
            (logo / f"irondost-mark-small{variant}.svg").write_text(build_mark("small", variant))

    icons = ROOT / "icons" / "src"
    icons.mkdir(parents=True, exist_ok=True)
    ink, white = HEX["ink"], HEX["white"]
    sources = {
        "app-icon.svg": square_icon("app", 1024, white, 800),
        "adaptive-foreground.svg": square_icon("afg", 1024, None, 520),
        "adaptive-monochrome.svg": square_icon("amono", 1024, None, 520, "small", ink),
        "maskable.svg": square_icon("mask", 512, white, 340),
        "favicon.svg": square_icon("fav", 64, white, 56, "small", rx=14),
        "favicon-tiny.svg": square_icon("favt", 64, white, 40, "glyph", rx=14),
        "notification.svg": square_icon("notif", 96, None, 88, "small", white),
        "social-avatar.svg": square_icon("avatar", 1080, white, 680),
        "og-image.svg": og_image(bold, semi),
    }
    for name, svg in sources.items():
        (icons / name).write_text(svg)

    write_tokens()
    print(f"Wrote {len(list(logo.glob('*.svg')))} logo SVGs, {len(sources)} icon sources and tokens.")


if __name__ == "__main__":
    main()
