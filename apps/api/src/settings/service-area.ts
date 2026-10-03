import type { BusinessSettings } from '../generated/prisma/client.js';

export type ServiceAreaSettings = Pick<
  BusinessSettings,
  'serviceCenterLatitude' | 'serviceCenterLongitude' | 'serviceRadiusKm' | 'servicePincodes'
>;

export const NOT_SERVICEABLE_REASONS = ['PINCODE_NOT_SERVED', 'OUTSIDE_RADIUS'] as const;
export type NotServiceableReason = (typeof NOT_SERVICEABLE_REASONS)[number];

export interface ServiceAreaResult {
  serviceable: boolean;
  reason: NotServiceableReason | null;
  /** Distance from the hub, when a radius is set and the place has coordinates. */
  distanceKm: number | null;
}

export interface Place {
  latitude?: number | null;
  longitude?: number | null;
  pincode?: string | null;
}

const EARTH_RADIUS_KM = 6371;
const toRad = (deg: number) => (deg * Math.PI) / 180;

/** Great-circle distance, matching the haversine SQL used for dispatch. */
export function distanceKm(lat1: number, lng1: number, lat2: number, lng2: number): number {
  const a =
    Math.sin(toRad(lat2 - lat1) / 2) ** 2 +
    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(toRad(lng2 - lng1) / 2) ** 2;
  return 2 * EARTH_RADIUS_KM * Math.asin(Math.sqrt(a));
}

/**
 * A place is served when its PIN code is on the allow-list (if there is one) and it lies within the
 * radius of the hub (if one is set). Each rule only applies when the place carries what it needs:
 * a map-pin check may arrive before the PIN code is known, and addresses typed in by staff for phone
 * orders often have no coordinates.
 */
export function checkServiceArea(place: Place, s: ServiceAreaSettings): ServiceAreaResult {
  if (place.pincode && s.servicePincodes.length > 0 && !s.servicePincodes.includes(place.pincode)) {
    return { serviceable: false, reason: 'PINCODE_NOT_SERVED', distanceKm: null };
  }
  const { serviceCenterLatitude: hubLat, serviceCenterLongitude: hubLng, serviceRadiusKm: radius } = s;
  if (hubLat == null || hubLng == null || radius == null || place.latitude == null || place.longitude == null) {
    return { serviceable: true, reason: null, distanceKm: null };
  }
  const km = Math.round(distanceKm(hubLat, hubLng, place.latitude, place.longitude) * 10) / 10;
  return km <= radius
    ? { serviceable: true, reason: null, distanceKm: km }
    : { serviceable: false, reason: 'OUTSIDE_RADIUS', distanceKm: km };
}
