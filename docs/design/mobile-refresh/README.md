# Mobile UI/UX refresh — 1 November 2026

Implemented locally in the Flutter customer app. User direction: clean and friendly, preserve IronDost blue, and compare two existing typography concepts before choosing. All mobile screen families are in scope.

Open [the review gallery](index.html), [three-screen preview](preview.jpg) or [typography comparison](typography-comparison.jpg). The [update plan](../mobile-ui-ux-update-plan.md) records scope and priorities.

## What changed

- **Shared typography:** Junction Bold headings replace Outfit headings throughout the customer app. Figtree continues to carry body text, controls and important amounts; it supplies unsupported ₹ glyphs in headings. Geist Mono remains for order IDs/codes. The existing logo and blue palette are retained. Junction files and the OFL licence are bundled locally.
- **Typography decision:** compared Charis headings from direction A with Junction headings from F on the same Home, Catalogue and Checkout baseline, in both themes. Selected F for its approachable sans serif character and fit with task-oriented screens. These are heading adaptations, not reproductions of the original concept compositions. The decision is a design assessment, not a measured usability result.
- **Checkout:** the estimate and final-count explanation now precede payment selection; a contact-number row shows the verified number or a direct Add number action. The existing verification flow still handles booking. Cancelling contact setup keeps the basket. The optional pickup note expands on demand, retains entered text through the existing checkout state and shows “Note added” after entry.
- **Selection and navigation:** payment methods, date/time choices, cancellation reasons, addresses, catalogue services and order tabs have consistent boundaries, selected surfaces and non-colour indicators. Bottom navigation gains a soft-blue selection indicator. Disabled slot copy remains readable.
- **Garment-care context:** a shared, quiet shirt-and-copy note explains the service on Welcome and the count estimate in Catalogue. Active-order summaries have a contained status surface, including a warning surface when delivery estimates are missed.
- **Small-screen sign-in:** when the keyboard is visible, Google sign-in and policy links move into the scrollable form. Send code remains reachable; secondary options no longer crowd out the input at 200% text on a 320 dp phone.
- **Form help:** helper text now sits below the input/counter area and wraps fully. The large-text visual review caught truncation that the overflow assertions did not detect.

The [UI/UX Pro Max skill](/Users/kalyan/.codex/skills/ui-ux-pro-max/SKILL.md) was consulted for Flutter, touch, hierarchy and accessibility guidance. It is now installed globally for Codex; the project-local copy and lock entry were removed at the user's request. Product-wide search suggestions were checked for fit; unrelated marketing patterns and replacement palettes were not applied. Original design explorations and pre-existing OTP/release/store work were preserved.

## Coverage

The gallery pairs all **47 representative views × two themes** from the fresh baseline with the updated Flutter captures. The shared theme reaches all customer screen families; layout changes focus on booking, selection and constrained forms. Every screen does not receive a new route or a new feature.

| Family | Result |
|---|---|
| Launch, welcome, phone, OTP, profile setup | Existing logo preserved; heading system applied; Welcome care note and keyboard-aware sign-in layout. Existing OTP edits retained. |
| Address search, map fallback, outside-area state, details and saved addresses | Heading system; padded address cards and clear selected surfaces; existing serviceability rules retained. |
| Home, catalogue, search and basket | Heading hierarchy, contextual order panel, service selection and count guidance; existing quantity controls and server quote retained. |
| Pickup/delivery and delivery sheet | Consistent selection treatment and legible closed-slot states. |
| Checkout and its note/contact variants | Estimate-first review, explicit contact number and optional-note disclosure. |
| Confirmation, payment failure, pay-due sheet, receipt and bill | Shared heading system and payment-choice treatment; existing pending/failure/paid behavior retained. |
| Orders, tracking and cancellation | Shared headings, contained segment selection and reason options; existing statuses and operational actions retained. |
| Offers, inbox, empty/loading/offline states | Shared type and existing contextual recovery controls; additional fixture captures reviewed. |
| Account, profile, support, policies, logout/deletion sheets and system gates | Shared type and rounded surface consistency; existing consequences, recovery and restrictions retained. |

## Verification

See `verification/` for command output. Tests render actual widgets with fake repositories; fixture amounts, dates, people and campaigns are not live business data. The test suite includes Android/iOS tap-target, label and contrast checks. Real-font audit captures provide separate visual evidence.

Verification results are recorded in [verification summary](verification-summary.json). The capture harness is opt-in; it never calls payment providers, sends SMS or deletes a real account.

| Check | Result |
|---|---|
| Flutter analysis | No issues |
| Customer tests | 457 passed |
| Updated primary captures | 94 passed: 47 views × two themes |
| Lifecycle / keyboard / checkout supplements | 24 / 16 / 4 passed; another 16 large-text keyboard captures passed |
| 200% text at 320, 390 and 430 dp | 78 base + 24 lifecycle + 16 keyboard + 4 checkout cases passed at each width |
| 200% text at 375 dp | 78 base cases passed |
| Landscape, 844 × 390 dp at normal text | 78 base cases passed |
| Native development builds | iOS simulator and Android debug builds passed |
| iOS launch | Opened in iPhone 17 Pro simulator; offline recovery screen inspected |
| Gallery | Screen filter and dark-theme switch checked in browser; image paths and theme counterparts verified |

These checks found and resolved the note-disclosure scroll-restoration collision, keyboard crowding on Phone, and truncated form helper text. Compiler warnings from existing Maps/Razorpay/Kotlin integrations remain in the native logs; the builds succeeded.

The baseline and updated main sets each contain 94 images. Supplements cover 12 lifecycle states, eight keyboard forms and two checkout variants in both themes. Large-text keyboard images use a simulated 300 dp keyboard inset. The full-screen captures omit the tab shell; bottom-navigation behavior is covered by the app tests rather than these isolated fixtures.

Native builds are development builds. The [iOS simulator screenshot](native-ios.png) shows the offline recovery screen: the development API at localhost is unavailable. It verifies that the bundle opens and renders with native safe areas, not that every native flow is verified. Real-device VoiceOver/TalkBack, provider SMS/Google login, Maps rendering and Razorpay checkout remain release checks. Telugu/Hindi translations and script-specific font selection remain separate work. Booking usability outcomes have not been measured in a user study.

## Review locally

From the repository root:

```sh
python3 -m http.server 8876 --bind 127.0.0.1 --directory docs/design
```

Open [the local gallery](http://127.0.0.1:8876/mobile-refresh/). It supports screen filtering, light/dark themes, full-resolution images and supplemental states. Rebuild it after capture changes with:

```sh
python3 docs/design/mobile-refresh/build_gallery.py
```

Tokens are maintained in `packages/design-tokens/customer.tokens.json`; regenerate Dart with `dart run tool/gen_tokens.dart` from `apps/customer`. Do not edit generated tokens as a second master. No backend, pricing rules or production configuration changed in this refresh.
