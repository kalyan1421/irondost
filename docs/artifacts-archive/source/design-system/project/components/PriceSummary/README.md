# PriceSummary

The bill on Cart, Checkout and Order details. Mirrors the API pricing exactly; the app never computes totals itself.

## Consumer provides
- `quote` from `POST /v1/orders/quote` (or the order): `itemsTotalPaise`, `discountPaise`, `deliveryFeePaise`, `totalPaise`, `promoCode`.

## Layout
- Rows in `body` with tabular figures, amounts right-aligned.
- Discount row in `success` with the code ("WELCOME20 applied"). A zero delivery fee shows "Free" (struck original in `text-muted` when waived).
- Total under a dashed `border-strong` rule in Outfit 18/700.
- Under the total on Checkout, one line in `caption`: "Final amount may change if items differ at pickup."
