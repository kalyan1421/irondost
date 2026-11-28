/**
 * The launch offer shown on /get. Change it here and nowhere else.
 * OWNER TO CONFIRM: the promo code, how many orders it covers and when it ends. Until `cap` and `endsOn` are set, the page
 * leaves them out instead of guessing. The code must match the one set up in the admin, or checkout will reject it.
 */
export const launchOffer = {
  headline: "Free pickup & delivery for new customers",
  /** The code people type at checkout. PLACEHOLDER until the owner confirms it. */
  code: "FREEPICKUP",
  /** For example "your first 2 orders". null = not shown. */
  cap: null as string | null,
  /** ISO date the offer ends, for example "2026-12-31". null = not shown. */
  endsOn: null as string | null,
} as const;
