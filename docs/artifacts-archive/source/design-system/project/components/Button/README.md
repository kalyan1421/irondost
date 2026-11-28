# Button

The tappable action. One `primary` button per screen carries the step forward ("Continue", "Place order", "Pay ₹540").

## Consumer provides
- `label`: a verb phrase in sentence case, two to four words.
- `onPressed`: null renders the disabled state.
- `variant`: `primary` | `tonal` | `outline` | `text` | `danger`.
- Optional `icon` (Lucide, `icon-md`, leading), `loading`, `expand` (full width).

## Variants
| Variant | Use when |
|---|---|
| primary | The one forward action on the screen; pinned to the bottom in flows. |
| tonal | A strong second action beside a primary ("Add address"). |
| outline | Neutral alternatives ("Change slot", "Call partner"). |
| text | Low-emphasis links inside content ("View all", "Resend OTP"). |
| danger | Destructive confirmations only ("Cancel order", "Delete account"); always behind a confirmation sheet. |

## States
- Height `button-height` (52), radius `radius-md`, label in `label`. Minimum width `touch-target`.
- **Pressed:** `primary-pressed` fill, scale 0.98 for 100ms.
- **Disabled:** 38% opacity, no ripple. Prefer explaining why below the button over silently disabling.
- **Loading:** the label is replaced by a spinner, the width is kept, and taps are ignored until the request settles.
- **Focus (keyboard, switch access):** 2px `focus-ring` outline, 2px offset.

## Flutter
`FilledButton` (primary), `FilledButton.tonal`, `OutlinedButton`, `TextButton`, all themed from `ColorScheme` with `minimumSize: Size(48, 52)`. Wrap with `Semantics(button: true)` only when building custom.

## Do / Don't
- Do put the amount on payment buttons: "Pay ₹540".
- Don't stack two primary buttons. Don't use all caps. Don't use `danger` for "Log out".
