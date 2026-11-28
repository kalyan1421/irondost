# OrderTimeline

The five customer steps of an order, top to bottom: Booked → Picked up → Ironing → Out for delivery → Delivered.

## Consumer provides
- `order.status` and `order.events` (timestamps). Step mapping is in **Order status**.

## States
- **Done:** filled `primary` dot with a check, `primary` connector, time in `caption` ("Today, 9:42 AM").
- **Current:** ring dot with a `primary-soft` halo, title in `label`, a meta line with the next promise ("Arrives Sat, 4 – 8 PM").
- **Future:** hollow `border-strong` dot, title in `text-muted`.
- **Cancelled:** the timeline is replaced by a neutral card with the reason and refund note.

## Motion
The current dot's halo pulses once on arrival (300ms) and only when reduced motion is off. Realtime updates (Socket.IO `order.updated`) advance the step with a 200ms crossfade.

## Accessibility
Read as a list: "Step 3 of 5, Ironing, in progress".
