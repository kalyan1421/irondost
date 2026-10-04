# Lessons from this pass

- A passing widget test can miss a destructive control. Make the actual control visible, finish scroll/transition animations, tap the specific button and assert the resulting repository call or rejected state.
- Test the installed typefaces: Ahem layout passes do not prove real-font layout. Font metrics revealed date-strip and OTP constraints that needed natural height and flexible width.
- Wider gutters are a component change, not a token comment. Changing to 20 dp revealed an 8 px OTP overflow at 320 dp; flexible digit boxes fixed it.
- A customer returning from a completed order must not see “No orders yet” on the active tab. State copy must match the filtered data available.
- Shared flat components still need their former internal horizontal padding removed after a containing card disappears, or the content drifts off the screen grid.
- A callback on an InkWell is not enough to give native controls an obvious role. Inspect the native accessibility tree and add explicit button semantics to custom rows.
- Captured dates are fixtures. Overdue presentation needs a clock-aware boundary test, including the end of the IST delivery window.
- Finalize the existing brand assets before proposing a replacement. Removing repetitive illustration improved task clarity while preserving recognition.

- No-overflow tests are insufficient for visual reflow: a long address can wrap one word at a time, and an input focus border can be clipped by a fixed toolbar without raising a Flutter error. Inspect large-text captures and assert the affected geometry.
- Search has two distinct sources of emptiness: the catalogue and the query. Show loading/error/retry before interpreting query results, and preserve the query and basket during recovery.
- A paged campaign refreshed from admin must keep image, caption, page and link synchronized. Test replacing content while a later page is selected.
- Confirmed promotional copy is not proof of working checkout eligibility. Keep a free-item campaign inactive until server-side pricing and first-order rules can deliver its promise.
