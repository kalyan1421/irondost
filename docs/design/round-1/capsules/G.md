# Direction G

## Premise (subject evidence)
Pricing is per piece and customers compare it before anything else. The amount is the news, so it is the largest thing on the page and the currency sign and item name become the small print around it.

## Fonts
- Figures: Chunk Five (Meredith Mandel), v2.001, SIL OFL 1.1, from github.com/theleagueof/chunk. Lacks ₹.
- Text: TeX Gyre Pagella 2.004 (GUST), Bold and Regular, GUST Font License (LPPL 1.3c based; free to use and redistribute), CTAN distribution. Lacks ₹.
- ₹ glyph: Charis Bold (SIL OFL 1.1, family "Rs", U+20B9 only), set small beside the figure. Provisional.

## Hierarchy and type roles
1. Figures: Chunk Five, clamp(5.6rem, 35vw, 15rem), line height 0.86, tracking -0.02em.
2. ₹: 0.26em, Pagella Bold, raised to the top of the figure.
3. Item names: Pagella Bold 1.1rem, set above the figure's midline; "per piece" Pagella 0.95rem below it.
4. Other copy: Pagella 1.05rem, line height 1.4, max 34ch. "Get started": Chunk Five 1.9rem.

## Case, spacing, line rules
Sentence case as supplied. Price rows 0.4rem apart; the remaining copy starts 3.2rem below; grouped lines 2.6rem apart.

## Colour
Canvas #FFF1B5. Two active text colours: brown-red #8C2A0F (primary, the price figures and "Get started", about 55% by area) and near-black #1A1408 (secondary, everything else, about 45%).

## Space and placement
Left-aligned. Each price is a two-column grid: figure, then name over "per piece" centred on the figure's midline. Side padding clamp(1.25rem, 6vw, 5rem).

## Signature typographic relationship
A giant slab figure with a small raised ₹ and a two-line label at its midline.

## Invariants / allowed variation / prohibited normalization
- Invariant: price is the largest element; ₹ is small and raised; labels sit at the figure's midline.
- May vary: the figure face if it stays heavy and numerical; hue pair.
- Must not: show prices as small grey secondary text; add price tags, badges or strikes.

## Assumptions and risks
Prices are provisional working copy; three-digit prices or ranges would break the proportion. A giant price may feel like discounting. ₹ is from another face. Telugu numerals are not covered.

## Round 2 translation
Service menu and basket lines where the price is the lead; quote and total screens; offers.
