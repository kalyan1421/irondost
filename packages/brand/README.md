# @laundry/brand

IronDost logo, app icons, social images and colour tokens. Everything here is
generated from one master drawing in `scripts/build-svg.py`; edit that, never
the output files.

## The mark

A front-load washing machine with a steam iron parked in front of it and soap
bubbles rising: wash, iron, deliver. App icons, favicons and avatars put the
colour mark on white. The wordmark is Outfit Bold, "Iron" in ink
and "Dost" in royal, converted to outlines so the SVGs need no font installed.

## What's here

| Path | Contents |
| --- | --- |
| `logo/svg`, `logo/png` | Horizontal logo, logo with tagline, stacked logo, mark, small mark (48px and below) and wordmark. Each comes in colour, `-reverse` (dark backgrounds), `-mono-ink` and `-mono-white`. The colour mark already works on dark backgrounds, so marks have no `-reverse` file. |
| `icons/ios/AppIcon.appiconset` | Single 1024px opaque icon for Xcode 14+. |
| `icons/android` | Adaptive icon foreground and monochrome layers (background colour `#FFFFFF`), Play Store 512px icon, white notification icons per density. |
| `icons/web` | `favicon.ico` (washer glyph at 16px, small mark at 32/48px), `favicon.svg`, Apple touch icon, PWA icons including a maskable one. |
| `icons/flutter_launcher_icons.yaml` | Config for generating every launcher size in the Flutter apps. |
| `social` | 1080px avatar and the 1200×630 Open Graph image. |
| `tokens` | `brand.json`, `brand.css` (CSS custom properties) and `brand_colors.dart` (Flutter). |

## Colours

| Token | Hex | Use |
| --- | --- | --- |
| ink | `#0E1E3D` | Text, outlines, dark surfaces |
| royal | `#1F4FD1` | Primary actions, links, "Dost" |
| sky | `#3FB8EA` | Water, fills, accents on dark. Not a text colour on light backgrounds (2.3:1). |
| ocean | `#1A73B0` | Sky's text-safe partner on light backgrounds (5.1:1) |
| sun | `#FFC93C` | Highlights and offers, always with ink text |
| mist | `#E6EEF8` | Panels and soft surfaces |

Fonts: Outfit (display and headings), Figtree (UI and body), Noto Sans
Devanagari (Hindi), Geist Mono (order IDs).

## Rebuilding

```bash
pip install fonttools
OUTFIT_DIR=/path/to/outfit-ttfs pnpm --filter @laundry/brand build
```

`OUTFIT_DIR` must contain `Outfit-Bold.ttf` and `Outfit-SemiBold.ttf` from
Google Fonts. `build:svg` writes the SVGs and tokens; `build:png` (sharp)
rasterises them. After rebuilding, copy `icons/web/favicon.ico`,
`icons/web/favicon.svg` (as `icon.svg`) and `icons/web/apple-touch-icon.png`
(as `apple-icon.png`) into `apps/admin/src/app/`. The admin `BrandMark`
component inlines the small mark; update it if the drawing changes.
