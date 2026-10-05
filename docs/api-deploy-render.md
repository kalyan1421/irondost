# Deploying the API on Render

The API is one Docker image (`apps/api/Dockerfile`) plus Postgres. Background jobs (pg-boss) run inside the API process and store
their state in the same database, so nothing else needs deploying. [`render.yaml`](../render.yaml) at the repo root describes both
pieces for Render Blueprints. Workspace: akvega's workspace, region Singapore (nearest to Hyderabad).

## What the Blueprint creates

| Resource | Plan | Notes |
|---|---|---|
| `irondost-db` (Postgres) | `free` | Internal connections only. Render deletes a free database 30 days after creation (after a 14-day grace period). |
| `irondost-api` (Docker web service) | `free` | Sleeps after 15 minutes idle and takes about a minute to wake, so order jobs and push notifications stall while asleep. |

Free plans are for testing only. Before real customers, change `plan` to `basic-256mb` (database) and `starter` (service). Render
refuses paid plans until the workspace has a payment method (`render blueprints validate render.yaml` reports `need_payment_info`),
so add one under Workspace → Billing first. A free database can be upgraded in place from its settings page.

## Settings Render asks for

These are `sync: false` in the Blueprint, so Render prompts for them when it is applied. Do not commit them.

| Variable | Where it comes from |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Firebase console → `irondost-app` → Project settings → Service accounts → new private key, then `base64 -i key.json` |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Razorpay dashboard, live mode |
| `RAZORPAY_WEBHOOK_SECRET` | Chosen when adding the webhook (`https://<api-url>/v1/webhooks/razorpay`) in the Razorpay dashboard |
| `S3_BUCKET`, `STORAGE_PUBLIC_BASE_URL` | An S3 bucket in `ap-south-1` and its public or CloudFront URL. Production refuses `STORAGE_DRIVER=local`. |
| `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY` | An IAM user limited to that bucket |
| `CORS_ORIGINS` | Comma-separated browser origins: the admin site and `https://irondost-app.web.app` |

## Deploying

1. Push `render.yaml` to `main` on GitHub (`kalyan1421/irondost`) and give Render access to the repo.
2. Render dashboard → Blueprints → New Blueprint Instance → pick the repo, enter the values above, apply.
3. The container applies pending migrations (`prisma migrate deploy`) and then starts. Check `https://<api-url>/v1/health`.
4. Seed the first super admin once, from a machine with the production `DATABASE_URL` (external connection string, allow your IP first):
   `SEED_SUPER_ADMIN_PHONE=+91… pnpm --filter @laundry/api db:seed`.
5. Put the service URL in `apps/customer/env/prod.json` as `API_BASE_URL`, and rebuild the app with
   `--dart-define-from-file=env/prod.json` (see [`customer-app-release.md`](customer-app-release.md), section 4).

`autoDeploy` is off, so a push does not redeploy. Use the dashboard's Manual Deploy or `render deploys create <service-id>`.
