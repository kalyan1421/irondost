# Direction A

## Premise (subject evidence)
Price is per piece, so an order is a count. Neighbourhood ironing has long worked from a tally of pieces: names on the left, amounts in a column on the right. The partner's confirmation at pickup is a second hand correcting the first count.

## Fonts
- Words: Charis (SIL Global), v7.000, SIL OFL 1.1, from github.com/silnrsi/font-charis. Regular, Italic, SemiBold. Contains ₹.
- Figures: TeX Gyre Cursor 2.004 (GUST), GUST Font License (LPPL 1.3c based; free to use and redistribute), from the CTAN distribution. Lacks ₹.
- Fallback: ₹ in the figure columns comes from Charis Regular (loaded as family "Rs" for U+20B9 only). This is a provisional metric match, not proof of the final glyph.

## Hierarchy and type roles
1. Headline: Charis SemiBold, clamp(1.9rem, 6.6vw, 2.55rem), line height 1.12, tracking -0.005em.
2. Body: Charis Regular 1.125rem, line height 1.45.
3. Labels (Morning, Afternoon, Evening) and wordmark: Charis all-small-caps, tracking 0.07em and 0.14em.
4. Figures (times, prices): Cursor 1.05rem, tabular, right-aligned in their column.
5. Notes (the two partner sentences, "per piece", the ask): Charis Italic.

## Case, spacing, line rules
Sentence case as supplied; small caps for labels. No hyphenation. Rows are separated by 0.85rem; groups by 4.2rem. No rules or lines between rows.

## Colour
Canvas #F2EADA. Ink #1E1A14, primary, about 77% of text. Red pencil #A8321F, secondary, about 23%: used only for the two sentences in the partner's voice ("Your partner arrives within the window you pick." and "A rough count is fine. Your partner confirms it at pickup.").

## Space and placement
Single left-aligned column, max 34rem. Left margin clamp(1.25rem, 10vw, 9rem); top padding clamp(2.5rem, 9vh, 6rem); bottom 9rem. Item rows use three columns: name (flexible), price (3.2rem), "per piece" (5.3rem, right-aligned). Window rows use two columns: label, time (right-aligned).

## Signature typographic relationship
Typewriter figures aligned to the right edge of each row, set against serif descriptions; red is reserved for what the partner says or confirms.

## Invariants / allowed variation / prohibited normalization
- Invariant: right-aligned typewriter figures; red limited to the partner's voice; no rules between rows.
- May vary: column widths, row spacing, the exact red and cream values, the serif used for words.
- Must not: add boxes, striped rows or card surfaces; use red for errors or price highlights; centre the ledger.

## Assumptions and risks
Item names and prices are provisional working copy. Cursor has no Telugu or Hindi; script coverage is open. Dense rows need a check at 200% text size.

## Round 2 translation
Item list, basket and order bill as ledger rows; subtotal and total as right-aligned figures; partner confirmations and corrected counts in the red voice; empty states written as ledger notes.
