/** Facts about the business that appear on more than one page. Change them here. */
export const site = {
  name: "IronDost",
  tagline: "Fresh clothes, back at your door.",
  description:
    "IronDost picks up your laundry from your door in Hyderabad, washes and irons it in our own machines, and brings it back. Ironing and dry cleaning too. Priced per piece; pay online or in cash.",
  company: "Cloud Ironing Factory Private Limited",
  area: "Hyderabad",
  phone: { display: "+91 79934 34932", tel: "+917993434932" },
  email: "kalyan91333@gmail.com",
  /** Where the site is served. Set NEXT_PUBLIC_SITE_URL in production; it is used for sharing previews and the sitemap. */
  url: process.env.NEXT_PUBLIC_SITE_URL ?? "http://localhost:3002",
  /** Live IronDost listings (Play: com.irondost.customer; App Store id 6819166862, India). */
  playStoreUrl:
    process.env.NEXT_PUBLIC_PLAY_STORE_URL ?? "https://play.google.com/store/apps/details?id=com.irondost.customer",
  /** Set to "" to show "coming soon" instead of the App Store button. */
  appStoreUrl:
    process.env.NEXT_PUBLIC_APP_STORE_URL ?? "https://apps.apple.com/in/app/irondost-laundry-ironing/id6819166862",
} as const;
