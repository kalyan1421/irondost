# Decisions and what changed (7 Nov 2026)

## Done today

**Next.js upgraded from 16.3.8 to 16.4.5** in `apps/admin` and `apps/web` (`next` and `eslint-config-next`, both pinned exact like before). Why 16.4.5: the advisories are patched in 16.4.1, and 16.4.5 is the latest stable patch.

| Check | Result |
|---|---|
| `pnpm install` | Succeeded. The lockfile changed only the `next` family (112 lines, all 16.3.8 to 16.4.5). |
| Admin: typecheck, lint, build | All pass; build generated 18 pages. |
| Website: typecheck, lint, build | All pass; build generated 14 pages. |
| `pnpm audit --prod` | **Critical 2 to 0.** High 17 to 16. No advisory names Next.js any more. Now 35 findings: 4 low, 15 moderate, 16 high. |
| Files changed | `apps/admin/package.json`, `apps/web/package.json`, `pnpm-lock.yaml`. Nothing else. Not committed. |
| Bundled-docs check (admin `AGENTS.md`) | Read the 16.4 notes: only new optional features (`prefetch`, `ensureStatic`) and ESLint 10 support. ESLint 9 stays supported. |

Not done: a browser run of the admin against the new version (build and typecheck passed; the pages themselves were not clicked through), and the 16 remaining high findings, which are in other packages (plan in [backend-plan.md](backend-plan.md), item B7).

## Your answers

| Question | Your answer | Effect |
|---|---|---|
| Which slice first? | **Trust core**: problem reports with a response clock, and customer approval of price changes | Backend, customer app and admin work in [backend-plan.md](backend-plan.md) and [build-plan.md](build-plan.md). No rider app needed for it. |
| How should riders get a phone interface? | **Flutter partner app** (my recommendation was a mobile web page in the admin) | A new Flutter app, sized **L**, scheduled after the Trust core. Its API already exists, so the cost is client work, store setup and field testing. See [build-plan.md](build-plan.md) part C. |
| Wallet and referral rewards in the first build? | **Leave out for now** | The wallet tables stay in [schema.sql](../schema.sql) for review but are not in the first migration ([schema.trust-core.sql](../schema.trust-core.sql)). Nothing is built until an accountant decides the rules. |
| What should the review research do next? | **Balance the sample** | [entrepreneur-plan.md](entrepreneur-plan.md): an unbiased newest-reviews sample for the three Hyderabad apps, so complaint shares stop being skewed to low stars. |

## Things the plans now assume (change any of them)

- **Response clock 4 hours, approval window 12 hours.** Placeholders in the schema; you set the real numbers in the admin. They are promises customers will see, so choose ones operations can keep.
- **A price increase needs the customer's approval; a decrease applies at once** with a notice.
- **If the customer does not answer, the original total stands** and staff are alerted. If the customer declines, staff decide whether to proceed at the original count or cancel the pickup.
- **Partner app starts Android-only**, since riders' phones are most often Android. Open question for you.
- **The partner app lives in `apps/partner`** (next to `apps/customer`, inside the workspace). The README says `mobile/partner`; one of them should be updated.
