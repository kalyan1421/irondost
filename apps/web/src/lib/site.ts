/** Facts about the business that appear on more than one page. Change them here. */
export const site = {
  name: "IronDost",
  tagline: "Fresh clothes, back at your door.",
  description:
    "IronDost picks up your clothes, irons, washes or dry-cleans them, and delivers them back to your door in Hyderabad. Pay online or in cash.",
  company: "Cloud Ironing Factory Private Limited",
  area: "Hyderabad",
  phone: { display: "+91 90632 90012", tel: "+919063290012" },
  email: "kalyan91333@gmail.com",
  /** Where the site is served. Set NEXT_PUBLIC_SITE_URL in production; it is used for sharing previews and the sitemap. */
  url: process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3002",
  /** The Play listing is the existing Cloud Ironing Factory app, which this release updates in place. */
  playStoreUrl:
    process.env.NEXT_PUBLIC_PLAY_STORE_URL ?? "https://play.google.com/store/apps/details?id=com.cloudironingfactory.customer",
  /** Empty until the App Store listing is live: the page then says "coming soon" instead of linking nowhere. */
  appStoreUrl: process.env.NEXT_PUBLIC_APP_STORE_URL ?? "",
} as const;
