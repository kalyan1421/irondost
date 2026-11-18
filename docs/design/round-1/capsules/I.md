# Direction I

## Premise (subject evidence)
"A rough count is fine. Your partner confirms it at pickup." The customer's count is approximate; the partner's count is exact. The page gives each of them a voice: loose and italic for the customer, precise and monospaced for the partner.

## Fonts
- Rough voice: TeX Gyre Schola Italic 2.004 (GUST), GUST Font License (LPPL 1.3c based; free to use and redistribute), CTAN distribution. Lacks ₹ (not used in the rough lines).
- Exact voice: Departure Mono (Helena Zhang), v1.500, SIL OFL 1.1, from github.com/rektdeckard/departure-mono. Contains ₹.
- Fallback: ₹ in rough lines would come from Charis Italic (family "Rs"); none present in the current copy.

## Hierarchy and type roles
1. Rough, large: Schola Italic, clamp(2.6rem, 12vw, 7rem), line height 1.08, tracking -0.015em, max 9em (headline only).
2. Rough, medium: Schola Italic, clamp(1.7rem, 6.4vw, 3.2rem), max 12em. "A rough count is fine." sits 6vw further in.
3. Exact: Departure Mono 0.8rem, line height 1.55, tracking 0.06em, uppercase, right-aligned, max 27ch.

## Case, spacing, line rules
Rough lines: sentence case, italic. Exact lines: uppercase by transform. Rough lines are 4.6–5.5rem apart from the previous exact block; each exact block is 2.2rem under the rough line it answers; grouped lines 0.15rem apart. The sentence "A rough count is fine. Your partner confirms it at pickup." is split across the two voices.

## Colour
Canvas #E4E2EC. Two active text colours: burnt umber #8A3B12 (primary, the customer's rough voice, about 62% by area) and navy #0E2A6B (secondary, the partner's exact voice, about 38%).

## Space and placement
Rough voice flush left; exact voice flush right in a narrow column. Side padding clamp(1.25rem, 6vw, 5rem); top padding clamp(1.5rem, 5vh, 3.5rem); the wordmark is in the exact voice at the top right, 5rem above the headline.

## Signature typographic relationship
Two voices in a conversation: large, loose, left and italic answered by small, tight, right and mono.

## Invariants / allowed variation / prohibited normalization
- Invariant: customer's lines italic and left; partner's lines mono, uppercase and right; the split sentence.
- May vary: the two hues; which lines belong to whom; the pair of faces if one stays loose and one stays exact.
- Must not: use the exact voice for headlines or the rough voice for prices and times.

## Assumptions and risks
Pixel-like mono at 0.8rem may be hard to read in sunlight; size and weight need testing. All-caps mono for windows and prices may feel cold. The wordmark in the exact voice replaces a brand lockup for now.

## Round 2 translation
Item counts: the customer's rough estimate in the rough voice, the partner's confirmed count in the exact voice; chat-like order updates; bill lines in the exact voice.
