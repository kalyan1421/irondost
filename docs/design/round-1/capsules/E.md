# Direction E

## Premise (subject evidence)
Clothes come back hanging: crisp, vertical, each piece a different length on the same rail. The type is narrow and tall, and the supporting lines hang from one top edge at their own lengths.

## Fonts
Ostrich Sans (Tyler Finck), v1.002, Heavy and Medium, SIL OFL 1.1, from github.com/theleagueof/ostrich-sans. All capitals; lacks ₹. Fallback: ₹ from Charis Bold (family "Rs", U+20B9 only). Provisional.

## Hierarchy and type roles
1. Headline: Heavy, clamp(4.6rem, 27vw, 15rem), line height 0.82, one word group per line (Fresh / clothes, / back at / your / door.).
2. Wordmark: Heavy 1.5rem, tracking 0.14em.
3. Rail lines: Medium, clamp(1.4rem, 5.4vw, 2.1rem), line height 1.05, tracking 0.07em, vertical writing mode (top to bottom, mixed orientation). "Get started" in Heavy.

## Case, spacing, line rules
Uppercase by transform and by design of the face. Rail columns sit clamp(0.9rem, 2.6vw, 1.8rem) apart and wrap onto rows 2.6rem apart; the rail starts 4.5rem below the headline.

## Colour
Canvas #0E3B2C. Three active text colours:
- Primary, cream #F3EFE2: wordmark, headline, the ironing sentence, "Get started" (about 55% by area).
- Secondary, saffron #F5B93A: the time lines and "Your partner arrives within the window you pick." (about 25%).
- Tertiary, pink #FF8FA3: prices, the rough-count sentence and the payment line (about 20%).
Saffron is time; pink is money.

## Space and placement
Left-aligned headline; the rail is a flex row, tops aligned, so each column hangs to its own length. Side padding clamp(1.25rem, 5vw, 4rem); top padding clamp(1.5rem, 5vh, 3.5rem).

## Signature typographic relationship
Tall narrow capitals stacked at the left; lines hanging from a shared top edge in different lengths, each colour marking a kind of information.

## Invariants / allowed variation / prohibited normalization
- Invariant: narrow tall capitals; vertical hanging lines with tops aligned; three colour roles (cream, time, money).
- May vary: hues, line breaks of the headline, number of columns per row.
- Must not: lay the rail horizontally to "make it readable" without replacing the idea; add hanger drawings.

## Assumptions and risks
Vertical Latin text is slow to read and is hard for screen magnifiers; interface text would need a horizontal companion. The face is Latin-only and capitals-only. ₹ is borrowed from another face.

## Round 2 translation
Large display headings and short labels in this face; vertical lines only for non-critical metadata such as status tags; interface rows set horizontally in a companion face chosen after the lock.
