# ServiceItemRow

One catalogue item in the "Iron" or "Dry clean" list: picture, name, price per piece and the quantity stepper.

## Consumer provides
- `item` from `GET /v1/catalog`: `name`, `imageUrl` (nullable), `pricePaise`, `offerPricePaise` (nullable), `effectivePricePaise`, `unit` (`PIECE` shows "per piece").
- `count`, `onChanged`.

## Layout
- Thumb `thumb` (56) at `radius-sm` on `surface-soft`; with no image, show the category's Lucide icon in `primary`.
- Name in `body-lg`/600; price in `label` with tabular figures; when `offerPricePaise` is set, the offer price followed by the struck-through `pricePaise` in `text-muted`; unit in `caption`.
- Rows divide with a 1px `border`; no cards inside the list.

## Do / Don't
- Do format money as "₹15" (no decimals when whole), "₹12.50" otherwise.
- Don't truncate item names; wrap to two lines.
