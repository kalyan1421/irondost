# TextField

A labelled single-line input. The label sits above the field, never only as a placeholder.

## Consumer provides
- `label`, `value`, `onChanged`; optional `placeholder` (an example, not an instruction), `helper`, `error`, `prefix`, `trailing` icon, `keyboardType`, `autofillHints`.

## Variants
- **Default:** name, flat/house number, landmark, coupon code.
- **Phone:** fixed `+91` prefix, `TextInputType.phone`, 10 digits, `AutofillHints.telephoneNumberNational`. Format as "98765 43210" while typing.
- **Search:** leading search icon, clear button once there is text.

## States
- Height `input-height` (52), radius `radius-md`, value in `body-lg` (16px, avoids iOS zoom).
- Rest: 1px `border-strong`. Focus: 2px `primary`. Error: 2px `danger` plus the message under the field with an alert icon.
- Validate on blur or on submit, never on every keystroke. On submit errors, focus the first invalid field.

## Flutter
`TextFormField` with an `InputDecorationTheme` (outline border, `floatingLabelBehavior: never`, label rendered above as a `Text` in `label-sm`).

## Do / Don't
- Do write errors that say how to fix it: "Enter a 10-digit mobile number".
- Don't put the label inside the field. Don't use red for anything but errors.
