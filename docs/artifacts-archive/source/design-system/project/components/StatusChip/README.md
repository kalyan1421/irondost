# StatusChip

The order's status in the customer's words, colour-coded by tone. Labels and tones come from **Order status**.

## Consumer provides
- `status` (API enum). The widget maps it to label, tone and icon; never pass free text.

## Tones
| Tone | Fill / text | Statuses |
|---|---|---|
| info | `primary-soft` / `on-primary-soft` | Booked, Partner assigned, Picked up, Being ironed, Ready |
| accent | `surface-soft` / `accent` + truck | Out for delivery soon, Out for delivery |
| success | `success-soft` / `success` + check | Delivered |
| neutral | `surface-soft` / `text-muted` | Cancelled |
| warning | `warning-soft` / `warning` | Payment due ("₹180 due"), a separate chip |
| offer | `offer` / `on-offer` | Promotions only ("20% off"), never a status |

Height 28, `radius-full`, `label-sm`.
