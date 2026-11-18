# Design critique: IronDost customer app (iOS and Android)

**Stage:** refinement of a shipped build, preparing a visual refresh.
**Reviewed:** the Choose items, Pickup and delivery, and Checkout screens (store screenshots of the current build), the Welcome screen (from `welcome_screen.dart`) and the theme (`lib/design/theme.dart`, `tokens.g.dart`).
**Not reviewed visually:** Home, Basket, Orders, Tracking, Account, Offers. Findings about them would be guesses; review them on a device before acting on this list.

## Overall impression

A tidy, trustworthy, low-effort-to-read booking flow: one task per screen, plain language ("A rough count is fine. Your partner confirms it at pickup."), a persistent bottom action. The biggest opportunity is character. Every screen is white with one blue, so the app could belong to any bank or delivery service, and nothing says *ironing*, *Hyderabad* or *Dost* (friend).

## Usability

| Finding | Severity | Recommendation |
|---|---|---|
| Checkout has no contact-number row, and a customer who signs in with Google has no number at all. Orders now require a verified number. | 🔴 Critical | Add a "Contact number" row at the top of Checkout (value + Change, or an inline "Add number" state that blocks the Pay button with a reason). |
| Checkout shows the price breakdown only below the fold; the total appears only inside the button ("Pay ₹15"). | 🟡 Moderate | Put a three-line summary (items, delivery, total) above the payment choice, or make the button area show total plus "see breakdown". |
| Choose items: every row is an outlined "Add" box of equal weight; "per piece" is repeated on each row; there is a large empty area under three items. | 🟡 Moderate | Show "per piece" once as a section note; turn Add into an inline stepper after the first tap; use the empty space for turnaround ("Back to you in 24 hours") and a count helper. |
| Three separate "Change" links on Checkout, all the same blue weight. | 🟡 Moderate | Make the whole row tappable with a quiet chevron; keep colour for the one primary action. |
| Pickup uses two selection languages: filled/outlined chips for the date and radio circles for the slot. | 🟢 Minor | Pick one (selectable rows for both, or chips for both). |
| "Earliest available delivery" is a pre-made choice with a small "Change" link. Delivery timing is a major trust point for this category. | 🟢 Minor | Offer it as two selectable options ("Tomorrow evening" / "Pick another time") instead of hiding the choice. |

## Visual hierarchy

- **What draws the eye first:** the large blue action bar at the bottom, on every screen. That is correct, and the one thing that works as a system.
- **Reading flow:** top-left title, then a left-aligned list. The screen title sits indented from the left margin that the content uses, so the two edges do not line up (title starts about 1.5x further in than the list text).
- **Emphasis:** price is bold but all prices look the same weight as item names, so scanning for "which is cheaper" is slow. Section headings ("Delivery", "Pay with") are the same size as the page question ("When should we collect?").

## Consistency

| Element | Issue | Recommendation |
|---|---|---|
| Service tabs | Photographic product shots (iron, washing machine, blazer) have different lighting and styles; they read as stock images against a flat UI. | One illustration or type treatment for all three, or no pictures. |
| Colour | One blue is used for links, selected state, tabs and the main button. | Separate roles: one brand colour for identity, one for the action, one for status. |
| Type | Figtree and Outfit are neutral geometric sans, as are most delivery apps. | See the typography directions (Round 1) for character options. |
| Language | English only, in a Telugu, Hindi, Urdu and English city. | Plan for Telugu and Hindi strings; check line heights for those scripts before choosing a face. |

## Accessibility

- **Contrast:** the token file documents 6.8:1 for primary on white and 6.4:1 for the accent on white. Muted grey captions ("per piece", "Earliest available delivery") were not measured here; check them.
- **Touch targets:** buttons are about 48 pt tall and "Change" links are text buttons with a 48 pt minimum in the theme; adequate.
- **Readability:** body text is comfortable. Caption sizes are the first thing to break when the user's text size is raised; test at 130-200%.
- **Colour only:** selected states pair colour with a filled radio or border, which is fine.

## What works well

- Plain, specific copy that sets expectations at the point of doubt.
- One decision per screen and a bottom action that never moves.
- Honest trust lines near money ("Secure payment by Razorpay"; cash on delivery explained in words).
- Good use of a real address and real time windows instead of placeholders.

## Priority recommendations

1. **Give the app a voice.** The brand name already carries the idea (Iron + Dost, a friend who irons). Make colour, type and tone say that, instead of one blue everywhere. This is what the typography directions test.
2. **Fix the order path for the new rules.** Contact number row in Checkout, price summary above the payment choice, and a clear block-with-reason state when the number is missing.
3. **Make choosing items quicker and more rewarding.** Inline steppers, a running total that stays visible, one "per piece" note, and use the empty space to answer "when do I get it back?".
