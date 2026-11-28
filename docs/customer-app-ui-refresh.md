# Customer app UI refresh: Home, Orders, Basket, Profile

Status: **implemented in `apps/customer`, not committed.** Checked by rendering each screen in a test harness with the real fonts, and on the iOS simulator and the owner's iPhone. The design drafts are on the
"IronDost Customer App Drafts" canvas (the four-tab row).

## What changed

| Area | Before | Now |
|---|---|---|
| Tabs | Home, Orders, Offers, Account | Home, Orders, **Basket**, **Profile**. A floating rounded bar; the Basket tab shows the piece count |
| Home | Greeting, Book button, plain service list, one offer line | Search pill, running offer banner, four service tiles (Laundry, Saree, Ironing, Carpets), Book a pickup, popular prices from the live price list, doorstep banner, How it works card, tagline |
| Orders | Flat white header and cards | Same data and actions; sky background, rounder cards, a service picture on each card |
| Basket | Pushed screen with a back button | A tab; service pictures on each line; scheduling and checkout still open full screen above the tabs |
| Profile | "Account" | "Profile"; adds an "Offers and codes" row, because the Offers tab is gone |
| Pictures | 3D PNGs for three services | Nine SVG illustrations made with Codex (`assets/illustrations/`), shown through `ServiceArt` |

## Decisions taken (asked and answered)

1. **Basket replaces Offers as a tab.** Offers is still reachable: the Home offer banner, the Home offer carousel and Profile → Offers and codes. `Routes.offers` is now a normal screen above the tabs.
2. **Home tiles are fixed to four** (Laundry, Ironing, Saree, Carpets). Each opens the catalogue category whose name, slug or items match; with no match it opens the full price list.
3. **UI only.** No change to API calls, basket maths, checkout or order logic.

## Files

- New: `lib/design/widgets/service_art.dart`, `lib/design/widgets/screen_backdrop.dart`, `assets/illustrations/*.svg`, dependency `flutter_svg`.
- Changed: `lib/features/home/home_screen.dart` (rebuilt), `lib/features/shell/app_shell.dart` (tab bar), `lib/app/router.dart` (Basket is a tab branch, `/basket/schedule` is top level), `lib/design/widgets/surfaces.dart` (rounder, soft shadow), `lib/design/widgets/order_card.dart`, `orders_screen.dart`, `basket_screen.dart`, `account_screen.dart`, plus three `context.push(Routes.basket)` calls that are now `context.go`.
- Tests updated: Home, How it works, Account and Basket tests for the new wording and the taller screens.

## Open points for the owner

- **Carpets** has no price or category in the rate card or docs I found. The tile opens the price list until a Carpets category exists.
- **Prices on Home** come from the live catalogue, so they are only as right as the admin data. Production prices were placeholders as of 14 November.
- **Dark theme** keeps the plain app background; the sky gradient is light-theme only.
- **Old 3D PNGs** are still used by the catalogue and the welcome screen (`ServiceVisual`). Switching those to the SVG set is a separate change and needs two tests updated.
- **Small phones and large text:** the test suite checks 320 dp and 200% text; still worth a look on a real small phone.

## Round 2: all tab screens follow the drafts (20 November)

The shared design widgets carry most of it, so every screen that uses them changed together:

| Widget | Change | Screens it reaches |
|---|---|---|
| Theme | Light screens sit on a soft sky ground (`#F2F6FE`); filled and outlined buttons are pills | All |
| `IdCard` | White, 24 radius, soft shadow, and content inset 16 from the sides | Orders, order detail, basket, checkout, schedule, bills, reports |
| `IdListRow` | Icon in a soft blue tile (red for destructive) | Profile, help, order detail |
| `SegmentedTabs` | White pill track, filled blue selection | Orders |
| `ItemStepper` | Compact pill: white minus, blue plus, count between; Add is an outlined pill | Basket, price list, search |
| `OrderCard` | Four-step progress bar on active orders | Orders |

Screen by screen:

- **Home:** search pill with a slowly turning colour ring (still under Reduce Motion), staggered service tiles with 3D renders that break out of the card corner, one spacing rhythm (32 between sections, 12 inside a group).
- **Orders:** sky ground, big title, pill switch, cards with progress bars.
- **Basket:** tab with service pictures per line, pill steppers under the line total, inset bill card.
- **Profile:** gradient avatar, a yellow "Add mobile number" banner for Google sign-ins with no number, icon tiles on every row.
- **Price list:** service tabs are pills, item card inset.

Not changed on purpose: no API, basket maths, scheduling or payment logic. The drafts show a pickup-window picker inside the Basket and a "Rate" button on past orders; the app keeps time choice on its own Schedule screen and has no rating feature yet, so those two stay as they are.
