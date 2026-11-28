# OtpInput

Six boxes for the SMS code. One hidden field drives them so paste and SMS autofill work.

## Consumer provides
- `length` (6), `onCompleted(code)`, `error`, `resendIn` seconds.

## Behaviour
- Boxes are 48×56, radius `radius-md`, digits in Outfit 24/700. The active box has a 2px `primary` border and a caret.
- Use `AutofillHints.oneTimeCode` (iOS) and the SMS User Consent API (Android). Submit automatically on the sixth digit.
- Under the boxes: "Resend code in 0:24", then a `text` button "Resend code". Offer "Change number" as a second text button.
- Errors replace the helper line ("That code is incorrect. 2 tries left.") and clear the boxes.

## Accessibility
One `Semantics` label "Verification code, 6 digits"; announce each entered digit. Never 6 separate focus stops.
