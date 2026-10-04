# IronDost customer design system

Version 2 implemented · 5 October 2026 · Based on the existing logo and local customer app.

The final logo selection is packaged in `logo/`. The customer app uses this system. The token master is `packages/design-tokens/customer.tokens.json`; `apps/customer/tool/gen_tokens.dart` generates its Dart tokens. The shared `tokens.json` remains available for other applications. `implemented.html` compares the original and implemented Flutter screens; `index.html` retains the initial interactive concepts.

## Identity and logo decision

Keep the existing IronDost identity. Its washer and iron communicate the service, the outlined Outfit wordmark is recognizable, and the blue/ink combination already has usable action and text colours. The problem is repeated illustration throughout task screens, not a lack of brand assets.

| Asset | Final role | Minimum display size |
|---|---|---|
| `logo/irondost-primary.svg` | Primary wordmark: welcome header, app-level brand contexts and documents | 104 dp wide; default 120–140 dp |
| `logo/irondost-primary-reverse.svg` | Same wordmark on dark backgrounds | Same widths |
| `logo/irondost-signature.svg` | Full washer/iron signature: store identity, marketing, receipts when space permits | 160 dp wide |
| `logo/irondost-symbol.svg` | Existing simplified small mark: compact brand context | 32 dp high; assess details below 32 dp |
| `logo/irondost-app-icon.svg` | Existing launcher artwork; keep the current app icon | Preserve platform safe areas |

All five assets reuse the existing outlined vector artwork. They are not generated approximations. Their master remains `packages/brand/scripts/build-svg.py`; do not edit copied SVG paths as a second master. The wordmark is the default UI identity. The full illustrated signature is a secondary asset, not a hero background.

Clear space: at least half the wordmark's cap height on all sides. Use the light asset on white/light neutrals and the reverse asset on dark surfaces. No recolouring, gradients, additional outlines, squeezing or replacing outlined lettering with live text. At tiny notification/favicon sizes, keep the existing dedicated platform glyph instead of shrinking the complete mark. The mobile UI does not need the tagline. Keep “Wash · Iron · Deliver” only where it is legible and useful outside compact task screens.

## Colour

Preserve logo colours; reduce their application area. White and neutral surfaces carry most content. Royal blue indicates the primary action or a selected state. Yellow indicates an actual offer in a small marker. Sky stays in logo artwork or on dark backgrounds, never as small text on white.

| Token | Light | Dark | Purpose |
|---|---|---|---|
| ink | `#0E1E3D` | Fixed brand colour | Logo outlines and identity |
| royal | `#1F4FD1` | Fixed brand colour | Logo identity; use primary for controls |
| bg | `#F7F8FA` | `#101820` | Page background |
| surface | `#FFFFFF` | `#18222F` | Content, header, sheet and footer |
| surface-soft | `#F0F3F7` | `#223041` | Small grouped summary or placeholder |
| text | `#0E1E3D` | `#EEF3FA` | Primary content |
| text-muted | `#526078` | `#AFBED1` | Supporting content |
| primary | `#1F4FD1` | `#7FA2FF` | Main action and selection |
| on-primary | `#FFFFFF` | `#0E1E3D` | Text on primary fills |
| primary-soft | `#E8EEFC` | `#1C2F63` | Selected radio row or small status |
| border | `#DFE5ED` | `#344254` | Decorative dividers |
| border-strong | `#7D8BA3` | `#6F82A6` | Required control boundaries |
| offer / on-offer | `#FFC93C` / `#0E1E3D` | Same | Small savings marker |

Success, warning and danger retain the existing semantic token pairs. Use labels and/or an icon with each status colour. Never use “blue means clickable” as the only indication of a button. A decorative divider does not need to meet control-boundary contrast; the edge of an input or unchecked radio does.

`contrast.json` measures 28 declared foreground/background pairs in both themes. Text pairs meet 4.5:1; control-boundary/focus pairs meet 3:1. These measurements are for solid colours, not proof of every composited widget, disabled state, image or animation. Existing widget accessibility tests run against the implemented colours. Do not rely on inherited version 1 contrast numbers in comments when token backgrounds change.

In dark mode, status summaries stay on a dark neutral surface. Do not use `surface-inverse` to turn a large tracking panel nearly white. Keep inverse surfaces for short snackbars. Logo colours stay fixed; UI controls use theme-aware primary colours.

## Typography

Outfit is for the logo and screen/section headings. Figtree is for body text, controls, prices and lists. Geist Mono remains an exception for order IDs and coupon codes only. Bundle the required font assets and licences; production typography must not depend on the first network request. The application now bundles Outfit 500/600/700, Figtree 400/500/600/700 and Geist Mono 500 with their OFL licences in `apps/customer/assets/fonts`. Runtime Google Fonts fetching has been removed.

| Style | Size / line height | Weight | Use |
|---|---|---|---|
| display | 30 / 36 dp | 600 | A single important amount when warranted |
| headline | 26 / 32 dp | 600 | Main screen heading |
| title-lg | 20 / 26 dp | 600 | Compact app bar or section heading |
| title | 16 / 22 dp | 600 | Item name, order status, setting label |
| body and body-lg | 16 / 24 dp | 400 | Instructions, addresses, input text |
| label | 15 / 20 dp | 600 | Buttons |
| label-sm | 13 / 18 dp | 600 | Small status and field label |
| caption | 13 / 18 dp | 400 | Timestamp and helper text |
| order-id | 14 / 20 dp | 500 | ID or code, never paragraph copy |

No letterspacing on ordinary mixed-case text. Use tabular figures for prices and numeric comparisons. Prefer left-aligned instructions. Reserve centring for a short success/empty title, not several lines of explanatory text. Use proper minus signs and time ranges. Screen reader labels should read a time window clearly rather than depending on punctuation alone.

Support long names, ₹ amounts, mixed service names and 200% text. Header/body widgets must grow or scroll. Do not shrink text to fit, disable system scaling, or ellipsize essential prices, dates, payment consequences and primary-action labels. A short Home address preview may truncate if the full address is available in its switcher.

## Layout and spacing

- Use the existing 4 dp spacing scale: 4, 8, 12, 16, 20, 24, 32 and 48.
- Default screen gutter: 20 dp. On 320 dp screens, long forms or lists may use 16 dp. App bars, content and footers align to the same gutter.
- Section gaps: 24 dp; use 32 dp between unrelated groups. Related label/value gaps: 4–8 dp. List row vertical padding: 12–16 dp.
- Primary buttons: minimum 52 dp height; every tappable area at least 48 × 48 dp. These are minimums, not fixed constraints when text wraps.
- App bar: 56 dp plus safe area. Bottom navigation: 64 dp plus safe area. Keep four labelled tabs: Home, Orders, Offers, Account.
- Text fields: minimum 52 dp height; label above, error/help below. Content grows at large text.
- At text scale above 1.3, move narrow metadata pairs to vertical layout. Reflow at constraints, not just at a device-name breakpoint.
- On a tablet, retain a centred readable width of about 480 dp for v1; do not introduce a new tablet IA during this pass.

`IdSpace.s4` is 16 dp and `IdSpace.s5` is 20 dp. Customer screen gutters use `s5`; internal gaps use the smaller scale as appropriate.

## Shapes and elevation

| Token | Installed value | Use |
|---|---|---|
| radius-sm | 8 dp | Small thumbnail or badge |
| radius-md | 10 dp | Button and input |
| radius-lg | 12 dp | Group that needs an enclosing boundary |
| radius-xl | 20 dp | Modal sheet top corners |
| radius-full | 999 dp | Avatar or compact status only |

Resting content has no shadow in either theme. Use space or a divider before adding a containing panel. A real modal may use the sheet shadow; a fixed booking footer uses a top divider. No card within a card unless the inner region communicates a genuinely different state. Quantity controls are neutral outlined rectangular controls; filled royal blue belongs to the footer action.

Remove `Bubble` from Welcome's secondary composition, Home hero/offer, Offers, tracking status, confirmation, receipt, permission preview and decorative empty states. Keep detailed logo art in the selected brand assets. Do not replace bubbles with blobs, gradients, glass panels or random decorative shapes.

## Component contracts

Build these on top of existing widgets; do not create a separate component per screen.

| Component | Structure | Required states |
|---|---|---|
| AppHeader | Back, one title, optional secondary action; same gutter | Back destination, long title, 200% text, accessibility label |
| FlatSection | Heading, content, optional divider; no default shadow | Loading, data, inline error |
| ItemRow | Item name, service/unit/price, Add or neutral stepper; optional real image | Zero/selected/max, discount, unavailable, long names |
| QuantityControl | Minus, quantity, plus; 48 dp hit areas; explicit item semantics | Zero, selected, max, disabled, focus |
| DateStrip | Full date semantics, weekday and date | Selected, unavailable, focus, horizontal scroll |
| SlotRow | Name and time window left; radio right; divider | Selected, unselected, closed with reason, 200% text |
| ReviewRow | Label, value, optional Change action | Long address, stacked date/time, disabled with reason |
| PriceSummary | Subtotal, delivery, discount, total; paid/due where relevant | Quote loading, minimum shortfall, code error, count changes |
| BottomActionBar | Total/summary when needed, one primary action; top divider | Enabled, disabled with inline reason, submitting, keyboard inset |
| OrderSummary | Actual status, next event, ID, amount; one contextual action | Active, overdue estimate, past, cancelled, refund pending |
| Timeline | Actual completed events, current event, labelled future targets | Delay, all terminal statuses, missing actual timestamp |
| PromoRow | Benefit, eligibility terms, code and Copy code | Eligible/ineligible, copied announcement, expired, loading |
| AddressRow | Label, full address, selected/default/serviceability metadata | Selected, unselected, unavailable, edit, long address |
| SettingsRow | Icon, label, optional value and chevron | Explicit button semantics when actionable; disabled explanation |
| MessageRow | Title, body, time, one unread dot | Read/unread, deep link, no order target, mark-read failure |
| StateView | Small meaningful icon, title, brief explanation, one next action | Empty, offline, unavailable, paused, update, pending payment |
| ActionSheet | Title, consequence, scrollable body, clear actions | Short/long text, loading, inline error, blocked, keyboard open |

Buttons use named variants rather than local hardcoded styling. On loading, preserve width, prevent duplicate submissions, show a foreground-safe spinner and mark the semantic control busy/disabled correctly. The button wrapper disables both its actual callback and semantic enabled state while loading.

## Page composition

Home: compact address header → returning customer's active-order summary → booking CTA → service/price rows → small available offer → existing navigation. If there is no active order, booking becomes the first content block. All service offerings still come from the API.

Booking: catalogue's divided list → basket items and server bill → pickup/delivery selection → plain checkout review → provider payment flow → useful confirmation. Add a small progress label only where it helps; do not add new mandatory steps.

Tracking: actual status and next event → timeline → relevant partner contact → bill/payment → help or allowed cancellation. A missed date is labelled as an overdue estimate. Future timeline steps must not look completed.

Account: profile → addresses/notifications/help → policies → logout/deletion. Keep editable identity and destructive actions visually separate. Do not introduce a photo picker for an initials avatar during this pass.

## Service artwork and campaign banners

Use the bundled transparent 3D iron, washing machine and hanging blazer for the three service categories. Assets live in `apps/customer/assets/services/`. Their family uses matte royal blue, warm white and navy details, an upper-left light source and a simple three-quarter silhouette. Display at 48 dp on Home and 28 dp inside catalogue tabs; keep the text label outside the image. Admin category artwork replaces the bundled fallback when available. These decorative images are excluded from semantics because their row already names the service. Reserve line icons for controls and status.

Campaign artwork is 2:1 landscape. Keep full images contained rather than cropping terms. Important terms also appear in readable Flutter text through promotion titles/terms; images cannot be the only accessible source. The carousel has manual swipes, 48 dp previous/next controls, a position announcement, reduced-motion support and an explicit Offers destination. Promotions with artwork use existing server validity windows; standalone banners use existing admin activity/sort settings. Campaign images are hosted through admin uploads, rather than bundled into the app. See [campaign assets, prompts and configuration](campaigns/index.html).

List recovery uses `ListStateView`: a plain optional 32 dp status icon, heading, concise message and a real recovery action. Use an always-scrollable viewport so short states retain pull-to-refresh and large text can scroll. Omit absent icons entirely. Catalogue and search use the same loading/failure/empty components; never label a failed or empty price list as no query matches. Skeleton proportions follow the final row layout and their decorative placeholders are excluded from semantics.

Address summaries use `ReviewRow` so their Change action moves below the value on narrow or enlarged-text layouts. Search input toolbars grow with the scaled input line height and leave room for the focus border. Keep real text scaling enabled. Keyboard checks must include the reduced content viewport, not just the full phone height.

Campaign refreshes reset carousel page, image, caption and destination together when the ordered content changes. Booking destinations use the same address/serviceability check as the normal booking entry. The welcome offer artwork names Wash & iron, but its inactive draft must not be advertised until server pricing can grant two shirts and two pants free to an eligible first-order customer.

## Interaction, loading and error rules

One primary action per view. Secondary actions are text or neutral outline controls with full touch targets. A primary button may include a price, but its label must explain the consequence: Book, Place order, Pay, Track, Retry or Save.

Use content-shaped skeletons for initially loaded lists. Reserve spinners for submitted actions, location determination and immediate provider work. Cached content with an offline strip is preferable to replacing the entire tab with a red empty illustration. Quotes must still be revalidated by the server.

Errors stay near the affected input or section. Global outage gets one Retry action and optional support. Explain what is still saved or booked only when the state provides that evidence. Do not guarantee refund timing, payment outcomes or future service availability as a stylistic reassurance.

Selection transitions: 120–180 ms. Use platform navigation and sheet transitions. Honour reduced motion. No decorative looping motion, bouncing CTAs or delayed staged reveals on routine screens.

## Implementation and verification

1. Complete Phase 1 in `AUDIT.md` before applying visual polish. Preserve quantities, server quote logic, slot availability, payment verification, idempotency, cancellation rules and account-deletion restrictions.
2. Update the customer-specific `packages/design-tokens/customer.tokens.json` master and run `dart run tool/gen_tokens.dart` from `apps/customer`. Never hand-edit generated tokens. Build the component contracts above and update screen references, since token changes alone will not remove nested containers or change composition.
3. Replace runtime font fetching with bundled weights and licences. Update stale font/brand guidance in repository docs.
4. Run `flutter analyze`, existing tests, real-font renders at 320/390/430 dp in both themes, and 200% text. Make missed taps fatal in interaction tests. Contrast measurements are necessary but do not replace rendered checks.
5. See `IMPLEMENTATION.md` for verified local flows and provider/device checks still required before release.

The plan changes presentation and usability. Any new area-alert signup, automatic refund workflow, notification preference system or dispatch rule is a separate product change, not part of adopting this system.
