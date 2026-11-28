# Order status

One vocabulary for every app. The API status is the source of truth. Each app shows its own label, and the customer app shows fewer distinct steps: it never mentions internal dispatch.

| API status | Customer label | Customer timeline step | Partner label | Admin label | Chip tone |
|---|---|---|---|---|---|
| `PENDING` | Booked | 1 · Booked | — | Awaiting pickup partner | info |
| `PICKUP_ASSIGNED` | Partner assigned | 1 · Booked (partner shown) | Pickup | Pickup assigned | info |
| `PICKED_UP` | Picked up | 2 · Picked up | Picked up | Picked up | info |
| `PROCESSING` | Being ironed | 3 · Ironing | — | At workshop | info |
| `READY_FOR_DELIVERY` | Ready | 3 · Ironing (done) | — | Ready for delivery | info |
| `DELIVERY_ASSIGNED` | Out for delivery soon | 4 · Out for delivery | Delivery | Delivery assigned | accent |
| `OUT_FOR_DELIVERY` | Out for delivery | 4 · Out for delivery | On the way | Out for delivery | accent |
| `DELIVERED` | Delivered | 5 · Delivered | Delivered | Delivered | success |
| `CANCELLED` | Cancelled | (timeline replaced by a cancelled card) | Cancelled | Cancelled | neutral |

**Chip tones:**
- **info:** `primary-soft` background, `on-primary-soft` text
- **accent:** `surface-soft` background, `accent` text with the truck icon
- **success:** `success-soft` background, `success` text with a check icon
- **neutral:** `surface-soft` background, `text-muted` text
- **Payment:** unpaid orders add a separate **warning** chip ("₹180 due"). Status and payment are never merged into one chip.
