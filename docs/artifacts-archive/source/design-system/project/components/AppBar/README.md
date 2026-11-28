# AppBar

The top bar. Two forms: the Home header (logo, address, bell) and the standard title bar with back.

## Consumer provides
- `title` or the Home form's `addressLabel`; `onBack` (shown on every pushed screen); up to two trailing icon actions.

## Layout
- Height `app-bar` (56), `surface`, title in `title-lg` (Outfit). No shadow at rest; a 1px `border` hairline appears once content scrolls under it.
- Icon buttons are 48×48 with a tooltip/semantic label. The notification bell shows a `danger` dot for unread items.
- Home: the address line ("Home · Banjara Hills" + chevron) opens the address picker sheet.
