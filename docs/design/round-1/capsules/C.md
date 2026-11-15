# Direction C

## Premise (subject evidence)
"Dost" means friend. The service is a friend who irons, so the app speaks the way a friend speaks: in large, lowercase, unhurried lines. The practical facts (times, prices, payment) are what the friend says quietly afterwards.

## Fonts
- TeX Gyre Bonum 2.004 (GUST), Regular, Italic, Bold. GUST Font License (LPPL 1.3c based; free to use and redistribute), CTAN distribution. Lacks ₹.
- Fallback: ₹ from Charis Regular (SIL OFL 1.1, family "Rs", U+20B9 only). Provisional.

## Hierarchy and type roles
1. Friend, large: Bonum Italic, clamp(2.4rem, 11.5vw, 6.6rem), line height 1.02, tracking -0.015em, lowercase, max 11em.
2. Friend, medium: Bonum Italic, clamp(1.4rem, 5.6vw, 2.6rem), line height 1.15, lowercase, max 15em.
3. System asides: Bonum Regular 1.05rem, line height 1.5, max 24ch, indented clamp(1.5rem, 16vw, 12rem).
4. Wordmark: Bonum Bold 1.25rem; "Iron" in ink, "Dost" in the friend colour. "Get started": Bonum Bold 1.2rem.

## Case, spacing, line rules
The friend's lines are lowercase by transform (source text keeps its capitals); the wordmark is not transformed. The large line starts 16vh below the wordmark; later friend lines are 12vh apart; asides sit 2.2rem under the line they answer.

## Colour
Canvas #FCEBDD. Two active text colours: tomato #C23B22 (primary, the friend's voice, about 62%) and ink #2B1B17 (secondary, the system's asides and "Iron", about 38%).

## Space and placement
Left-aligned, ragged right. Side padding clamp(1.25rem, 7vw, 6rem). The friend's lines hang at the left margin; the asides are pushed in.

## Signature typographic relationship
Voice by position and size: big italic lowercase at the margin is the friend; small upright text indented beneath is the fact.

## Invariants / allowed variation / prohibited normalization
- Invariant: two voices (italic lowercase large, upright small indented); "Iron" and "Dost" in different colours.
- May vary: the exact warm hues; which sentences are the friend's.
- Must not: set prices or buttons in the friend's voice; use all caps; add exclamation marks or emoji.

## Assumptions and risks
Lowercase transform on "your partner arrives…" may read as casual to some customers; confirm tone with the business. Bonum is a wide, heavy serif; Telugu and Hindi pairing is open.

## Round 2 translation
Greeting, empty states, order confirmation and tracking messages in the friend's voice; forms, totals and payment in the system voice.
