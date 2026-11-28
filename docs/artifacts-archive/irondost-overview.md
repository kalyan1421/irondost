# IronDost
Source: https://claude.ai/artifact/3TxmJdVqHnomwZHFxMu9bR · Last updated: 2026-10-02 (content; published version 2026-11-23) · Archived 2026-11-23

> Design System artifact (typed). Exported from its project files: README (brand book), Order status section, tokens, component guidelines and asset notes. The generated "Consuming this system" and "Index" sections of the README are kept for reference. Logo and icon files are uploads and are listed by name only.

## Brand book (README)

IronDost picks up clothes from homes in Hyderabad, irons or washes them, and brings them back. This system dresses all three IronDost products: the **customer app** and the **partner app** (Flutter, iOS and Android) and the **admin** (Next.js). The brand promise sits in the tagline: **Wash · Iron · Deliver**. "Dost" means friend, so everything should feel like a dependable neighbour: warm, plain-spoken and quick.

#### Content fundamentals

**Voice.** Friendly, direct, never cute. Talk to the customer as **you**; IronDost is **we**. Short sentences, sentence case everywhere (buttons, titles, tabs). No exclamation marks in UI copy and no emoji in interface text.

**Say what happens.** Buttons start with a verb and name the result: "Schedule pickup", "Pay ₹180", "Track order", "Add address". Never "Submit" or "OK".

**Real examples from the product:**

| Moment | Copy |
| --- | --- |
| Home headline | "Fresh clothes, back at your door." |
| Empty orders | "No orders yet. Book a pickup and we'll collect your clothes." |
| Slot closed | "That slot just closed. Pick another  time." |
| Push: picked up | "We have your clothes for order ID001042." |
| Push: out for delivery | "Order ID001042 is on its way." |
| Payment due at delivery | "₹180 is due. Pay the partner in cash or pay online now." |
| Account deletion | "This removes your name, phone number and addresses. Past orders stay in our records without your details." |

**Numbers, money and time.**
- Rupees with Indian grouping and no decimals when whole: ₹1,240, ₹15, ₹12.50.
- Dates read "Sat, 3 Oct".
- Slots read "Morning · 7–11 am", "Noon · 11 am–4 pm", "Evening · 4–8 pm".
- Order numbers are set in `order-id` (mono): ID001042.

**Language.** English first. Hindi strings use the `devanagari` family; never mix scripts inside one line.

#### Visual foundations

##### Colour

The palette comes straight from the logo: `ink` outlines, a `royal` iron, `sky` water, `sun` highlights, `mist` panels.

- **One `primary` action per screen**, filled `primary` with `on-primary` text. Secondary actions are tonal (`primary-soft` with `on-primary-soft`) or text buttons in `primary`.
- **Text** is `text` on `bg`, `surface` or `surface-soft`. Secondary text is `text-muted`. Never place `sky` text on a light ground; use `accent` (a deepened `ocean`) instead.
- **`sun` / `offer` means money saved**: offers, promo codes and the "You saved ₹30" pill, always with `on-offer` (ink) text. Don't use it for warnings; that is `warning`.
- **Status colours always travel with a word or icon** (`success`, `warning`, `danger` and their `-soft` fills). Success is green, danger is red, and they also differ in lightness, so no state relies on hue alone.
- **Cards** are `surface` on `bg` with `shadow-card` in light mode; in dark mode they separate by colour step plus `border`.
- **Dark mode** uses the same structure. `primary` lightens to stay at 6.5:1, and `accent` becomes `sky`, which is designed to sit on dark grounds.

##### Type

- **Outfit** (`display` family) is the brand's voice: headings, the wordmark and big numbers. Use `display` for totals, `headline` for top-level screen titles and `title-lg` for app bars and section heads.
- **Figtree** (`body` family) carries the interface:
  - `title` for card titles and item names
  - `body` and `body-lg` for reading
  - `label` for buttons
  - `label-sm` for chips
  - `caption` for helper text
- **Geist Mono** (`mono`) is only for order numbers and promo codes (`order-id`).
- Respect the system text size: layouts must reflow at 200% without truncating prices or buttons.

##### Space, shape, elevation

- **4-point spacing.** Screens have a 16px gutter (`space-4`), cards pad 16px, and sections sit 24px apart (`space-6`). Touch targets are at least `touch-target` (48px), with 8px between them.
- **Rounded but not bubbly.** Buttons and inputs use `radius-md`, cards `radius-lg`, sheet tops `radius-xl`, and pills `radius-full`. The admin uses the tighter `radius-sm`.
- **Elevation is quiet.** `shadow-card` for cards, `shadow-raised` for things that float (cart bar, snackbar), `shadow-sheet` for bottom sheets. Never stack shadows.

##### Illustration and imagery

- **Brand illustration style:** flat fills from the palette and the `illo-*` tokens, closed with thick, rounded `ink` outlines (about 3–4% of the artwork's height), white glints, and soap bubbles as the recurring motif.
- **Use only the logo files in Logos.** Never redraw the mark. New spot illustrations (empty states, onboarding) follow the same outline weight and palette.
- **Photos:** item and service photos are square, cropped tight on the garment, on a plain light ground. The API stores them as WebP.
- **No stock photos of people** in v1.

##### Motion

- **Durations:** 150–250ms for state changes, 300ms for sheets and page transitions. Exits run about two-thirds as long as entries.
- **Easing:** ease-out on enter (Flutter `Curves.easeOutCubic`), ease-in on exit.
- **Motion explains cause and effect:**
  - a stepper's count slides
  - the cart bar rises when the first item is added
  - the tracking step fills when the status changes
- With reduced motion on, every transition becomes a fade, or no animation at all.

##### States

- **Pressed:** fills switch to `primary-pressed`; other surfaces get an 8% `text` overlay. Android ripples use the same colour.
- **Disabled:** 38% opacity, no press feedback, and still announced as disabled.
- **Focus** (keyboard, switch access): a 2px `focus-ring`, offset 2px.
- **Loading:** a spinner replaces the button label at the same width. Lists and cards load as `surface-soft` skeletons, never a blank screen.
- **Errors:** sit under the field in `danger` with an icon, and say how to fix it.

#### Iconography

- **Lucide icons:** 24×24 grid, 2px stroke, round caps and joins. Flutter uses `lucide_icons_flutter`; the admin uses `lucide-react`.
- **Sizes:** `icon-lg` in the app bar and bottom navigation, `icon-md` in buttons and rows, `icon-sm` in chips.
- **Colour:** icons take `text`, `text-muted` or the colour of the label they sit with.
- **No emoji as icons.** Keep outline icons; only the active bottom-navigation tab uses the filled pill indicator.
- **Icon-only buttons** need an accessible label and a 48px hit area.

#### Logo

- **On light grounds**, use `irondost-logo.svg` (horizontal) or `irondost-logo-stacked.svg`. The tagline lockup is only for marketing and splash screens.
- **On `ink` or dark grounds**, use `irondost-logo-reverse.svg`. The colour mark already works on dark, so marks have no reverse file.
- **At 48px and below** (favicons, notification avatars), use `irondost-mark-small.svg`.
- **App icon:** the colour mark on white. Android notifications use the white single-colour glyph.
- **Clear space:** at least the height of one soap bubble on every side. Never recolour, stretch, outline or add effects.

#### Platform mapping

**Flutter.** Build `ColorScheme` from these tokens:
- `primary` = `primary`; `onPrimary` = `on-primary`
- `primaryContainer` = `primary-soft`; `onPrimaryContainer` = `on-primary-soft`
- `secondary` = `accent`; `tertiary` = `offer`; `onTertiary` = `on-offer`
- `surface` = `surface`; `onSurface` = `text`; `onSurfaceVariant` = `text-muted`
- `surfaceContainerHighest` = `surface-soft`
- `outline` = `border-strong`; `outlineVariant` = `border`
- `error` = `danger`
- The scaffold background is `bg`.

The brand constants are generated in `packages/brand/tokens/brand_colors.dart`. Fonts load through `google_fonts` (Outfit, Figtree, Geist Mono).

**Admin (Next.js).** `apps/admin/src/app/globals.css` maps the same roles to shadcn variables: `--primary` is royal, `--brand` is sky, and the sidebar is ink.

---

#### Consuming this system (generated — do not edit)

Every path named below is under `project/` in this design system: read `project/api/tokens.md`, not `api/tokens.md`.

19 components are documented without a runnable `components/bundle.js`: read each component’s card, and its README where it has one (`components/<Comp>/README.md`), and build to those guidelines. Tokens: the values are on `api/tokens.md`; a Slides deck or Design canvas also takes `tokens.json` by file path.

**Read, per thing:** a component’s props, parts and examples: `api/components/<Comp>.md`; token values: `api/tokens.md`; stored assets and their paths: `api/assets/<Group>.md`. After this README, fetch the cards and fonts you need in ONE message as parallel calls — none depends on another.

**Two rules.** Before you use a thing — a component, a token group, an icon, an asset — read its card from the index below; a value you did not read from a card is a guess. `tokens.json`, `manifest.json` and `design-system.json` are sources for tools: hand them over. `components/<Comp>/README.md` and `assets/<Group>/README.md` are the long-form second read a card links to; `SKILL.md` and `artifact-type/` beside them are authoring guidance, not needed to consume the system.

#### Index (generated — do not edit)

**Tokens**

- `api/tokens.md` — Every token: surface, text, fill, border, palette, type, spacing, radius, shadow, size. (10.7k)

**Icons and assets**

- `api/assets/Logos.md` — 9 files, by asset id. (2.4k)
- `api/assets/App-icons.md` — 3 files, by asset id. (1.4k)

**Components** (`api/components/<Comp>.md`, 19)

- **Inputs**: `AddressCard` — A saved address in the address book and the checkout address picker · `ChoiceCard` — A large single-choice option with an icon, title and one line of explanation · `OtpInput` — Six boxes for the SMS code · `QuantityStepper` — Adds an item to the cart and changes its count · `SlotPicker` — Chooses the pickup (and later delivery) date and time window · `TextField` — A labelled single-line input
- **Navigation**: `AppBar` — The top bar · `BottomNav` — The four top-level destinations: Home, Orders, Offers, Account · `CartBar` — The sticky bar at the bottom of the catalogue once the cart has items: count, total, and the one forward action · `ListRow` — A settings-style row inside a grouped list: icon, label, optional value, chevron
- **Actions**: `Button` — The tappable action
- **Feedback**: `EmptyState` — What a screen shows when there is nothing yet: the mark, a title, one sentence, and at most one action · `Snackbar` — Short confirmation at the bottom of the screen, above the bottom nav or cart bar
- **Orders**: `OrderCard` — An order in the Orders list and the Home "active order" slot · `OrderTimeline` — The five customer steps of an order, top to bottom: Booked → Picked up → Ironing → Out for delivery → Delivered · `PriceSummary` — The bill on Cart, Checkout and Order details · `StatusChip` — The order's status in the customer's words, colour-coded by tone
- **Catalogue**: `PromoCard` — A promotion or banner on Home and Offers: headline, short condition, code chip, soap-bubble decoration · `ServiceItemRow` — One catalogue item in the "Iron" or "Dry clean" list: picture, name, price per piece and the quantity stepper

## Order status

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

## Tokens

Every token of the system, a section per group: Surfaces — 3 tokens; Text — 4 tokens; Fills and status backgrounds — 3 tokens; Borders and rings — 2 tokens; Palette ramps and brand — 27 tokens; Type styles, families, font files; Spacing — 8 tokens; Radius — 5 tokens; Shadow — 3 tokens; Size — 9 tokens.

### Color · Surfaces

#### Tokens (3)

| token | light | dark | usage |
| --- | --- | --- | --- |
| `surface` | #ffffff | #12213f | Cards, sheets, inputs, app bars and the bottom navigation. |
| `surface-soft` | #e6eef8 | #1a2c52 | Grouped panels inside a card, skeleton loaders, unselected chips. |
| `surface-inverse` | #0e1e3d | #e6eef8 | Snackbars and the dark hero card on order tracking. |

### Color · Text

#### Tokens (4)

| token | light | dark | usage |
| --- | --- | --- | --- |
| `ink` | #0e1e3d | #0e1e3d | Brand ink: the logo's outlines, the word "Iron", dark brand surfaces. For UI text use `text`, which follows the theme. |
| `text` | #0e1e3d | #eef3fa | Primary text and icons on `bg`, `surface` and `surface-soft` (light 16:1, dark 15:1). |
| `text-muted` | #4a5a77 | #a9b6cc | Secondary text, captions and inactive icons on `bg`, `surface` and `surface-soft` (light ≥5.9:1, dark ≥6.4:1). |
| `text-inverse` | #ffffff | #0e1e3d | Text on `surface-inverse`. |

### Color · Fills and status backgrounds

#### Tokens (3)

| token | light | dark | usage |
| --- | --- | --- | --- |
| `on-primary` | #ffffff | #0e1e3d | Text and icons on `primary` fills (light 6.8:1, dark 6.7:1). |
| `on-primary-soft` | #1f4fd1 | #7fa2ff | Text and icons on `primary-soft` (light 5.8:1, dark 5.2:1). |
| `on-offer` | #0e1e3d | #0e1e3d | Text on `offer` (10.8:1). |

### Color · Borders and rings

#### Tokens (2)

| token | light | dark | usage |
| --- | --- | --- | --- |
| `border` | #dce4ee | #26375a | Dividers and card outlines (decorative, never the only boundary of a control). |
| `border-strong` | #7d8ba3 | #6f82a6 | Input, checkbox and outline-button borders: ≥3:1 on `surface` and `bg` in both themes. |

### Color · Palette ramps and brand

#### Tokens (27)

| token | light | dark | usage |
| --- | --- | --- | --- |
| `royal` | #1f4fd1 | #1f4fd1 | Brand primary: the word "Dost", the iron's body. UI actions use `primary`, which is royal in light mode. |
| `sky` | #3fb8ea | #3fb8ea | Water and fills in illustrations; accent text on dark grounds only (2.3:1 on white, never text on light). |
| `ocean` | #1a73b0 | #1a73b0 | Sky's text-safe partner on light grounds (5.1:1 on white): the tagline, informational links. |
| `sun` | #ffc93c | #ffc93c | Offers, savings and highlights. Always carries `ink` text (10.8:1), never white. |
| `mist` | #e6eef8 | #e6eef8 | Soft brand panels and the washer's control panel in illustrations. |
| `white` | #ffffff | #ffffff | Washer and iron bodies in illustrations; logo ground. |
| `bg` | #f5f8fc | #0b1630 | App background behind cards, lists and sheets. |
| `inverse-accent` | #3fb8ea | #1f4fd1 | Action text on `surface-inverse`, e.g. the snackbar's "Undo" (light 7.3:1, dark 5.8:1). |
| `primary` | #1f4fd1 | #7fa2ff | The one main action per screen, links, selected states, progress. On `surface` and `bg`: light 6.8:1, dark 6.5:1. |
| `primary-pressed` | #1a43b3 | #9db8ff | Pressed state of `primary` fills. |
| `primary-soft` | #e8eefc | #1c2f63 | Selected chips and slots, the active tab indicator, info fills. Pair with `on-primary-soft`. |
| `accent` | #16639a | #3fb8ea | Informational accents: the live-tracking line, "Partner on the way", the out-for-delivery chip. Light is `ocean` deepened for small text: 6.4:1 on `surface`, 5.5:1 on `surface-soft`; dark is `sky` (7:1, 6:1). |
| `offer` | #ffc93c | #ffc93c | Offer badges, promo cards and the "You saved" pill. Pair with `on-offer`. |
| `offer-soft` | #fff4d1 | #3a3112 | Large promo backgrounds; text on it is `text`. |
| `success` | #1a7347 | #5fd39a | Delivered, paid, savings amounts. On `surface` 5.8:1 / 8.6:1; on `success-soft` 5.1:1 / 6.8:1. Always with an icon or word. |
| `success-soft` | #e3f4ea | #133a2a | Background of success chips and banners. |
| `warning` | #8a5a00 | #ffc93c | Unpaid amounts, slots closing soon. On `warning-soft` 5.3:1 / 8.4:1. |
| `warning-soft` | #fff1cc | #3a3112 | Background of warning chips and banners. |
| `danger` | #c62828 | #ff8a80 | Errors, cancellation, account deletion. On `surface` 5.6:1 / 7:1; on `danger-soft` 4.9:1 / 7.1:1. |
| `danger-soft` | #fdeceb | #3d1a1d | Background of error banners and the cancelled chip. |
| `focus-ring` | #1f4fd1 | #3fb8ea | 2px keyboard and switch-access focus ring, offset 2px; ≥6.5:1 on every surface. |
| `scrim` | rgba(14, 30, 61, 0.5) | rgba(0, 0, 0, 0.6) | Behind bottom sheets and dialogs. |
| `illo-steel` | #c9d2dd | #c9d2dd | Illustration: the iron's soleplate and metal parts. |
| `illo-ring` | #dce4ee | #dce4ee | Illustration: the washer door ring. |
| `illo-glass` | #bfeaf8 | #bfeaf8 | Illustration: glass and window highlights. |
| `illo-foam` | #d9f4fc | #d9f4fc | Illustration: soap bubbles and foam. |
| `illo-chrome` | #f1f4f8 | #f1f4f8 | Illustration: chrome highlights. |

### Type

Use the named styles; no literal px.

#### Styles

| style | CSS | size / line | weight | family | usage |
| --- | --- | --- | --- | --- | --- |
| `display` | `.display`, `--text-display` | 32px / 38px | 700 | `display` | Totals and big numbers: the order total, the OTP digits. |
| `headline` | `.headline`, `--text-headline` | 24px / 30px | 700 | `display` | Large screen titles on top-level tabs and the first line of a hero card. |
| `title-lg` | `.title-lg`, `--text-title-lg` | 20px / 26px | 600 | `display` | App bar titles and section headings. |
| `title` | `.title`, `--text-title` | 17px / 24px | 600 | `body` | Card titles, item names, list row labels. |
| `body-lg` | `.body-lg`, `--text-body-lg` | 16px / 24px | 400 | `body` | Input text and comfortable reading copy. |
| `body` | `.body`, `--text-body` | 15px / 22px | 400 | `body` | Default body copy, addresses, descriptions. |
| `label` | `.label`, `--text-label` | 15px / 20px | 600 | `body` | Button labels and tab labels. |
| `label-sm` | `.label-sm`, `--text-label-sm` | 13px / 18px | 600 | `body` | Chips, badges and field labels. |
| `caption` | `.caption`, `--text-caption` | 12px / 16px | 500 | `body` | Helper text, timestamps, fine print. Never smaller than 12px. |
| `order-id` | `.order-id`, `--text-order-id` | 14px / 20px | 500 | `mono` | Order numbers and promo codes. |

#### Families

| family | CSS variable | stack |
| --- | --- | --- |
| `display` | `--font-display` | `"Outfit", system-ui, sans-serif` |
| `body` | `--font-body` | `"Figtree", system-ui, sans-serif` |
| `mono` | `--font-mono` | `"Geist Mono", ui-monospace, monospace` |
| `devanagari` | `--font-devanagari` | `"Noto Sans Devanagari", "Figtree", sans-serif` |

### Spacing

4-point scale. Screens use a 16px side gutter; sections are separated by 24px.

#### Tokens (8)

| token | value | usage |
| --- | --- | --- |
| `space-1` | 4px | Icon-to-text gap inside chips. |
| `space-2` | 8px | Gap between related items; minimum gap between touch targets. |
| `space-3` | 12px | Inside chips and list rows; gap between cards in a list. |
| `space-4` | 16px | Screen side gutter and card padding. |
| `space-5` | 20px | Padding of hero and promo cards. |
| `space-6` | 24px | Space between sections on a screen. |
| `space-8` | 32px | Space above a screen's first heading; empty-state padding. |
| `space-12` | 48px | Large breaks, e.g. above the sign-in form. |

### Radius

#### Tokens (5)

| token | value | usage |
| --- | --- | --- |
| `radius-sm` | 8px | Small chips, thumbnails, admin buttons and inputs. |
| `radius-md` | 12px | App buttons, inputs, OTP boxes, slot tiles. |
| `radius-lg` | 16px | Cards: orders, addresses, items, promos. |
| `radius-xl` | 24px | Top corners of bottom sheets; hero cards. |
| `radius-full` | 999px | Pills: steppers, status chips, the tab indicator, avatars. |

### Shadow

Shadows only in light mode; dark mode separates with `border` and lighter surfaces.

#### Tokens (3)

| token | value | usage |
| --- | --- | --- |
| `shadow-card` | 0 1px 2px rgba(14, 30, 61, 0.06), 0 2px 8px rgba(14, 30, 61, 0.06) · dark: none | Cards on `bg`. |
| `shadow-raised` | 0 6px 20px rgba(14, 30, 61, 0.12) · dark: 0 6px 20px rgba(0, 0, 0, 0.5) | Floating elements: the cart bar, menus, snackbars. |
| `shadow-sheet` | 0 -6px 24px rgba(14, 30, 61, 0.14) · dark: 0 -6px 24px rgba(0, 0, 0, 0.6) | Bottom sheets and sticky bottom action bars. |

### Size

Fixed sizes in logical pixels (dp / pt).

#### Tokens (9)

| token | value | usage |
| --- | --- | --- |
| `touch-target` | 48px | Minimum tappable area for any control, even when the visible icon is smaller. |
| `button-height` | 52px | Primary and secondary buttons. |
| `input-height` | 52px | Text fields and the phone field. |
| `app-bar` | 56px | Top app bar height (plus the status-bar safe area). |
| `bottom-nav` | 64px | Bottom navigation height (plus the home-indicator safe area). |
| `icon-sm` | 16px | Icons inside chips and captions. |
| `icon-md` | 20px | Icons in buttons, list rows and fields. |
| `icon-lg` | 24px | App bar and bottom navigation icons. |
| `thumb` | 56px | Item and service thumbnails in lists. |

## Components (19)

### AddressCard

A saved address in the address book and the checkout address picker.

#### Consumer provides
- `address` from `GET /v1/me/addresses`: `label` (Home, Work or the customer's own), `houseNo`, `building`, `street`, `area`, `landmark`, `city`, `pincode`, `formatted`, `isPrimary`.
- `selected`/`onTap` in pickers; `onEdit` in the address book.

#### Layout
- 40px icon tile (`house`, `briefcase`, `map-pin`), the label in `title`, a "Default" info chip when `isPrimary`, then the address in `body`/`text-muted`, wrapping to three lines.
- In pickers the selected card has a 2px `primary` border plus a check; in the address book a trailing pencil icon button (48×48) edits.

#### Do / Don't
- Do show the landmark: partners rely on it.
- Don't show coordinates or the raw pincode alone.

### AppBar

The top bar. Two forms: the Home header (logo, address, bell) and the standard title bar with back.

#### Consumer provides
- `title` or the Home form's `addressLabel`; `onBack` (shown on every pushed screen); up to two trailing icon actions.

#### Layout
- Height `app-bar` (56), `surface`, title in `title-lg` (Outfit). No shadow at rest; a 1px `border` hairline appears once content scrolls under it.
- Icon buttons are 48×48 with a tooltip/semantic label. The notification bell shows a `danger` dot for unread items.
- Home: the address line ("Home · Banjara Hills" + chevron) opens the address picker sheet.

### BottomNav

The four top-level destinations: Home, Orders, Offers, Account.

#### Behaviour
- Height `bottom-nav` (64) plus the safe area. Icons `icon-lg` with a label in `caption`/600 always visible.
- Active: icon in a 56×32 `primary-soft` pill, label in `text`. Inactive: `text-muted`.
- Re-tapping the active tab scrolls to top. Each tab keeps its own navigation stack (go_router `StatefulShellRoute`).
- Orders shows a small count badge while an order is active.

#### Flutter
Material 3 `NavigationBar` themed with `indicatorColor: primary-soft`; on iOS the same widget (not a Cupertino tab bar) so both platforms match.

### Button

The tappable action. One `primary` button per screen carries the step forward ("Continue", "Place order", "Pay ₹540").

#### Consumer provides
- `label`: a verb phrase in sentence case, two to four words.
- `onPressed`: null renders the disabled state.
- `variant`: `primary` | `tonal` | `outline` | `text` | `danger`.
- Optional `icon` (Lucide, `icon-md`, leading), `loading`, `expand` (full width).

#### Variants
| Variant | Use when |
|---|---|
| primary | The one forward action on the screen; pinned to the bottom in flows. |
| tonal | A strong second action beside a primary ("Add address"). |
| outline | Neutral alternatives ("Change slot", "Call partner"). |
| text | Low-emphasis links inside content ("View all", "Resend OTP"). |
| danger | Destructive confirmations only ("Cancel order", "Delete account"); always behind a confirmation sheet. |

#### States
- Height `button-height` (52), radius `radius-md`, label in `label`. Minimum width `touch-target`.
- **Pressed:** `primary-pressed` fill, scale 0.98 for 100ms.
- **Disabled:** 38% opacity, no ripple. Prefer explaining why below the button over silently disabling.
- **Loading:** the label is replaced by a spinner, the width is kept, and taps are ignored until the request settles.
- **Focus (keyboard, switch access):** 2px `focus-ring` outline, 2px offset.

#### Flutter
`FilledButton` (primary), `FilledButton.tonal`, `OutlinedButton`, `TextButton`, all themed from `ColorScheme` with `minimumSize: Size(48, 52)`. Wrap with `Semantics(button: true)` only when building custom.

#### Do / Don't
- Do put the amount on payment buttons: "Pay ₹540".
- Don't stack two primary buttons. Don't use all caps. Don't use `danger` for "Log out".

### CartBar

The sticky bar at the bottom of the catalogue once the cart has items: count, total, and the one forward action.

#### Consumer provides
- `itemCount`, `totalPaise`, `onContinue`.

#### Behaviour
- `surface` with `shadow-sheet`, top corners `radius-xl`, sits above the bottom nav and the safe area.
- Slides up 200ms ease-out when the first item is added; the total ticks with a 150ms crossfade.
- If the order is below the minimum, the button reads "Add ₹49 more" and is disabled, with the reason in the count line.

### ChoiceCard

A large single-choice option with an icon, title and one line of explanation. Used for payment method and address type.

#### Consumer provides
- `icon`, `title`, `description`, `selected`, `onTap`; optional `trailing` (e.g. a "Recommended" chip).

#### Payment methods (v1)
- **Pay online:** UPI, cards, netbanking via Razorpay. Description "UPI, cards and netbanking".
- **Cash on delivery:** "Pay the partner when your clothes come back".

#### Behaviour
- Radius `radius-lg`, 1px `border`; selected gets a 2px `primary` border and a filled radio. Never colour alone: the radio changes too.
- Whole card is the hit target.

### EmptyState

What a screen shows when there is nothing yet: the mark, a title, one sentence, and at most one action.

#### Consumer provides
- `title`, `body`, optional `action` (Button, `tonal` or `primary`), optional `illustration` (defaults to `irondost-mark.svg` at 132px).

#### Copy
| Screen | Title | Body | Action |
|---|---|---|---|
| Orders | No orders yet | Book a pickup and we'll collect your clothes. | Book a pickup |
| Offers | No offers right now | New offers show up here. We'll notify you too. | — |
| Notifications | You're all caught up | Updates on your orders will appear here. | — |
| Offline | You're offline | Check your connection and try again. | Retry |
| Out of area | We're not in your area yet | We'll let you know when IronDost reaches you. | Change address |

### ListRow

A settings-style row inside a grouped list: icon, label, optional value, chevron.

#### Consumer provides
- `icon`, `label`, optional `value` ("English"), `onTap`, `destructive`.

#### Layout
- Min height 56, padding 16, icon `icon-md` in `text-muted`, label in `body-lg`/500. Rows sit in an `id-list` group (`radius-lg`), separated by 1px `border`.
- Destructive rows ("Delete account") use `danger` for icon and label, live in their own group at the bottom, and always open a confirmation sheet.

### OrderCard

An order in the Orders list and the Home "active order" slot. Tapping opens order details.

#### Consumer provides
- `order`: `number` ("ID001042"), `status`, `itemCount`, `summary` ("8 shirts, 2 trousers"), `pickup` and `delivery` slot, `totalPaise`, `paymentStatus`.

#### Layout
- `id-card` (radius `radius-lg`, `shadow-card`; in dark a 1px `border` instead of shadow).
- Header: order number in `order-id` (Geist Mono) and the StatusChip.
- Pickup and delivery in a `surface-soft` panel as label/value pairs.
- Footer: total in Outfit 18/700 and, when unpaid, the warning chip; the trailing action is a `text` button ("Track", "Pay now", "Reorder").

#### Do / Don't
- Do show the next thing that happens, not the history.
- Don't show more than one action button on a card.

### OrderTimeline

The five customer steps of an order, top to bottom: Booked → Picked up → Ironing → Out for delivery → Delivered.

#### Consumer provides
- `order.status` and `order.events` (timestamps). Step mapping is in **Order status**.

#### States
- **Done:** filled `primary` dot with a check, `primary` connector, time in `caption` ("Today, 9:42 AM").
- **Current:** ring dot with a `primary-soft` halo, title in `label`, a meta line with the next promise ("Arrives Sat, 4 – 8 PM").
- **Future:** hollow `border-strong` dot, title in `text-muted`.
- **Cancelled:** the timeline is replaced by a neutral card with the reason and refund note.

#### Motion
The current dot's halo pulses once on arrival (300ms) and only when reduced motion is off. Realtime updates (Socket.IO `order.updated`) advance the step with a 200ms crossfade.

#### Accessibility
Read as a list: "Step 3 of 5, Ironing, in progress".

### OtpInput

Six boxes for the SMS code. One hidden field drives them so paste and SMS autofill work.

#### Consumer provides
- `length` (6), `onCompleted(code)`, `error`, `resendIn` seconds.

#### Behaviour
- Boxes are 48×56, radius `radius-md`, digits in Outfit 24/700. The active box has a 2px `primary` border and a caret.
- Use `AutofillHints.oneTimeCode` (iOS) and the SMS User Consent API (Android). Submit automatically on the sixth digit.
- Under the boxes: "Resend code in 0:24", then a `text` button "Resend code". Offer "Change number" as a second text button.
- Errors replace the helper line ("That code is incorrect. 2 tries left.") and clear the boxes.

#### Accessibility
One `Semantics` label "Verification code, 6 digits"; announce each entered digit. Never 6 separate focus stops.

### PriceSummary

The bill on Cart, Checkout and Order details. Mirrors the API pricing exactly; the app never computes totals itself.

#### Consumer provides
- `quote` from `POST /v1/orders/quote` (or the order): `itemsTotalPaise`, `discountPaise`, `deliveryFeePaise`, `totalPaise`, `promoCode`.

#### Layout
- Rows in `body` with tabular figures, amounts right-aligned.
- Discount row in `success` with the code ("WELCOME20 applied"). A zero delivery fee shows "Free" (struck original in `text-muted` when waived).
- Total under a dashed `border-strong` rule in Outfit 18/700.
- Under the total on Checkout, one line in `caption`: "Final amount may change if items differ at pickup."

### PromoCard

A promotion or banner on Home and Offers: headline, short condition, code chip, soap-bubble decoration.

#### Consumer provides
- `title` ("20% off your first order"), `terms` ("Up to ₹100 · Min. order ₹299"), `code` (nullable), optional `imageUrl` (admin banner) and `onTap`.

#### Layout
- `offer-soft` ground, radius `radius-lg`, padding 20. Title in `title-lg` Outfit, up to 75% width.
- The code sits in a dashed outline chip in Geist Mono; tapping it copies and shows a Snackbar "Code WELCOME20 copied".
- Bubbles: two or three `illo-foam` circles with a 2.5px `ink` outline bleeding off the right edge. Decorative, hidden from screen readers.
- Admin banners with an image replace the ground with the image (2:1, `radius-lg`) and keep the code chip.

#### Do / Don't
- Don't stack more than one promo above the fold on Home. Don't animate the bubbles.

### QuantityStepper

Adds an item to the cart and changes its count. Starts as an outlined "Add" pill and becomes a filled stepper at 1.

#### Consumer provides
- `count`, `onChanged(count)`, optional `max` (default 50).

#### Behaviour
- Pill height 36 inside a 48×48 hit area. Count in `label` with tabular figures.
- Decrementing from 1 removes the item (the stepper turns back into "Add"). No confirmation; the cart bar updates instantly.
- Light haptic on each change. At `max`, the plus is disabled.

#### Accessibility
Buttons labelled "Remove one Shirt" / "Add one Shirt"; the count is announced as "2 Shirts in cart".

### ServiceItemRow

One catalogue item in the "Iron" or "Dry clean" list: picture, name, price per piece and the quantity stepper.

#### Consumer provides
- `item` from `GET /v1/catalog`: `name`, `imageUrl` (nullable), `pricePaise`, `offerPricePaise` (nullable), `effectivePricePaise`, `unit` (`PIECE` shows "per piece").
- `count`, `onChanged`.

#### Layout
- Thumb `thumb` (56) at `radius-sm` on `surface-soft`; with no image, show the category's Lucide icon in `primary`.
- Name in `body-lg`/600; price in `label` with tabular figures; when `offerPricePaise` is set, the offer price followed by the struck-through `pricePaise` in `text-muted`; unit in `caption`.
- Rows divide with a 1px `border`; no cards inside the list.

#### Do / Don't
- Do format money as "₹15" (no decimals when whole), "₹12.50" otherwise.
- Don't truncate item names; wrap to two lines.

### SlotPicker

Chooses the pickup (and later delivery) date and time window. Dates scroll horizontally; the three windows stack below.

#### Consumer provides
- `days` and `slots` from `GET /v1/schedule/pickup-slots` (or `GET /v1/schedule/delivery-slots`): each `SlotOptionDto` has `date`, `slot` (MORNING | NOON | EVENING), `label`, `startsAt`, `endsAt`, `available`.
- `selected`, `onSelected`.

#### Behaviour
- Date tiles 64 wide: weekday (`caption`, upper case) over day number (Outfit 20/700). Selected: `primary` fill, `on-primary` text. Show "Today"/"Tomorrow" instead of the weekday for the first two.
- Slot rows: name ("Morning") over time ("7 – 11 AM"), radio on the right. Selected: `primary-soft` fill with a 2px `primary` border.
- Unavailable slots stay visible at 50% with a reason ("Too soon" when inside the 20-hour turnaround, "Closed" once the window has started) so the list never jumps.
- Delivery slots start at pickup + 20h; the picker only shows what the API returns.

#### Accessibility
Each slot is a radio in one group: "Evening, 4 to 8 PM, available, not selected".

### Snackbar

Short confirmation at the bottom of the screen, above the bottom nav or cart bar.

#### Consumer provides
- `message` (one line, ≤ 60 characters), optional `action` ("Undo", "Retry").

#### Behaviour
- `surface-inverse` with `text-inverse`; the action in `inverse-accent`. Radius `radius-md`, `shadow-raised`.
- Auto-dismiss after 4s (7s with an action). Never steals focus; announced politely.
- Errors that need a decision use a dialog or inline message instead.

### StatusChip

The order's status in the customer's words, colour-coded by tone. Labels and tones come from **Order status**.

#### Consumer provides
- `status` (API enum). The widget maps it to label, tone and icon; never pass free text.

#### Tones
| Tone | Fill / text | Statuses |
|---|---|---|
| info | `primary-soft` / `on-primary-soft` | Booked, Partner assigned, Picked up, Being ironed, Ready |
| accent | `surface-soft` / `accent` + truck | Out for delivery soon, Out for delivery |
| success | `success-soft` / `success` + check | Delivered |
| neutral | `surface-soft` / `text-muted` | Cancelled |
| warning | `warning-soft` / `warning` | Payment due ("₹180 due"), a separate chip |
| offer | `offer` / `on-offer` | Promotions only ("20% off"), never a status |

Height 28, `radius-full`, `label-sm`.

### TextField

A labelled single-line input. The label sits above the field, never only as a placeholder.

#### Consumer provides
- `label`, `value`, `onChanged`; optional `placeholder` (an example, not an instruction), `helper`, `error`, `prefix`, `trailing` icon, `keyboardType`, `autofillHints`.

#### Variants
- **Default:** name, flat/house number, landmark, coupon code.
- **Phone:** fixed `+91` prefix, `TextInputType.phone`, 10 digits, `AutofillHints.telephoneNumberNational`. Format as "98765 43210" while typing.
- **Search:** leading search icon, clear button once there is text.

#### States
- Height `input-height` (52), radius `radius-md`, value in `body-lg` (16px, avoids iOS zoom).
- Rest: 1px `border-strong`. Focus: 2px `primary`. Error: 2px `danger` plus the message under the field with an alert icon.
- Validate on blur or on submit, never on every keystroke. On submit errors, focus the first invalid field.

#### Flutter
`TextFormField` with an `InputDecorationTheme` (outline border, `floatingLabelBehavior: never`, label rendered above as a `Text` in `label-sm`).

#### Do / Don't
- Do write errors that say how to fix it: "Enter a 10-digit mobile number".
- Don't put the label inside the field. Don't use red for anything but errors.

## Cover

IronDost

Wash · Iron · Deliver. Fresh clothes, back at your door.

## Assets

### Logos

Exact copies of `packages/brand/logo/svg`, generated from one master drawing (`packages/brand/scripts/build-svg.py`). Never edit or redraw them.

- **`irondost-logo.svg`:** horizontal logo for light grounds (app headers, admin sign-in, documents). Colours: ink, royal, sky, white, mist.
- **`irondost-logo-reverse.svg`:** horizontal logo for `ink` and dark grounds.
- **`irondost-logo-tagline.svg`:** logo with "WASH · IRON · DELIVER" in ocean. For the splash screen, website and marketing only.
- **`irondost-logo-stacked.svg`:** stacked lockup for square spaces (store listing header, social).
- **`irondost-mark.svg`:** the washer-and-iron mark alone, from 48px up.
- **`irondost-mark-small.svg`:** simplified mark for 48px and below.
- **`irondost-wordmark.svg`:** "IronDost" in outlined Outfit Bold, ink and royal.
- **`irondost-logo-mono-ink.svg`, `irondost-logo-mono-white.svg`:** single-ink versions, all `ink` (#0E1E3D) or all white, for one-colour print and embossing.

Files: `irondost-logo.svg`, `irondost-logo-reverse.svg`, `irondost-logo-tagline.svg`, `irondost-logo-stacked.svg`, `irondost-mark.svg`, `irondost-mark-small.svg`, `irondost-wordmark.svg`, `irondost-logo-mono-ink.svg`, `irondost-logo-mono-white.svg`  ![logos](image omitted)

### App icons

From `packages/brand/icons`. Regenerate launcher sizes with `flutter_launcher_icons` using `packages/brand/icons/flutter_launcher_icons.yaml`.

- **`app-icon-1024.png`:** iOS App Store and launcher master. The colour mark on white, opaque.
- **`play-store-512.png`:** Google Play listing icon.
- **`notification-icon-96.png`:** Android status-bar notification glyph (xxxhdpi). It is white on transparent, so it is invisible on a white preview tile; Android tints it.

Files: `app-icon-1024.png`, `play-store-512.png`, `notification-icon-96.png`  ![logos](image omitted)

## Record

Last change: 2026-10-02T12:27:43Z by Kalyan via Claude Code: IronDost design system: tokens, brand book, order status vocabulary, 19 customer-app components, logos and app icons.
