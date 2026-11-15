# Build log

replica-build output. Date 2026-11-07.

**No screens or features were built in this pass, and no application code was changed.** This was a competitor study and a plan. The only files created are inside `replica/`.

| Item | Status | Notes |
|---|---|---|
| Shell, tokens and primitives | Already exist in the Flutter app | The shipped design system is the source of truth ([design/irondost.light.tokens.json](design/irondost.light.tokens.json) records it for the contrast tool) |
| Vertical slice | Not started | Proposed: the trust core (problem reports and price-change approval), architecture step 2 |
| Screens | 0 new | New screens listed in [architecture.md](architecture.md): Report a problem, Issue detail, Approve new total, Reschedule, Wallet |
| Schema | Draft only | [schema.sql](schema.sql), tested on a throwaway database, not applied |
| Feature matrix `clone` column | Filled from code reading | See [parity.md](parity.md) for how that was done |

Rules for when building starts (from the pack): every label, button and empty state written fresh; no competitor markup, assets, copy or colours; tokens only, no raw hex in components; every state (empty, loading, error, long text, 200% text) for each new screen; one commit per screen; a failing test first for each fix.

Next: `/replica-build`, starting at step 2 of the build order.
