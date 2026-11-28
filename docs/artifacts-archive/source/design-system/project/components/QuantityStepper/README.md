# QuantityStepper

Adds an item to the cart and changes its count. Starts as an outlined "Add" pill and becomes a filled stepper at 1.

## Consumer provides
- `count`, `onChanged(count)`, optional `max` (default 50).

## Behaviour
- Pill height 36 inside a 48×48 hit area. Count in `label` with tabular figures.
- Decrementing from 1 removes the item (the stepper turns back into "Add"). No confirmation; the cart bar updates instantly.
- Light haptic on each change. At `max`, the plus is disabled.

## Accessibility
Buttons labelled "Remove one Shirt" / "Add one Shirt"; the count is announced as "2 Shirts in cart".
