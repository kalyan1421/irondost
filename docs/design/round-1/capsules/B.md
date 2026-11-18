# Direction B

## Premise (subject evidence)
The promise is a window, not a time: Morning 7 – 11 AM, Afternoon 11 AM – 4 PM, Evening 4 – 8 PM (4, 5 and 4 hours). "Your partner arrives within the window you pick." The size of a window is the information, so the type size follows its duration and its position follows when it starts.

## Fonts
Monaspace Neon, variable (weight 200–800, width 100–125, slant), GitHub Next, v1.400, SIL OFL 1.1, from github.com/githubnext/monaspace (variable web fonts). Contains ₹. No fallback in use.

## Hierarchy and type roles
1. Window numerals: weight 700, tracking -0.03em, line height 0.92, size = u × 4 (Morning), u × 5 (Afternoon), u × 4 (Evening), where u = min(5.4vw, 3.4rem). Each set on two lines (7 – / 11 AM; 11 AM / – 4 PM; 4 – / 8 PM).
2. Headline: weight 700, clamp(1.6rem, 6.2vw, 3.2rem), line height 1.08, tracking -0.02em, max 15ch.
3. Window names: 0.9rem, weight 500, uppercase, tracking 0.22em.
4. Body: 0.95rem, weight 400, line height 1.5, max 34ch.

## Case, spacing, line rules
Sentence case for body; uppercase for window names. No hyphenation. Window blocks are 3.4rem apart; the headline sits 3.2rem below the wordmark.

## Colour
Canvas #0B1530. Four active text colours:
- Primary, cream #F1ECDD: wordmark, headline, all body copy, prices (about 35%).
- Secondary, amber #F5C25B: the Morning name and numerals (about 22%).
- Tertiary, pale blue #A9DDF5: the Afternoon name and numerals (about 25%, largest block).
- Accent, coral #FF8F73: the Evening name and numerals (about 18%).
The three window colours mark time of day and the reading order of the day.

## Space and placement
Left-aligned. Outer padding clamp(1.25rem, 6vw, 5rem) sides. Window blocks are indented by their start time after 7 AM: Morning 0, Afternoon 0.89u, Evening 2u.

## Signature typographic relationship
Size proportional to window length and indent proportional to start time, so the three windows read as a day laid on its side; the colour of each window is the colour of that part of the day.

## Invariants / allowed variation / prohibited normalization
- Invariant: size and offset derived from the windows; one colour per window; one monospaced family.
- May vary: the three window hues, the base canvas, line breaks of the numerals.
- Must not: give all windows the same size; add icons for sun or moon; introduce a fifth colour.

## Assumptions and risks
Window times are working copy; if windows change, the proportions are recalculated. Monospace body text is wide at small sizes; check line length at 200% text size. The relationship holds only for three windows.

## Round 2 translation
Slot picker with sized and offset window options; the colour of the chosen window carries into the order summary and tracking; body text may move to a narrower companion face if the locked direction allows.
