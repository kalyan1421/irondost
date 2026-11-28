# AddressCard

A saved address in the address book and the checkout address picker.

## Consumer provides
- `address` from `GET /v1/me/addresses`: `label` (Home, Work or the customer's own), `houseNo`, `building`, `street`, `area`, `landmark`, `city`, `pincode`, `formatted`, `isPrimary`.
- `selected`/`onTap` in pickers; `onEdit` in the address book.

## Layout
- 40px icon tile (`house`, `briefcase`, `map-pin`), the label in `title`, a "Default" info chip when `isPrimary`, then the address in `body`/`text-muted`, wrapping to three lines.
- In pickers the selected card has a 2px `primary` border plus a check; in the address book a trailing pencil icon button (48×48) edits.

## Do / Don't
- Do show the landmark: partners rely on it.
- Don't show coordinates or the raw pincode alone.
