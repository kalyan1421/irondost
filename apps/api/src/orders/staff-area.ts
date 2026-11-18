import { AppError } from '../common/errors.js';
import type { Address } from '../generated/prisma/client.js';
import { checkStaffArea, distanceFromCentre, type ServiceAreaSettings } from '../settings/service-area.js';

type AreaAddress = Pick<Address, 'id' | 'latitude' | 'longitude' | 'pincode'>;

/**
 * The service-area rule for an order staff place by phone, for the pickup and delivery addresses together.
 *
 * - An address with no map pin and no PIN code on the served list cannot be checked, so it is refused
 *   (ADDRESS_LOCATION_REQUIRED). A typed reason does not help: staff must add the pin or use a served PIN code.
 * - An address outside the area is refused (ADDRESS_NOT_SERVICEABLE) unless staff typed a reason. That reason is returned
 *   so it can be kept on the order and in the audit log.
 *
 * Returns the reason that was used, or null when every address is inside (a typed reason is then ignored, not stored).
 */
export function staffAreaOverrideReason(
  addresses: readonly AreaAddress[],
  settings: ServiceAreaSettings,
  typedReason: string | undefined,
): string | null {
  const checked = [...new Set(addresses)].map((address) => ({ address, area: checkStaffArea(address, settings) }));

  const unverified = checked.find((c) => c.area.serviceable && !c.area.verified);
  if (unverified) {
    throw AppError.badRequest(
      'ADDRESS_LOCATION_REQUIRED',
      'Add a map pin to this address, or use a PIN code we serve, to place the order',
      { addressId: unverified.address.id },
    );
  }

  const outside = checked.find((c) => !c.area.serviceable);
  if (!outside) return null;
  const reason = typedReason?.trim();
  if (!reason) {
    throw AppError.badRequest('ADDRESS_NOT_SERVICEABLE', 'This address is outside the service area. Give a reason to place the order anyway', {
      addressId: outside.address.id,
      reason: outside.area.reason,
      distanceKm: outside.area.distanceKm ?? distanceFromCentre(outside.address, settings),
      canOverride: true,
    });
  }
  return reason;
}
