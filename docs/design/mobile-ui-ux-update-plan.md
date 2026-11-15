# IronDost mobile UI/UX update plan

Prepared 1 November 2026. Status: local UI update implemented. See [the implementation report and review gallery](mobile-refresh/README.md) for changes, evidence and remaining device checks.

User decisions: clean and friendly, retain IronDost blue, compare two existing typography concepts on Home, Catalogue and Checkout. Compared heading adaptations of A (Charis) and F (Junction); selected F/Junction. The shared typography and controls now apply across the customer app, with targeted booking and keyboard improvements.

## Scope and interpretation

Update all mobile screen families in the Flutter customer app in `apps/customer` for iOS and Android. The user confirmed that “AI screen types” means **all mobile screens**. Cover primary journeys, secondary screens, sheets, system gates and their applicable loading, empty, error, offline and recovery states. Typography and visual consistency are part of this complete UI/UX update; AI-specific features are outside this scope.

The design skill recommendation below is a workflow aid, not an AI model ranking. No model comparison was performed and no model switch is proposed.

## Recommended design skill

**UI/UX Pro Max (`nextlevelbuilder/ui-ux-pro-max-skill`) is the best fit among the checked options for this Flutter project.** It includes Flutter-specific guidance and searchable typography, accessibility, interaction and design-system advice. Use it to support product-specific decisions rather than automatically replace the existing brand with a preset.

| Candidate | Evidence checked on 1 November 2026 | Fit |
|---|---|---|
| UI/UX Pro Max | Skills directory reports 427.4K installs; source repository shows approximately 143.5K stars. Community-maintained, not an official Flutter skill. | Recommended for the Flutter redesign workflow. |
| design-mobile-apps, designed-by-ai/skills | Directory reports 1.2M installs; GitHub shows 21 stars. The skill primarily operates the Sleek design API and requires its service authentication. | Useful for external screen generation; weaker fit for directly refining the existing Flutter app. |

Sources: [UI/UX Pro Max directory](https://www.skills.sh/nextlevelbuilder/ui-ux-pro-max-skill/ui-ux-pro-max), [source repository](https://github.com/nextlevelbuilder/ui-ux-pro-max-skill), [Sleek mobile skill directory](https://www.skills.sh/designed-by-ai/skills/design-mobile-apps), [source repository](https://github.com/designed-by-ai/skills). Popularity is a selection signal, not proof of design quality. Counts are snapshots.

Optional installation command for the implementation stage:

```sh
npx skills add nextlevelbuilder/ui-ux-pro-max-skill --skill ui-ux-pro-max
```

UI/UX Pro Max was read before implementation and is now installed globally for Codex at `/Users/kalyan/.codex/skills/ui-ux-pro-max`, as requested. Its project-local copy and lock entry were removed.

## Evidence and existing work

- The app already has a token-based system, bundled Outfit/Figtree/Geist Mono fonts, reusable controls, and documented light/dark coverage.
- `docs/ui-ux-audit/IMPLEMENTATION.md` records 47 representative views and earlier verification. Those results are historical, not fresh test results for the current working tree.
- Visually inspected archived fixture captures: Home, Choose items and Checkout in `docs/ui-ux-audit/after/`. These are examples of layout, not current offers, live pricing or complete native navigation.
- Inspected current Home and Checkout source, shared typography mapping, route inventory and capture-tool instructions.
- Existing critique: `docs/design/customer-app-critique.md`. Ten typography explorations already exist in `docs/design/round-1/`; no selected winner was established by this review. Their evidence capsule defines a separate original-design exercise; preserve those artifacts and their source boundaries.
- Current checkout source enforces a verified phone through `_hasPhone` before placing an order, but its review rows show address and times without an explicit contact-number summary. The quote bill follows payment selection. Quantity steppers already exist, so improving them does not require rebuilding that interaction.
- Existing uncommitted OTP, release and design work must be preserved during implementation.

## Product and visual direction

Make booking feel clear, local and dependable: the customer should quickly understand what will be collected, when it returns and what payment means. Keep the recognizable IronDost logo. Use garment care, item counts and pickup windows to give the UI character.

Use a restrained neutral background, intentional brand accents, aligned content edges and clear differences between headings, instructions, prices and metadata. Reduce repeated outlined boxes and competing blue edit links where they weaken hierarchy. Decorative images should help identify services and remain consistent in style and scale.

Begin by comparing two of the existing typography directions in actual Flutter Home, Catalogue and Checkout layouts. Retain the current fonts as the baseline. Choose on reading speed, brand character, ₹/numeral quality, text scaling and feasible Telugu/Hindi fallback coverage. Do not select a face from a welcome-page specimen alone. Translation rollout is a separate scope; check script feasibility before committing to new typography.

## Ordered implementation

| Phase | Work | Reviewable result / completion condition |
|---|---|---|
| 1. Current baseline | Capture the current branch into a new dated folder; map routes, sheets and edge states against the existing 47-view inventory. Inspect real navigation and safe areas on both platforms. | Screen/state checklist with reproducible issues, evidence paths and severity. No claim that archived fixtures equal today's build. |
| 2. Booking clarity | Add a visible verified contact row with an Add number action when missing; return to the same checkout after verification. Move a clear quote summary before payment choice. Reassess edit-row emphasis and pickup/delivery selection consistency. | Complete first-order and repeat-order walkthroughs; phone cancellation retains the basket; missing/stale quotes cannot trigger an order. |
| 3. Shared visual system | Compare type directions on three real screens; select hierarchy, spacing, colour roles, service-art treatment and control states. Update the token master and regenerate Dart tokens. | Light/dark Home, Catalogue and Checkout previews at normal and large text, plus updated system notes. |
| 4. Main journeys | Apply the selected system to auth, address selection, catalogue/search, basket, scheduling, checkout and payment recovery. Keep each screen's primary task explicit. | Working booking flow with clear count, estimate, pickup/delivery windows and recovery at every step. |
| 5. Retention and secondary screens | Update order lists/tracking, receipts, offers, inbox, account, support and policies. Use contextual actions and consistent status language. | Every inventory family reviewed; destructive actions retain explicit consequences and recovery states. |
| 6. Verification and handoff | Run relevant analysis/tests, capture all representative views, stress text/keyboard layouts, then inspect native iOS and Android flows. | Before/after gallery, current verification results, remaining device/provider limitations and a final issue list. |

Phase 2 should start with existing visual tokens so functional clarity can be verified independently of typography selection. Phase 4 follows the shared system decision. No calendar estimate is assigned until the fresh baseline establishes the issue count.

## Screen families and proposed changes

| Family | UI/UX update | States to verify |
|---|---|---|
| Launch, welcome, phone, OTP, profile setup | Clear first action, consistent type, keyboard-aware forms; integrate existing OTP work. | Invalid code, resend wait, loading, Google entry, add-phone return and interrupted sign-in. |
| Home | Prioritize address, active order and booking; use consistent service visuals; keep promotions subordinate to the task. | New/repeat customer, no address, out of area, active order, absent/expired promotion. |
| Address search, map, details, saved addresses | Explain serviceability and next action; keep manual entry available where supported. | Permission denied, map unavailable, search no result, outside area, add/edit/save failure. |
| Catalogue and search | Align item names, units and prices; retain Add-to-stepper interaction and visible basket summary. Move a unit label to a section only when every item shares that unit. | Loading, empty catalogue, query with no match, offline retry, long names and quantity changes. |
| Basket | Distinguish the estimate, fees, discounts and final pickup count; keep editing easy. | Empty basket, invalid coupon, changed prices/items, pending quote and retry. |
| Pickup and delivery | Use consistent selection affordances and make delivery choice obvious. Show only server-supported windows. | No slots, unavailable selection, date change, loading and revalidation failure. |
| Checkout | Contact, address, windows and total should be easy to review before committing. Show cash/online consequences plainly. | Missing phone, phone already in use, verification cancelled, invalid quote, out-of-area address and placing state. |
| Payment, confirmation, receipt | Distinguish unpaid, failed, still confirming and paid. Make the next safe action clear. | SDK cancel/failure, timeout, webhook delay, retry, COD switch where allowed and later balance due. |
| Orders and tracking | Lead with current status, promised window and available action; distinguish delays from completed/cancelled states. | Active/past empty lists, pagination, overdue order, partner unavailable, cancellation boundary and realtime reconnect. |
| Offers and notifications | Scannable rows, explicit eligibility/expiry and meaningful destinations. | None available, expired offer, ineligible coupon, loading and offline failure. |
| Account, help, legal, sheets and system gates | Consistent forms/rows, readable long text and clear consequences. | Save failure, blocked deletion with active orders, logout, permission prompt, maintenance, update and unavailable service. |

For each family, record applicable loading, content, empty, error/retry, offline and submission states. These are states of a screen, not automatically new routes. Keep state recovery local and retain user input.

## Implementation map

- Token source: `packages/design-tokens/customer.tokens.json`; generator: `apps/customer/tool/gen_tokens.dart`. Do not hand-edit the generated Dart file as the master.
- Theme/type mapping: `apps/customer/lib/design/theme.dart`.
- Shared controls: `apps/customer/lib/design/widgets/`, particularly `review_row.dart`, `choice_card.dart`, `slot_picker.dart`, `item_stepper.dart`, `cart_bar.dart` and `state_view.dart`.
- Booking and checkout: `apps/customer/lib/features/{catalogue,basket,schedule,checkout,payment}/`.
- Inventory: `apps/customer/lib/app/routes.dart` and `docs/ui-ux-audit/IMPLEMENTATION.md`.

Keep server-owned prices, slot rules, serviceability, payment confirmation and order idempotency intact. Display confirmed facts; never invent delivery guarantees or discounts for visual completeness.

## Acceptance and validation

1. One clear primary action per task screen; key review information remains discoverable before commitment. The keyboard and footer never obscure the active input or required action.
2. At 320, 390 and 430 dp, normal and 200% text remain usable. Essential amounts, dates and labels wrap or reflow without clipping. Check long addresses and service names.
3. All touch targets meet the existing 48 × 48 dp minimum. Normal text meets 4.5:1 contrast and meaningful control boundaries meet 3:1. Selection and status have cues beyond colour.
4. Light/dark mode, screen reader labels, focus order, reduced-motion behavior for added animation and native back navigation are checked.
5. Run `flutter analyze` and `flutter test` from `apps/customer` after implementation. Add focused regression coverage for changed checkout/contact and recovery behavior; avoid tests that only duplicate styling code.
6. Use `tool/audit/capture.sh` with a new output directory for the base captures, extra lifecycle states and keyboard variants. Run stress captures at the three widths. See `apps/customer/tool/audit/README.md` for flags. Keep historical evidence intact.
7. Verify real OS keyboards, TalkBack/VoiceOver, native Maps, sign-in and payment SDK paths on test devices/environments. Fixture captures do not prove those integrations work.
8. Compare task completion for booking, editing a delivery window and recovering a failed payment. Record hesitations/errors in a small usability review before claiming an improvement; define numerical targets after baseline observation.

The first implementation deliverable should be the refreshed baseline plus the checkout contact/price review improvement. A full visual rollout follows the three-screen typography/system comparison.
