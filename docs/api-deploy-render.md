# Deploying the API on Render

The API is one Docker image (`apps/api/Dockerfile`). It needs PostgreSQL, and background jobs (pg-boss) run inside the API process and
keep their state in that same database, so nothing else needs deploying. [`render.yaml`](../render.yaml) at the repo root describes the
two Render services: the API and the admin console. Workspace: akvega's workspace, region Singapore (nearest to Hyderabad).

## Where things live

| Part | Where | Notes |
|---|---|---|
| API (Docker web service `irondost-api`) | Render, `free` plan | Sleeps after 15 minutes idle and takes about a minute to wake, so order jobs and push notifications stall while asleep. |
| Admin console (Node web service `irondost-admin`) | Render, `free` plan | Next.js, built on Render. Sleeps when idle like the API. |
| PostgreSQL | Supabase project `gsqcgqgsatppgccuiqbb` (`ap-southeast-1`) | Reached through the session pooler. A free Supabase project pauses after a week without activity. |
| Uploaded images | Same Supabase project, public bucket `irondost-uploads` | See "Storage on Supabase" below. |

The free plans are for testing. Before real customers, change the Render `plan` to `starter` (Render refuses paid plans until the
workspace has a payment method; `render blueprints validate render.yaml` reports `need_payment_info`) and move the Supabase project to a
paid plan so it does not pause.

## Settings Render asks for

These are `sync: false` in the Blueprint, so Render prompts for them when it is applied. Do not commit them.

| Variable | Where it comes from |
|---|---|
| `FIREBASE_SERVICE_ACCOUNT_BASE64` | Firebase console → `irondost-app` → Project settings → Service accounts → new private key, then `base64 -i key.json` |
| `RAZORPAY_KEY_ID`, `RAZORPAY_KEY_SECRET` | Razorpay dashboard. Use test-mode keys while testing and live keys at launch. |
| `DATABASE_URL` | Supabase → Connect → **Session pooler** string, with the database password filled in (`postgresql://postgres.<ref>:<password>@aws-0-ap-southeast-1.pooler.supabase.com:5432/postgres`). Not the transaction pooler (port 6543), which Prisma migrations cannot use. |
| `SUPABASE_SERVICE_ROLE_KEY` | Supabase → Project Settings → API Keys → the secret key (`service_role`). Server-side only. |
| `CORS_ORIGINS` | Comma-separated browser origins: the admin site and `https://irondost-app.web.app` |

## Storage on Supabase

Uploaded images go to a **public** bucket named `irondost-uploads` in the same Supabase project. The API's Supabase driver uploads
with the project's secret key through Supabase's storage API (no AWS or S3 involved) and serves files from
`https://gsqcgqgsatppgccuiqbb.supabase.co/storage/v1/object/public/irondost-uploads/…`. The project URL and bucket are set in
`render.yaml`; only the secret key is entered in Render. To use a different project or bucket, change `SUPABASE_URL` and
`SUPABASE_STORAGE_BUCKET` there.

## Admin console

`irondost-admin` builds the Next.js app (`apps/admin`) on Render and serves it with `next start`, so the `/orders/[id]` and
`/customers/[id]` pages work without changes. Its settings are all in `render.yaml`: the API address and the Firebase **web** app
config (`IronDost Admin`, created in the `irondost-app` Firebase project). Those values are compiled into the browser bundle, so
they are public by design; restrict the web API key to the admin's address in Google Cloud → Credentials if you want a second layer.

Two things outside the repo make sign-in work:

- The admin's address (`irondost-admin.onrender.com`) must be in Firebase → Authentication → Settings → Authorized domains.
- The same address is in the API's `CORS_ORIGINS` (set in `render.yaml`).

The first super admin signs in with the number given to the seed, and then adds everyone else under Staff. That number must not
be a Firebase "phone number for testing", because those have a fixed, known code.

## Database connections

The session pooler on Supabase's free tier allows about 15 connections. Prisma and pg-boss each keep a pool, so `render.yaml` sets
`DATABASE_POOL_MAX=5` (2 × 5 = 10) and leaves room for the migration step that runs when the container starts. Raise it only if you
also raise the pooler size (Supabase → Database → Connection pooling).

Tables Prisma creates in the `public` schema are reachable through Supabase's own REST API with the project's public key unless that
API is switched off or row level security is on. The apps never use it, so turn the Data API off (Supabase → Project Settings →
Data API) or enable row level security on every table. The API itself connects as the `postgres` role, which row level security does
not restrict.

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
4. Seed the first super admin once, from your own machine with the same `DATABASE_URL` (the session pooler string):
   `SEED_SUPER_ADMIN_PHONE=+91… pnpm --filter @laundry/api db:seed`.
5. Put the service URL in `apps/customer/env/prod.json` as `API_BASE_URL`, and rebuild the app with
   `--dart-define-from-file=env/prod.json` (see [`customer-app-release.md`](customer-app-release.md), section 4).

`autoDeploy` is off, so a push does not redeploy. Use the dashboard's Manual Deploy or `render deploys create <service-id>`.
