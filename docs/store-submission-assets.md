# Store submission graphics

Current exports are built from the latest customer-app captures recorded on 5 October 2026. The export script is
[`build_store_assets.py`](../apps/customer/store/build_store_assets.py). Run it from the repository root with:

```sh
python3 apps/customer/store/build_store_assets.py
```

## App Store Connect

Upload the opaque icon at `apps/customer/store/app-store/app-icon-1024.png` and the five images in
`apps/customer/store/app-store/screenshots/`, in numeric order. They are 1260 × 2736 PNGs for the current 6.9-inch iPhone display.
The screenshots show the latest services, basket, pickup scheduling, checkout, and catalogue search screens.

The product page header is `apps/customer/store/app-store/header-3840x1646.png` (3840 × 1646, 21:9, no alpha, 5.1 MB). It is built from the same art as the
Play feature graphic by `create_app_store_header()` in the build script. Upload it under Distribution, the version, Header and Search Results, Header.
Apple accepts either 3840 × 1646 or 5244 × 2950. Apple processes a new header for a few minutes before it shows a thumbnail. The art source is only 1795 px
wide, so the header is upscaled about 2x; regenerate the art at a higher resolution if it looks soft.

Apple accepts 1–10 PNG or JPEG screenshots per device display and disallows alpha channels. Its current 6.9-inch display sizes
include 1260 × 2736; Apple scales these to compatible devices when no matching size is supplied. See [Apple's current screenshot
specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/).

## Google Play Console

Upload `apps/customer/store/google-play/icon-512.png`, `apps/customer/store/google-play/feature-graphic.png`, and the five PNGs in
`apps/customer/store/google-play/screenshots/`, in numeric order. The feature graphic is 1024 × 500. Each phone screenshot is
1080 × 1920, with the current app display centered on a mist-blue edge fill so the complete interface remains visible at Google's
recommended 9:16 portrait ratio.

Google Play requires a 512 × 512 32-bit PNG icon, a 1024 × 500 JPEG or 24-bit PNG feature graphic, and at least two screenshots.
Four or more 1080 × 1920 portrait screenshots are recommended for screenshot-based recommendation surfaces. Screenshots should
show actual app use; feature-graphic and screenshot copy must not make time-sensitive discount claims. See [Google Play preview
asset requirements](https://support.google.com/googleplay/android-developer/answer/9866151?hl=en-en) and [Google Play icon
guidance](https://developer.android.com/distribute/google-play/resources/icon-design-specifications).

## Asset sources and review

- Screenshot sources: `docs/ui-ux-audit/after/native-catalogue.png`, `native-basket.png`, `native-schedule.png`,
  `native-checkout.png`, and `native-search.png`. The build script crops away the Simulator window and device bezel, then exports
  both platform sizes. This keeps the current app UI intact.
- Google Play feature-graphic source: `apps/customer/store/google-play/feature-art-source.png`, generated with the built-in image
  generator. The final graphic adds the approved IronDost name and Hyderabad service-area line in the brand fonts and colors.
- Icons come from `packages/brand/icons/ios/AppIcon.appiconset/AppIcon-1024.png` and
  `packages/brand/icons/android/play-store-512.png`.
- Earlier Phase 6 captures are retained under `apps/customer/store/archive/phase6-2026-10-03/`; they are superseded and should not
  be uploaded.

The latest test captures include fictional sample addresses, prices, dates, and order data. Replace them with clean, current demo
data and recapture before a public release if service prices, dates, or fulfillment states change. In particular, the newest sample
order-tracking capture contains an already-past estimate, so the current export set leaves it out.

## Image-generation prompt

> Create a premium, horizontal 1024x500 Google Play feature-graphic background illustration for IronDost, a friendly laundry
> pickup and ironing service in Hyderabad. Use a polished editorial 3D still life: freshly laundered white and sky-blue shirts folded
> neatly, a modern steam iron, a soft cotton laundry bag, cloth folds and gentle water droplets in bright morning light. Anchor the
> palette in royal blue #1F4FD1, sky #3FB8EA, ink navy #0E1E3D, mist #E6EEF8 and white, with a small sunshine-yellow #FFC93C accent.
> Put the laundry still life on the right half, leaving the left 43% clean for typography. Use a vibrant blue field with subtle fabric
> and water motifs. No text, logos, app UI, discount badges or prices.

## Remaining release work

The graphics are packaged. The app still needs the signing keys, production API and payment configuration, store privacy/data-safety
answers, a reviewer test number, and final policy review listed in [`customer-app-release.md`](customer-app-release.md) before
binary submission.
