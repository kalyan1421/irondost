# PromoCard

A promotion or banner on Home and Offers: headline, short condition, code chip, soap-bubble decoration.

## Consumer provides
- `title` ("20% off your first order"), `terms` ("Up to ₹100 · Min. order ₹299"), `code` (nullable), optional `imageUrl` (admin banner) and `onTap`.

## Layout
- `offer-soft` ground, radius `radius-lg`, padding 20. Title in `title-lg` Outfit, up to 75% width.
- The code sits in a dashed outline chip in Geist Mono; tapping it copies and shows a Snackbar "Code WELCOME20 copied".
- Bubbles: two or three `illo-foam` circles with a 2.5px `ink` outline bleeding off the right edge. Decorative, hidden from screen readers.
- Admin banners with an image replace the ground with the image (2:1, `radius-lg`) and keep the code chip.

## Do / Don't
- Don't stack more than one promo above the fold on Home. Don't animate the bubbles.
