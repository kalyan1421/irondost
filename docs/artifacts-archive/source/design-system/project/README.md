IronDost picks up clothes from homes in Hyderabad, irons or washes them, and brings them back. This system dresses all three IronDost products: the **customer app** and the **partner app** (Flutter, iOS and Android) and the **admin** (Next.js). The brand promise sits in the tagline: **Wash · Iron · Deliver**. "Dost" means friend, so everything should feel like a dependable neighbour: warm, plain-spoken and quick.

## Content fundamentals

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

## Visual foundations

### Colour

The palette comes straight from the logo: `ink` outlines, a `royal` iron, `sky` water, `sun` highlights, `mist` panels.

- **One `primary` action per screen**, filled `primary` with `on-primary` text. Secondary actions are tonal (`primary-soft` with `on-primary-soft`) or text buttons in `primary`.
- **Text** is `text` on `bg`, `surface` or `surface-soft`. Secondary text is `text-muted`. Never place `sky` text on a light ground; use `accent` (a deepened `ocean`) instead.
- **`sun` / `offer` means money saved**: offers, promo codes and the "You saved ₹30" pill, always with `on-offer` (ink) text. Don't use it for warnings; that is `warning`.
- **Status colours always travel with a word or icon** (`success`, `warning`, `danger` and their `-soft` fills). Success is green, danger is red, and they also differ in lightness, so no state relies on hue alone.
- **Cards** are `surface` on `bg` with `shadow-card` in light mode; in dark mode they separate by colour step plus `border`.
- **Dark mode** uses the same structure. `primary` lightens to stay at 6.5:1, and `accent` becomes `sky`, which is designed to sit on dark grounds.

### Type

- **Outfit** (`display` family) is the brand's voice: headings, the wordmark and big numbers. Use `display` for totals, `headline` for top-level screen titles and `title-lg` for app bars and section heads.
- **Figtree** (`body` family) carries the interface:
  - `title` for card titles and item names
  - `body` and `body-lg` for reading
  - `label` for buttons
  - `label-sm` for chips
  - `caption` for helper text
- **Geist Mono** (`mono`) is only for order numbers and promo codes (`order-id`).
- Respect the system text size: layouts must reflow at 200% without truncating prices or buttons.

### Space, shape, elevation

- **4-point spacing.** Screens have a 16px gutter (`space-4`), cards pad 16px, and sections sit 24px apart (`space-6`). Touch targets are at least `touch-target` (48px), with 8px between them.
- **Rounded but not bubbly.** Buttons and inputs use `radius-md`, cards `radius-lg`, sheet tops `radius-xl`, and pills `radius-full`. The admin uses the tighter `radius-sm`.
- **Elevation is quiet.** `shadow-card` for cards, `shadow-raised` for things that float (cart bar, snackbar), `shadow-sheet` for bottom sheets. Never stack shadows.

### Illustration and imagery

- **Brand illustration style:** flat fills from the palette and the `illo-*` tokens, closed with thick, rounded `ink` outlines (about 3–4% of the artwork's height), white glints, and soap bubbles as the recurring motif.
- **Use only the logo files in Logos.** Never redraw the mark. New spot illustrations (empty states, onboarding) follow the same outline weight and palette.
- **Photos:** item and service photos are square, cropped tight on the garment, on a plain light ground. The API stores them as WebP.
- **No stock photos of people** in v1.

### Motion

- **Durations:** 150–250ms for state changes, 300ms for sheets and page transitions. Exits run about two-thirds as long as entries.
- **Easing:** ease-out on enter (Flutter `Curves.easeOutCubic`), ease-in on exit.
- **Motion explains cause and effect:**
  - a stepper's count slides
  - the cart bar rises when the first item is added
  - the tracking step fills when the status changes
- With reduced motion on, every transition becomes a fade, or no animation at all.

### States

- **Pressed:** fills switch to `primary-pressed`; other surfaces get an 8% `text` overlay. Android ripples use the same colour.
- **Disabled:** 38% opacity, no press feedback, and still announced as disabled.
- **Focus** (keyboard, switch access): a 2px `focus-ring`, offset 2px.
- **Loading:** a spinner replaces the button label at the same width. Lists and cards load as `surface-soft` skeletons, never a blank screen.
- **Errors:** sit under the field in `danger` with an icon, and say how to fix it.

## Iconography

- **Lucide icons:** 24×24 grid, 2px stroke, round caps and joins. Flutter uses `lucide_icons_flutter`; the admin uses `lucide-react`.
- **Sizes:** `icon-lg` in the app bar and bottom navigation, `icon-md` in buttons and rows, `icon-sm` in chips.
- **Colour:** icons take `text`, `text-muted` or the colour of the label they sit with.
- **No emoji as icons.** Keep outline icons; only the active bottom-navigation tab uses the filled pill indicator.
- **Icon-only buttons** need an accessible label and a 48px hit area.

## Logo

- **On light grounds**, use `irondost-logo.svg` (horizontal) or `irondost-logo-stacked.svg`. The tagline lockup is only for marketing and splash screens.
- **On `ink` or dark grounds**, use `irondost-logo-reverse.svg`. The colour mark already works on dark, so marks have no reverse file.
- **At 48px and below** (favicons, notification avatars), use `irondost-mark-small.svg`.
- **App icon:** the colour mark on white. Android notifications use the white single-colour glyph.
- **Clear space:** at least the height of one soap bubble on every side. Never recolour, stretch, outline or add effects.

## Platform mapping

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

## Consuming this system (generated — do not edit)

Every path named below is under `project/` in this design system: read `project/api/tokens.md`, not `api/tokens.md`.

19 components are documented without a runnable `components/bundle.js`: read each component’s card, and its README where it has one (`components/<Comp>/README.md`), and build to those guidelines. Tokens: the values are on `api/tokens.md`; a Slides deck or Design canvas also takes `tokens.json` by file path.

**Read, per thing:** a component’s props, parts and examples: `api/components/<Comp>.md`; token values: `api/tokens.md`; stored assets and their paths: `api/assets/<Group>.md`. After this README, fetch the cards and fonts you need in ONE message as parallel calls — none depends on another.

**Two rules.** Before you use a thing — a component, a token group, an icon, an asset — read its card from the index below; a value you did not read from a card is a guess. `tokens.json`, `manifest.json` and `design-system.json` are sources for tools: hand them over. `components/<Comp>/README.md` and `assets/<Group>/README.md` are the long-form second read a card links to; `SKILL.md` and `artifact-type/` beside them are authoring guidance, not needed to consume the system.

## Index (generated — do not edit)

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
