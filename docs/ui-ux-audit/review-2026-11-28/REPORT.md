# Customer app UI/UX audit: installed build on a real iPhone (28 November 2026)

**What was reviewed:** the 2.1.0 build (`claude/determined-kalam-a325dc`, commit `931d7f8`) running on an iPhone 15
(393 × 852 pt, light mode), signed in to a real customer account against the live API. Every screen was opened on the
phone and captured through the app's debug service: `phone/` (29 captures). Screens that need a signed-out or
special state (welcome, sign-in, OTP, out-of-area, dark mode) come from the fixture renderer of the same code:
`fixtures/` (122 captures, light and dark).

Method: design-audit (15 dimensions, reduction filter, three phases), design-critique framing, and a systems view:
most issues below share a handful of root causes in shared components, so fixing the component fixes every screen.

## Overall impression

The app reads calm and trustworthy: one type family, one blue, generous cards, honest copy, good empty states, and
the booking flow (catalogue → basket → time → checkout) is short and clear. The biggest problems are not visual
taste. They are **stale data shown as if it were live**, and **cards that get cut off**, either by scrolling under
a flat header or by sitting behind a sticky footer. Both repeat on many screens because they come from shared layout code.

## Root causes (fix once, fixes many screens)

| # | Root cause | Where it comes from | Screens affected |
|---|---|---|---|
| A | Headers have no "scrolled" state. Transparent or flat app bars let content slide underneath with no separation | `theme.dart` `appBarTheme` (`scrolledUnderElevation: 0`), transparent app bars in Home, Orders, Basket, Account | Home, Checkout, Catalogue, Order detail, Search |
| B | Scroll content has no bottom inset for sticky footers | each screen's `ListView` padding | Basket, Change pickup time, Search, Catalogue |
| C | The header band is a fixed colour (`#F2F6FE`) while page backgrounds vary (gradient backdrop or plain white) | `theme.dart:177` | Terms, Privacy, Edit profile, Saved addresses, Address details |
| D | Hand-rolled rows that skip `IdListRow` | `help_screen.dart:155` and `:223` (`horizontal: 0`) | Help |
| E | Time-based copy without a "this time has passed" state | `order_detail_screen.dart:805`, order card, Home active-order card | Order detail, Orders, Home |

## Phase 1: Critical (actively hurts the customer)

| # | Finding (evidence) | Severity | Recommendation |
|---|---|---|---|
| 1.1 | **A 24-day-old order is presented as live.** ID001001's pickup window was Wed 4 Nov, 11 AM–4 PM. Today Home says "Booked · Pickup Wed 4 Nov … Track", Orders shows step 1 "Booked", and the detail says "Pickup running late … we'll call you if we can't make it **by 4 PM**". The customer paid ₹130 online. (`phone/01-home-a`, `02-orders`, `04-order-a`) | 🔴 | Add a **missed pickup** state once the window's end has passed: amber hero "We missed your pickup on Wed 4 Nov", one primary action "Pick a new time", secondary "Cancel and refund ₹130", and WhatsApp. The "by 4 PM" sentence must carry the date, or disappear once the time has passed. Home's active card should say "Missed pickup · pick a new time", not "Track". *Also an operations issue: this real paid order needs action from the team today.* |
| 1.2 | **Content scrolls under the header with no separation** (root cause A). Home: "Popular prices" and its labels slide under the address bar (`01-home-b/c`). Checkout: the heading "Anything we should know about your clothes?" is sliced in half under the title (`08-checkout-b`). Catalogue: the item card loses its rounded top and butts against the tab chips (`07-catalogue-end`). | 🔴 | Give every app bar a scrolled-under state: page background fill plus a 1 px `border` hairline (or a soft shadow) once content scrolls beneath it. Home's transparent header gets the same fill when scrolled. The catalogue's category chips belong in the pinned header, so the list scrolls cleanly below them. |
| 1.3 | **Cards cut off behind sticky footers** (root cause B). Basket: the bill card ("Items (2) ₹30") is sliced by the Total bar (`08-basket`). Change pickup time: the "Pick Sun, 7–11 AM" button sits half under the footer (`05-resched`). Search: the results card ends abruptly mid-row (`07-search`). | 🔴 | Bottom padding on every scrolling body = footer height + `IdSpace.s5`, applied in one place (for example, a shared `FooterInset`). Search results become plain rows on the page rather than one fixed card. |
| 1.4 | **Help cards have no inner padding** (root cause D). The WhatsApp and Call icons and all the FAQ text touch the card edge, unlike the list group directly below (`06-help`). This is the most visible "card issue". | 🔴 | Build the contact rows and FAQ rows on `IdListRow` / `IdListGroup` padding (`IdSpace.s4` horizontal), the same as the rows below them. |
| 1.5 | **Pickup time opens on a dead day.** Late in the day every window "Today" is closed, yet Today stays selected and Continue is disabled. The customer must find the hint "Pick Sun, 7–11 AM" (`08-schedule`). | 🟡 | Open on the earliest day that has an open window, with that window selected. Keep the note "Today's pickups have closed" as a caption. *Small change to the schedule's default choice, flagged for the build agent.* |

## Phase 2: Refinement (consistency and hierarchy)

| # | Finding | Recommendation |
|---|---|---|
| 2.1 | Two-tone header band on white pages: Terms, Edit profile and Saved addresses show a pale-blue band above a white body (`09-terms`, `06-edit`, `06-addresses`). Root cause C. | The app bar takes the page's own background (`Scaffold.backgroundColor`) everywhere, and separation comes only from the scrolled state in 1.2. |
| 2.2 | Back icons differ: Saved addresses uses `arrowLeft` (`addresses_screen.dart:29`, also Address details and Search) while every other screen uses the chevron. | One back affordance: `BackButton` with the theme icon everywhere. |
| 2.3 | Saved addresses shows the bottom tab bar. The other Profile pages (Help, Edit profile, Notifications, Offers) do not. | Open Saved addresses full screen like its siblings (route outside the tab branch), or keep the tab bar on all Profile pages. Pick one. |
| 2.4 | Order card: "Booked" and the order number don't share a baseline, and the number floats mid-row. The item list breaks inside words ("T-↵shirt") and splits "4↵PM" (`02-orders`). The 4-segment progress bar doesn't match the 5-step timeline. | Put the status and number on one row (number right-aligned, muted). Summarise items as "6 items · Bedsheet, Dupatta +4". Use non-breaking spaces in times (`keepLastWordsTogether`). Use 5 segments. |
| 2.5 | Basket rows put the line total top-right and the stepper alone on a line underneath, which costs about 140 pt per item (`08-basket`). | Use the catalogue row layout: name, rate and total stacked on the left, stepper on the right, in one row. That halves the height. |
| 2.6 | Order detail repeats itself while a pickup is late. The amber notice and the new "now" panel both say the team is still finding a partner. "Change time" (link) duplicates the "Change pickup time" row. The notice mixes an outline pill with two text links (`04-order-a/b`). | While delayed, the "now" panel shows only its action, not the sentence. In the notice: one outline button "Call us" plus one text action "Cancel order". Keep rescheduling in the list row. |
| 2.7 | Home hierarchy drifts: "Everything for your clothes" is muted grey while "Popular prices" is dark. The service tiles use three different layouts (chip-title-price, eyebrow-title, eyebrow-title-art). The category under each popular price is blue for Laundry and grey for Ironing (`01-home-a/b`). | One section-title style. One tile layout (eyebrow, title, one line of price; art bottom-right). Category labels all `textMuted`. |
| 2.8 | Profile → "Help and support" still says "Call or email", but WhatsApp is now the first channel (Profile tab). | "WhatsApp, call or email", or drop the value. |
| 2.9 | Notifications: "Mark all read" touches the right edge, and each notification is a separate card with a divider as well (`06-notifs`). | Put `IdSpace.s4` trailing padding on app-bar actions. One card per day group, with dividers between rows. |
| 2.10 | Catalogue category chips run off the right edge ("Dry Cleaning" is cut, with no fade). The struck-through old price is tiny and low contrast (`07-catalogue`). | Add a right fade or start the row inset so the cut shows on purpose. Show offers as "₹15 · was ₹20" in `caption` `textMuted`. |
| 2.11 | Items and bill shows "Due ₹0" on a fully paid order. The header line repeats the stale delivery date (`05-bill`). | Hide "Due" at zero. The header uses the same missed-pickup state as 1.1. |
| 2.12 | OTP: "…43210.Change" has no space. Phone and OTP screens open with an empty header band (fixtures `otp`, `phone`). | Add the space, and a back button in the band (or remove the band). |

## Phase 3: Polish

| # | Finding | Recommendation |
|---|---|---|
| 3.1 | First-pickup checklist (new in 2.1.0): done rows are struck through, which reads as "cancelled". The card also shows to customers whose address is outside the service area, who cannot book (fixture `home-outside-the-area`). | Show done rows as a green tick with muted text, no strike. Hide the card when the selected address is not serviceable. Collapse it to a single progress line once 3 of 4 required steps are done. |
| 3.2 | Home banner copy "DOORSTEP LAUNDRY @ price shown first!" (admin content). | Edit it in the admin banner tool, for example "Doorstep laundry · price shown before you book". |
| 3.3 | "Report a problem" is offered before pickup, when there is nothing to inspect yet. | Before pickup, show WhatsApp only. Show Report from the moment the clothes are picked up. |
| 3.4 | The order help sheet has no email option because the live config has no support email (`09-orderhelp`). | Set `supportEmail` in the API config if email support is wanted. |
| 3.5 | Dark mode was checked only in fixtures (the phone is in light mode). Fixtures show the same header and footer issues. | Re-check on the phone in dark mode after Phase 1. |
| 3.6 | Stage illustrations for future steps are at 30% opacity and small (40 pt). On the phone they read as noise rather than a preview. | Future steps: no picture. Show the picture only for done steps (small) and the current step (56 pt). |

## Accessibility

- **Contrast:** body and labels pass. The struck-through old price and the faded future stage art fall below 3:1 (2.10, 3.6).
- **Touch targets:** steppers, chips and rows meet 44 pt. "Mark all read" sits against the screen edge (2.9).
- **Readability:** the order-card wrapping (2.4) and missing space on OTP (2.12) hurt scanning. Nothing else.

## What works well

- One type family and a restrained blue. Prices are always visible before booking.
- Empty states (Past orders, Basket, Offers, Reports) say what to do next, with a single action.
- Checkout is honest: estimate, contact number, address, pickup and delivery, then pay, all on one screen.
- The closed-day explanation on the pickup picker is clear. Only the default selection is wrong (1.5).
- The order help sheet is focused: quote this number, WhatsApp, call.

## Priority order

1. **1.1 Missed-pickup state** (and an ops follow-up on the real ID001001 order).
2. **1.2 + 1.3 Header scrolled-state and footer inset.** Two shared fixes clear the "cut card" look on about 8 screens.
3. **1.4 Help padding and 2.1–2.3 header and back consistency.** Small, high-visibility consistency wins.

Nothing in this report has been implemented yet; each phase waits for approval.
