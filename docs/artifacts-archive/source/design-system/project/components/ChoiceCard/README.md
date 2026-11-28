# ChoiceCard

A large single-choice option with an icon, title and one line of explanation. Used for payment method and address type.

## Consumer provides
- `icon`, `title`, `description`, `selected`, `onTap`; optional `trailing` (e.g. a "Recommended" chip).

## Payment methods (v1)
- **Pay online:** UPI, cards, netbanking via Razorpay. Description "UPI, cards and netbanking".
- **Cash on delivery:** "Pay the partner when your clothes come back".

## Behaviour
- Radius `radius-lg`, 1px `border`; selected gets a 2px `primary` border and a filled radio. Never colour alone: the radio changes too.
- Whole card is the hit target.
