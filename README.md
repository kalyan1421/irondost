# IronDost platform

IronDost is a doorstep ironing and laundry service: customers book a pickup, a delivery partner collects the clothes, the workshop processes them, and a partner delivers them back.

This repository replaces the Firebase-based "Cloud Ironing Factory" apps with a new stack. The brand name and order prefix are configured in the API with `APP_NAME=IronDost` and `ORDER_NUMBER_PREFIX=ID`.

| Part | Stack | Status |
|---|---|---|
| `apps/api` | NestJS 12, Prisma 7, PostgreSQL | Built and tested |
| `apps/admin` | Next.js 16 | Built: all screens, image uploads (see `apps/admin/README.md`) |
| `apps/web` (marketing site) | Next.js | Not started |
| `mobile/customer`, `mobile/partner` | Flutter | Not started |
| `packages/contracts` | OpenAPI document exported from the API | Generated |

## Architecture

- **One API, one database.** All business rules run on the server: pricing, order numbers, slot rules, the order status flow, driver dispatch and payments. Apps never write to the database directly.
- **Firebase is kept for two things only:** phone-OTP sign-in and push delivery (FCM, which also reaches iPhones through APNs). The API verifies Firebase ID tokens. There is no Firestore, Cloud Functions or Firebase Storage.
- **Background jobs** use [pg-boss](https://github.com/timgit/pg-boss), which stores jobs in the same PostgreSQL database, so there is no Redis to run.
- **Realtime** uses Socket.IO at `/v1/realtime`. The API also sends FCM pushes for when the app is in the background.
- **Payments:** Razorpay (server-created orders, signature-verified callback plus webhook) and cash on delivery.
- **Images:** admins upload images for the catalogue, promotions and banners. The upload endpoint (`POST /v1/admin/uploads/images`) does the following:
  - checks the file really is an image
  - removes camera metadata, including GPS location
  - resizes the image for its use and stores it as WebP
  - saves it to S3 in production, or to a local `uploads/` folder in development

### Order flow

```
PENDING → PICKUP_ASSIGNED → PICKED_UP → PROCESSING → READY_FOR_DELIVERY
        → DELIVERY_ASSIGNED → OUT_FOR_DELIVERY → DELIVERED
```

Any open order can be `CANCELLED` by an admin. Customers can cancel until pickup. The full table of allowed moves, and who may make them, is in `apps/api/src/orders/order-state.ts`.

### Dispatch

Each leg (pickup or delivery) is offered to the nearest available partners at the same time. That is 3 partners by default, and a partner counts as available when they are online, sent a location in the last 15 minutes and have spare capacity.

- **Winning an offer.** The first partner to accept gets the leg; the database settles any race.
- **Declines and timeouts.** If everyone declines, or the 20-second timeout passes, the next round starts with other partners.
- **Nobody available.** The order is flagged for admins, who get a push, and dispatch retries every 5 minutes until the slot ends. Admins can assign or reassign at any time.
- **Timing.** Dispatch starts 60 minutes before the pickup slot.

Every one of these numbers is a row in `business_settings` that admins can edit.

## Getting started

Requirements: pnpm 10 and PostgreSQL 14 or newer. pnpm downloads the pinned Node 24 for this repo automatically (`useNodeVersion`).

```bash
pnpm install
cp apps/api/.env.example apps/api/.env   # then edit DATABASE_URL
docker compose up -d postgres             # or use a local PostgreSQL
pnpm --filter @laundry/api db:deploy      # apply migrations
pnpm --filter @laundry/api db:seed        # first super admin + sample catalogue
pnpm --filter @laundry/api dev            # http://localhost:4000
```

API docs are served at <http://localhost:4000/docs>; they are not exposed in production.

### Signing in during development

With `AUTH_DEV_BYPASS=true` (refused when `NODE_ENV=production`), any `dev:<phone>` string is accepted as a token:

```bash
curl -X POST localhost:4000/v1/auth/session \
  -H 'Authorization: Bearer dev:9000000000' -H 'content-type: application/json' \
  -d '{"app":"ADMIN"}'
```

Every app calls `POST /v1/auth/session` right after OTP sign-in, with `app` set to `CUSTOMER`, `PARTNER` or `ADMIN`:

- **Customers** are created on their first sign-in.
- **Partners and admins** must first be added by an admin, matched by phone number.

## Tests

```bash
pnpm --filter @laundry/api test       # unit tests: pricing, slots, order flow, signatures
pnpm --filter @laundry/api test:e2e   # full HTTP flows against a throwaway database
```

The e2e suite creates its own database (`laundry_e2e_<pid>_<time>`), runs the migrations, and drops it when done. Point `TEST_DATABASE_SERVER_URL` at the server if it isn't local.

## API contract

`pnpm --filter @laundry/api openapi` writes `packages/contracts/openapi.json`. Generate clients from it:

- **Next.js admin:** `openapi-typescript`
- **Flutter apps:** `openapi-generator` with the `dart-dio` generator

## Deployment notes

- `apps/api/Dockerfile` builds a production image. Build it from the repo root. It runs `prisma migrate deploy` on start. The Dockerfile has not been built yet.
- **Production environment.** Set `FIREBASE_SERVICE_ACCOUNT_BASE64`, the three `RAZORPAY_*` values and `CORS_ORIGINS`. Leave `AUTH_DEV_BYPASS` unset.
- **Image storage.** Production needs `STORAGE_DRIVER=s3`, `S3_BUCKET` and `STORAGE_PUBLIC_BASE_URL` (the CloudFront or bucket URL); the API refuses local storage in production. The S3 driver has not yet been run against a real bucket.
- **Razorpay webhook:** point it at `POST /v1/webhooks/razorpay`, with the events `payment.captured` and `payment.failed`.
- **Hosting.** Suggested: AWS Mumbai (ap-south-1), with App Runner or ECS for the API and RDS PostgreSQL.
