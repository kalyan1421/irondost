# CartBar

The sticky bar at the bottom of the catalogue once the cart has items: count, total, and the one forward action.

## Consumer provides
- `itemCount`, `totalPaise`, `onContinue`.

## Behaviour
- `surface` with `shadow-sheet`, top corners `radius-xl`, sits above the bottom nav and the safe area.
- Slides up 200ms ease-out when the first item is added; the total ticks with a 150ms crossfade.
- If the order is below the minimum, the button reads "Add ₹49 more" and is disabled, with the reason in the count line.
