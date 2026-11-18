# Direction F

## Premise (subject evidence)
The service is a round trip: out from the door (booking and pickup), through the workshop (counting, washing, pressing), and back to the door (delivery and payment). The page walks that route: lines step to the right on the way out and back to the left on the way home.

## Fonts
Junction (Caroline Hadilaksono), v1.056, Light, Regular, Bold, SIL OFL 1.1, from github.com/theleagueof/junction. Lacks ₹. Fallback: ₹ from Charis Regular and Bold (family "Rs", U+20B9 only). Provisional.

## Hierarchy and type roles
1. Headline: Bold, clamp(2.1rem, 8.4vw, 4.8rem), line height 1.02, tracking -0.02em, max 12em.
2. Body: Regular 1.15rem, line height 1.4. Wordmark Bold. The ironing sentence in Light. "Get started" Bold 1.5rem.

## Case, spacing, line rules
Sentence case as supplied. Lines are 1.5rem apart; list lines 0.15rem apart; headline to first line 3rem.

## Colour
Canvas #EEF1F3. Three active text colours, one per leg:
- Primary, indigo #2E3FA3: the way out (headline, the choice of times, the windows, the partner's arrival), about 50%.
- Secondary, graphite #23262B: the workshop (wordmark, rough count and confirmation, ironing and washing), about 20%.
- Tertiary, orange #D4531A: the way back (prices, payment, "Get started"), about 30%.

## Space and placement
Indent step s = min(8.5vw, 4.4rem). Left indent in steps by line: headline 0, choose-times 1, windows 2, partner arrives 3, rough-count and ironing 4 (the turn), prices 3, payment 2, "Get started" 0. Side padding clamp(1.25rem, 5vw, 4rem).

## Signature typographic relationship
Indentation traces the journey, out and back; colour changes at the turn.

## Invariants / allowed variation / prohibited normalization
- Invariant: stepped left indents that rise and fall; one colour per leg; the turn is the deepest indent.
- May vary: number of steps, hues, which lines belong to which leg.
- Must not: add arrows or path lines; flatten the indents to a straight left edge.

## Assumptions and risks
Deep indents shorten lines at narrow widths (the deepest line has about 64% of the width). Needs a check at 200% text size and in Telugu, which sets taller.

## Round 2 translation
Order tracking as the same walk: status lines step out and back as the order moves; booking screens use the indents as progress.
