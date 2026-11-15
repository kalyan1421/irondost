# Reference screenshots (competitors)

**Reference only. Never shipped, never copied into the IronDost app, store listing, website or ads.** They exist so layouts can be compared and colours measured. Saved 2026-11-07 with the project owner's yes ("competitor screenshots save yes").

Everything here is a public app-store listing image. No app was installed or logged into, no account was used, and nothing was taken from the apps' code or network traffic.

## Where each file came from

| Folder | Files | Source | How I got the URL |
|---|---|---|---|
| `dhobilite/` | `ios-01..07.jpg` (1242×2208) | App Store listing, India storefront, id 1128126966 | Apple's public iTunes Lookup API (`itunes.apple.com/lookup?id=…&country=in`), full-size variant of each listed image |
| `dhobilite/` | `play-01..07.jpg` (720×1440) | Google Play listing `com.dhobilite`, en_IN | Image IDs read from the listing page's HTML; fetched at 720 px wide |
| `tumbledry/` | `ios-01..08.jpg` (1242×2208) | App Store, id 1481554539 | iTunes Lookup API |
| `tumbledry/` | `play-01..08.jpg` (720×1280) | Google Play `com.quickdrycleaning.tumbledry` | listing page HTML |
| `fabrico/` | `ios-01..06.jpg` (1242×2688) | App Store, id 1541387385 | iTunes Lookup API (its 5 iPad images were not saved) |
| `fabrico/` | `play-01..07.jpg` (720×1600) | Google Play `in.fabrico.knoty` | listing page HTML |

| `laundrymate/` | `ios-01..06.jpg` (1242×2208), `play-01..06.jpg` (720×1280) | App Store id 1632839902 and Google Play `in.laundrymate.consumer` | iTunes Lookup API and listing page HTML, same method as above |
| `laundrokart/` | `ios-01..06.jpg` (1242×2208), `play-01..06.png` (720×1280), `play-07.png` (a banner) | App Store id 1552864492 and Google Play `com.laundrokart.laundrokartapp` | same method (its Play images are PNG, not JPEG) |

Deleted after review: 14 extra DhobiLite Play images that were wide banners or duplicates of the iOS marketing frames.

## What the images are (important for reading them)

- **Fabrico Play** (`play-*`): raw Android app screens. The most trustworthy UI evidence of the three.
- **DhobiLite Play** (`play-01..07`): marketing frames around the current dark app UI. **DhobiLite iOS** (`ios-*`): an older, light marketing look.
- **Tumbledry iOS and Play**: marketing frames (phone mockups on grey or pink) around a dark home screen and a light schedule screen. The in-app part is small.
- Store images are curated and may be older than the live app (one Tumbledry frame shows a July date in the schedule strip).

## Measured colours

Pixel sampling, not eyeballing, but JPEG compression and marketing colour grading mean ±a few units per channel. Results are in `../design/*.tokens.json`.
