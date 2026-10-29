# Deploying the API on Render

The API is one Docker image (`apps/api/Dockerfile`). It needs PostgreSQL, and background jobs (pg-boss) run inside the API process and
keep their state in that same database, so nothing else needs deploying. [`render.yaml`](../render.yaml) at the repo root describes the
two Render services: the API and the admin console. Workspace: Iron dost's workspace (moved from akvega's workspace in October 2026),
region Singapore (nearest to Hyderabad).

The services live at `https://irondost-api-8nwz.onrender.com` and `https://irondost-admin-sayn.onrender.com`. Render kept the old
`irondost-api` / `irondost-admin` names reserved after the previous workspace's services were deleted, so the new ones got a suffix.
The suffix is fixed when a service is created; renaming a service does not change its address.

## Where things live

| Part | Where | Notes |
|---|---|---|
| API (Docker web service `irondost-api`) | Render, `free` plan | Sleeps after 15 minutes idle and takes about a minute to wake, so order jobs and push notifications stall while asleep. The keep-alive job (below) stops that. |
| Admin console (Node web service `irondost-admin`) | Render, `free` plan | Next.js, built on Render. Sleeps when idle like the API, and is left to sleep on purpose (see the keep-alive section). |
| PostgreSQL | Supabase project `gsqcgqgsatppgccuiqbb` (`ap-southeast-1`) | Reached through the session pooler. A free Supabase project pauses after a week without activity. |
| Uploaded images | Same Supabase project, public bucket `irondost-uploads` | See "Storage on Supabase" below. |

The free plans are for testing. Before real customers, change the Render `plan` to `starter` (Render refuses paid plans until the
workspace has a payment method; `render blueprints validate render.yaml` reports `need_payment_info`) and move the Supabase project to a
paid plan so it does not pause.

## Keeping the free plans awake

The API runs a keep-alive job (`apps/api/src/keep-alive`). With `KEEP_ALIVE_INTERVAL_MINUTES=10` (set in `render.yaml`) it does two
things on start and then every 10 minutes:

- **Database update.** It rewrites one row in `service_heartbeats` (the service name, a beat counter and the time), so Supabase sees
  real writes and the project is never idle long enough to pause.
- **Traffic.** It requests its own public address (`RENDER_EXTERNAL_URL/v1/health`, which Render fills in) and each address in
  `KEEP_ALIVE_URLS`, so Render sees inbound traffic and never spins the service down.

A failed beat is logged as a warning (`Keep-alive …`) and never affects the API. The `service_heartbeats` table comes from a migration
that runs when the container starts. Until then the job logs a database warning and still sends the requests.

**The admin is left asleep on purpose.** Free Render gives the whole workspace 750 instance hours a month, and a service that never
sleeps uses about 744. The API alone fits; the API plus the admin is about 1,490 hours, and Render then suspends every free service
until the first of the next month. To keep the admin awake too, move both services to `starter` first, then set
`KEEP_ALIVE_URLS=https://irondost-admin-sayn.onrender.com/login` on the API.

Limits: the job only runs while the API is up. If Render restarts it, the job starts again by itself, but nothing wakes a service
that was already asleep before this change was deployed (open the API address once). Render also does not promise that a service
pinging itself is "traffic"; if the API still sleeps, schedule an outside caller (UptimeRobot or a GitHub Actions cron) for
`/v1/health` every 10 minutes, or move to `starter`.

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

- The admin's address (`irondost-admin-sayn.onrender.com`) must be in Firebase → Authentication → Settings → Authorized domains.
- The same address is in the API's `CORS_ORIGINS` (set in `render.yaml`).

The first super admin signs in with the number given to the seed, and then adds everyone else under Staff. That number must not
be a Firebase "phone number for testing", because those have a fixed, known code.

**Email + password sign-in.** The admin's sign-in page also takes an email and password (it is the default tab; "Use a mobile number
instead" switches to the phone code). The API checks the password against a scrypt hash in `users.password_hash`, then returns a
Firebase custom token (`POST /v1/auth/admin-login`), so the session after that is an ordinary Firebase one. Only admins and super
admins can use it, five tries a minute per address, and an account locks for 15 minutes after eight wrong passwords. Create such an
admin, or reset its password, from your own machine with the session pooler string:
`DATABASE_URL='postgresql://…' ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='…' pnpm --filter @laundry/api db:admin`. The account has
no phone, so Staff lists it as `email:<address>`. There is no "forgot password" flow on purpose: the email is only a username, so
nobody who owns that mailbox can reset it; re-run the command to change the password. Use a real address you control and a long
password, because this sign-in is reachable from the internet.

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
   `SEED_SUPER_ADMIN_PHONE=+91… pnpm --filter @laundry/api db:seed`. For an email + password admin instead, run `db:admin` (see
   "Email + password sign-in" above).
5. Load the service catalogue (categories and items) from your local database into the live one. From `apps/api`, with the
   session pooler string as the target; the first run is a dry run that prints what it would add and writes nothing:
   `TARGET_DATABASE_URL='postgresql://…' scripts/push-catalogue.sh`, then the same with `--apply`. It only adds what is missing
   (add `--overwrite` to also replace prices of items that already exist) and never deletes. Check the result at
   `https://<api-url>/v1/catalog`.
6. Put the service URL in `apps/customer/env/prod.json` as `API_BASE_URL`, and rebuild the app with
   `--dart-define-from-file=env/prod.json` (see [`customer-app-release.md`](customer-app-release.md), section 4).

`autoDeploy` is off, so a push does not redeploy. Use the dashboard's Manual Deploy or `render deploys create <service-id>`.
