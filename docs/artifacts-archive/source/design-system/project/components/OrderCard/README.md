# OrderCard

An order in the Orders list and the Home "active order" slot. Tapping opens order details.

## Consumer provides
- `order`: `number` ("ID001042"), `status`, `itemCount`, `summary` ("8 shirts, 2 trousers"), `pickup` and `delivery` slot, `totalPaise`, `paymentStatus`.

## Layout
- `id-card` (radius `radius-lg`, `shadow-card`; in dark a 1px `border` instead of shadow).
- Header: order number in `order-id` (Geist Mono) and the StatusChip.
- Pickup and delivery in a `surface-soft` panel as label/value pairs.
- Footer: total in Outfit 18/700 and, when unpaid, the warning chip; the trailing action is a `text` button ("Track", "Pay now", "Reorder").

## Do / Don't
- Do show the next thing that happens, not the history.
- Don't show more than one action button on a card.
