# CI/CD

One workflow, `.github/workflows/ci.yml`.

| When | What runs |
| --- | --- |
| Pull request | Checks only: API (typecheck, lint, unit, e2e, OpenAPI contract), admin, website, customer app |
| Push to `main` | The same checks, then a deploy for each app whose files changed, after that app's checks pass |
| Actions → CI → Run workflow (on `main`) | Checks, then deploys the website and the API |

| App | Deploys to | Job |
| --- | --- | --- |
| Website `apps/web` | Firebase Hosting, project `irondost-app` (irondost-app.web.app, irondost.in, irondost.com, irondost.shop) | `deploy-web` |
| Admin `apps/admin` | Vercel project `irondost-admin` (admin.irondost.in), through Vercel's GitHub link: production from `main`, a preview per pull request. Root directory `apps/admin`, install `pnpm install --frozen-lockfile --filter @laundry/admin...`, Node 24 | Vercel, not this workflow |
| API `apps/api` | Render service `irondost-api`, through its deploy hook | `deploy-api` |

Deploy jobs use the GitHub environment `production`. To approve each deploy by hand, open Settings → Environments → production and add yourself under "Required reviewers".

## Secrets (GitHub → Settings → Secrets and variables → Actions)

| Secret | Where it comes from |
| --- | --- |
| `FIREBASE_SERVICE_ACCOUNT_IRONDOST_APP` | Run `firebase init hosting:github` in `apps/web` once. It creates the service account and stores this secret for you. Answer "no" when it offers to write workflow files, because they already exist. Or: Google Cloud console → IAM → Service accounts → create one with "Firebase Hosting Admin" and "API Keys Viewer", make a JSON key, and paste the whole JSON |
| `RENDER_DEPLOY_HOOK_API` | Render → irondost-api → Settings → Deploy Hook. Copy the URL and treat it as a secret |

The admin's `NEXT_PUBLIC_*` values live in Vercel's Production environment; Vercel's own build reads them. The website needs no secrets beyond the Firebase key: it has no environment variables except `NEXT_PUBLIC_SITE_URL`, which the workflow sets.

## Careful with the API

The API applies database migrations when its container starts. A merge to `main` that adds a migration changes the production database as soon as `deploy-api` runs. Before merging, read the migration and follow `docs/ui-ux-audit/review-2026-11-14/RELEASE-CHECKLIST.md`. Render's own auto-deploy should stay off (`autoDeploy: false` in `render.yaml`), so this workflow is the only path to production.
