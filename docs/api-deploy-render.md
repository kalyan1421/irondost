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
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Razorpay dashboard. Use test-mode keys while testing and live keys at launch. |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API Keys → the secret key (`service_role`). Server-side only. |
| `CORS_ORIGINS` | Comma-separated browser origins: the admin site and `https://irondost-app.web.app` |

## Storage on Supabase

The server, the database and the background jobs all run on Render. Only uploaded images live elsewhere, in a **public** bucket named
`irondost-uploads` in the IronDost Supabase project (`gsqcgqgsatppgccuiqbb`, `ap-southeast-1`). The API's Supabase driver uploads
with the project's secret key through Supabase's storage API (no AWS or S3 involved) and serves files from
`https://gsqcgqgsatppgccuiqbb.supabase.co/storage/v1/object/public/irondost-uploads/…`. The project URL and bucket are set in
`render.yaml`; only the secret key is entered in Render. To use a different project or bucket, change `SUPABASE_URL` and
`SUPABASE_STORAGE_BUCKET` there.

## The Razorpay webhook is optional for testing

The app confirms a payment itself: after checkout it calls the API, which verifies Razorpay's signature with the key secret.
That path needs only `RAZORPAY_KEY_ID` and `RAZORPAY_KEY_SECRET`. The webhook (`POST /v1/webhooks/razorpay`) is a safety net for
customers who close the app mid-payment, and the only source of refund-status and payment-failed updates. Without it, those
refund updates do not arrive. Cash orders do not use Razorpay at all.

Render generates `RAZORPAY_WEBHOOK_SECRET` for you. Add the webhook in the Razorpay dashboard when you want it, using
`https://<api-url>/v1/webhooks/razorpay`, the events `payment.captured`, `payment.failed` and `refund.*`, and the value from the
service's Environment tab as the secret.

## Deploying

1. Push `render.yaml` to `main` on GitHub (`kalyan1421/irondost`) and give Render access to the repo.
2. Render dashboard → Blueprints → New Blueprint Instance → pick the repo, enter the values above, apply.
3. The container applies pending migrations (`prisma migrate deploy`) and then starts. Check `https://<api-url>/v1/health`.
4. Seed the first super admin once, from a machine with the production `DATABASE_URL` (external connection string, allow your IP first):
   `SEED_SUPER_ADMIN_PHONE=+91… pnpm --filter @laundry/api db:seed`.
5. Put the service URL in `apps/customer/env/prod.json` as `API_BASE_URL`, and rebuild the app with
   `--dart-define-from-file=env/prod.json` (see [`customer-app-release.md`](customer-app-release.md), section 4).

`autoDeploy` is off, so a push does not redeploy. Use the dashboard's Manual Deploy or `render deploys create <service-id>`.
