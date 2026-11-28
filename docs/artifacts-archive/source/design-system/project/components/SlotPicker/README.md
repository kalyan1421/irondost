# SlotPicker

Chooses the pickup (and later delivery) date and time window. Dates scroll horizontally; the three windows stack below.

## Consumer provides
- `days` and `slots` from `GET /v1/schedule/pickup-slots` (or `GET /v1/schedule/delivery-slots`): each `SlotOptionDto` has `date`, `slot` (MORNING | NOON | EVENING), `label`, `startsAt`, `endsAt`, `available`.
- `selected`, `onSelected`.

## Behaviour
- Date tiles 64 wide: weekday (`caption`, upper case) over day number (Outfit 20/700). Selected: `primary` fill, `on-primary` text. Show "Today"/"Tomorrow" instead of the weekday for the first two.
- Slot rows: name ("Morning") over time ("7 – 11 AM"), radio on the right. Selected: `primary-soft` fill with a 2px `primary` border.
- Unavailable slots stay visible at 50% with a reason ("Too soon" when inside the 20-hour turnaround, "Closed" once the window has started) so the list never jumps.
- Delivery slots start at pickup + 20h; the picker only shows what the API returns.

## Accessibility
Each slot is a radio in one group: "Evening, 4 to 8 PM, available, not selected".
