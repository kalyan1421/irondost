# IronDost website

The public site for IronDost: what the service is, how it works, support, and the pages the app stores require
(privacy policy, terms, cancellation and refunds, how to delete your account). Next.js App Router, Tailwind 4, no database and no
client-side JavaScript beyond what Next ships: every page is built once and served as static files.

```bash
pnpm --filter @laundry/web dev      # http://localhost:3002
pnpm --filter @laundry/web build    # production build
pnpm --filter @laundry/web lint
pnpm --filter @laundry/web typecheck
```

## Pages

| Path | What it is |
|---|---|
| `/` | Home: hero with the app, how it works, services, tracking and offers, service area, questions, download |
| `/support` | Call and email, and what to have ready |
| `/privacy`, `/terms`, `/cancellation` | The policies, from `packages/legal/legal.json` (same text as the app) |
| `/delete-account` | How to delete an account in the app or by asking us (required by Google Play) |
| `/sitemap.xml`, `/robots.txt` | Generated |

`/privacy`, `/terms` and `/cancellation` keep the paths the old Cloud Ironing Factory site used, so existing store listings still work.

## Settings

Copy `.env.example` to `.env.local`.

| Variable | Meaning |
|---|---|
| `NEXT_PUBLIC_SITE_URL` | The public address. Used for link previews, canonical links and the sitemap. Set it in production. |
| `NEXT_PUBLIC_PLAY_STORE_URL` | Defaults to the existing `com.cloudironingfactory.customer` Play listing. |
| `NEXT_PUBLIC_APP_STORE_URL` | Set when the App Store listing is live. Until then the page says "iPhone: coming soon". |

The phone number, email and company name are in `src/lib/site.ts`.

## Content you will change

- **Policy text:** edit `packages/legal/legal.json` only (see its README), then run `dart run tool/gen_legal.dart` in `apps/customer`.
  The text needs review by whoever is responsible for the business before release.
- **Screenshots** in `public/screens` are the app's own, resized to 540 px wide from `apps/customer/store/ios`.
  Replace them when the app's look changes.
- **Logos and icons** come from `packages/brand`. After rebuilding the brand, copy `logo/svg/irondost-logo.svg`,
  `irondost-logo-reverse.svg`, `irondost-mark.svg`, `irondost-logo-tagline.svg` into `public/brand/`, and
  `icons/web/favicon.ico`, `favicon.svg` (as `icon.svg`), `apple-touch-icon.png` (as `apple-icon.png`) and
  `social/og-image-1200x630.png` (as `opengraph-image.png`) into `src/app/`.

## Deleting accounts on request

The delete-account page tells people who cannot open the app to email or call. Staff then open the customer in the admin and use
**Delete account** on the profile card (`DELETE /v1/admin/customers/:id`). It erases the same data as the in-app deletion, refuses while
orders are in progress, and records who did it in the audit log. Check the person is who they say they are before deleting.

## Deploying

Any host that runs Next.js or serves its static output works (Vercel, an S3 and CloudFront bucket with `next build` output, a container).
Nothing here talks to the API. Before launch: set `NEXT_PUBLIC_SITE_URL`, review the policy text, and confirm the contact details.
