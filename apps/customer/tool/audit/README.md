# Customer UI audit capture tool

This opt-in fixture renderer lives outside `test/`, so normal `flutter test` does not write screenshots or intentionally fail on known audit defects. It reuses existing repository fakes and loads fonts so visual layout checks use realistic text metrics. It does not call the real API, request device permissions, open Razorpay, or delete an account.

From `apps/customer`:

```sh
./tool/audit/capture.sh --dart-define=AUDIT_CAPTURE_DIR=../../docs/ui-ux-audit/after
./tool/audit/capture.sh --dart-define=AUDIT_STRESS=true
./tool/audit/capture.sh --dart-define=AUDIT_STRESS=true --dart-define=AUDIT_WIDTH=390
```

The first command renders 47 representative views in both themes (94 cases) at 390 × 844 dp into the specified `after/` folder. Create the requested output directory before running; without `AUDIT_CAPTURE_DIR` the default is `docs/ui-ux-audit/screens`. The sheet scenarios target real controls; blocked deletion is a fake repository rejection and asserts the actual blocked heading. Capture mode does not assert every accessibility dimension or every content variation.

The stress commands draw 39 screen/state variants in both themes at 200% text, 740 dp height and the specified width. They assert that Flutter reports no layout errors. The implemented customer UI passes all 78 cases at 320, 390 and 430 dp widths. The original baseline failed 10 cases at 320 dp and 4 at 390 dp. Overlay stress is still covered separately by existing tests and requires a strict hit-test/device pass.

Fonts are cached under `/tmp/irondost-audit-fonts` and fetched from the official Google Fonts repository when missing. This is renderer infrastructure, not a change to production font delivery. The shipped app bundles production font weights and licences; it does not fetch fonts at runtime.

The images use repository fixture dates and amounts. Tab screens are isolated without AppShell. For real safe areas, current data and navigation, see `after/native-*.png` from the updated iOS walkthrough. Real SMS, Maps SDK rendering, provider checkout, native screen reader operation and all-form OS keyboards at enlarged text still require device verification. Profile and item-search keyboard invocation were reviewed on iOS; the supplemental renderer checks a simulated keyboard inset across all seven form families.

## Supplemental states and keyboard layouts

`AUDIT_EXTRA_STATES=true` renders 12 initial-loading, empty and offline states in both themes. `AUDIT_KEYBOARD=true` selects seven form families and reserves a 300 dp keyboard inset. Both flags work with `AUDIT_STRESS=true`; stress uses 200% text and 740 dp height. Normal capture defaults are 390 × 844 dp and 100% text; `AUDIT_WIDTH` and `AUDIT_SCALE` can change capture width/text scale. Keyboard captures show only the application layout, not an OS keyboard image.

```sh
mkdir -p ../../docs/ui-ux-audit/after/states ../../docs/ui-ux-audit/after/keyboard ../../docs/ui-ux-audit/after/keyboard-large
./tool/audit/capture.sh --dart-define=AUDIT_EXTRA_STATES=true --dart-define=AUDIT_CAPTURE_DIR=../../docs/ui-ux-audit/after/states
./tool/audit/capture.sh --dart-define=AUDIT_KEYBOARD=true --dart-define=AUDIT_CAPTURE_DIR=../../docs/ui-ux-audit/after/keyboard
./tool/audit/capture.sh --dart-define=AUDIT_KEYBOARD=true --dart-define=AUDIT_WIDTH=320 --dart-define=AUDIT_SCALE=2 --dart-define=AUDIT_CAPTURE_DIR=../../docs/ui-ux-audit/after/keyboard-large
./tool/audit/capture.sh --dart-define=AUDIT_STRESS=true --dart-define=AUDIT_EXTRA_STATES=true --dart-define=AUDIT_WIDTH=430
./tool/audit/capture.sh --dart-define=AUDIT_STRESS=true --dart-define=AUDIT_KEYBOARD=true --dart-define=AUDIT_WIDTH=430
```

The final supplement has 24 lifecycle captures, 14 normal keyboard-inset captures and 14 captures at 320 dp / 200% text. Together with the original 94 captures, these give 146 fixture images. At each of 320/390/430 dp, the base 78, lifecycle 24 and keyboard 14 stress cases pass, for 348 checks total. Visual review remains necessary: a fixed toolbar can clip an input and an address can become excessively narrow without triggering a layout exception. Dedicated regression tests cover those defects.
