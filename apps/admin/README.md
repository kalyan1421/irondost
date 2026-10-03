# IronDost Admin

Operations console for the IronDost team: orders, customers, delivery partners, prices, promotions and settings. It is a client-rendered Next.js 16 app (App Router) that talks only to the IronDost API.

## Run it locally

The API must be running (see the repo README) with `AUTH_DEV_BYPASS=true`.

```bash
cp .env.example .env.local      # set NEXT_PUBLIC_AUTH_DEV_BYPASS=true for local sign-in without SMS
pnpm --filter @laundry/admin dev  # http://localhost:3000
```

Sign in with the super admin number from the API seed (`SEED_SUPER_ADMIN_PHONE`, default 9000000000). To fill the screens with sample partners, customers and orders, run `pnpm --filter @laundry/api demo` once against a local API.

## How it is built

| Concern | Choice |
|---|---|
| Sign-in | Firebase phone OTP (web SDK, invisible reCAPTCHA). The ID token is sent to the API, which checks the admin role. |
| API calls | `openapi-fetch` with types generated from `packages/contracts/openapi.json`. Run `pnpm gen:api` after API changes. |
| Data | TanStack Query. Screens refetch when the API pushes `order.updated` over Socket.IO, so boards stay live. |
| UI | Tailwind v4, shadcn/ui (Radix), lucide icons. Theme tokens are in `src/app/globals.css`. |
| Images | `ImageUpload` (`src/components/image-upload.tsx`) handles upload, drag and drop, preview, replace and remove, with "paste a link" as a fallback. It is used for category, item, promotion and banner images. |
| Roles | The API enforces every permission. The UI only hides what an admin cannot use (Staff is for super admins). |

Folder guide:

- `src/app/(app)/`: signed-in screens
- `src/app/login/`: sign-in
- `src/components/`: shared building blocks such as the page header, empty and error states, status badges and the confirm dialog
- `src/lib/api/`: client, generated types and the mutation helper
- `src/lib/format.ts`: money in paise, IST dates and phone numbers

## Brand

The palette and logo mark are provisional until the IronDost identity is designed. Update the `--brand*` and `--sidebar*` tokens in `globals.css` and the mark in `src/components/brand.tsx`.
