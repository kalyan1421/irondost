import type { DistanceBand } from "@/lib/api/types";

/** The distance bands the waiting list is read in, nearest first. */
export const BANDS: readonly DistanceBand[] = ["UNDER_6", "KM_6_8", "KM_8_10", "KM_10_PLUS", "UNKNOWN"];

export const BAND_LABEL: Record<DistanceBand, string> = {
  UNDER_6: "Under 6 km",
  KM_6_8: "6–8 km",
  KM_8_10: "8–10 km",
  KM_10_PLUS: "10+ km",
  UNKNOWN: "No map pin",
};

/** Why a band is worth reading: the first one is only there because of the PIN code list. */
export const BAND_HINT: Record<DistanceBand, string> = {
  UNDER_6: "Inside 6 km but on a PIN code we do not serve",
  KM_6_8: "Just past the edge",
  KM_8_10: "A little further out",
  KM_10_PLUS: "Well outside",
  UNKNOWN: "The address has no map position",
};

export const STATUSES = ["OPEN", "TOLD", "ALL"] as const;
export type Status = (typeof STATUSES)[number];
export const STATUS_LABEL: Record<Status, string> = { OPEN: "Waiting to be told", TOLD: "Told", ALL: "Both" };

export function pick<T extends string>(value: string | null, allowed: readonly T[], fallback: T): T {
  return allowed.includes(value as T) ? (value as T) : fallback;
}

/** "7.2 km", or a dash when there is no distance. */
export function km(value: number | null): string {
  return value === null ? "–" : `${value} km`;
}
