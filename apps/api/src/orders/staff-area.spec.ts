import { AppError } from '../common/errors.js';
import type { ServiceAreaSettings } from '../settings/service-area.js';
import { staffAreaOverrideReason } from './staff-area.js';

const open: ServiceAreaSettings = { serviceCenterLatitude: null, serviceCenterLongitude: null, serviceRadiusKm: null, servicePincodes: [] };
const area: ServiceAreaSettings = { serviceCenterLatitude: 17.4126, serviceCenterLongitude: 78.4482, serviceRadiusKm: 8, servicePincodes: ['500033', '500034'] };

const inside = { id: 'a-in', latitude: 17.4325, longitude: 78.4071, pincode: '500033' };
const far = { id: 'a-far', latitude: 17.4401, longitude: 78.3489, pincode: '500033' }; // ~11 km, listed PIN
const unlistedPin = { id: 'a-pin', latitude: null, longitude: null, pincode: '500003' };
const listedPinOnly = { id: 'a-listed', latitude: null, longitude: null, pincode: '500033' };
const nothing = { id: 'a-none', latitude: null, longitude: null, pincode: '500033' };

const refusal = (fn: () => unknown): AppError => {
  try {
    fn();
  } catch (e) {
    return e as AppError;
  }
  throw new Error('expected a refusal');
};

describe('staffAreaOverrideReason', () => {
  it('lets an address inside the area through and ignores a typed reason', () => {
    expect(staffAreaOverrideReason([inside], area, undefined)).toBeNull();
    expect(staffAreaOverrideReason([inside], area, 'not needed')).toBeNull();
  });

  it('accepts a served PIN code with no map pin', () => {
    expect(staffAreaOverrideReason([listedPinOnly], area, undefined)).toBeNull();
  });

  it('refuses an address it cannot check, even with a reason', () => {
    for (const settings of [open, { ...open, serviceRadiusKm: 6, serviceCenterLatitude: 17.3, serviceCenterLongitude: 78.5 }]) {
      const e = refusal(() => staffAreaOverrideReason([nothing], settings, 'a perfectly good reason'));
      expect(e.code).toBe('ADDRESS_LOCATION_REQUIRED');
      expect(e.details).toEqual({ addressId: 'a-none' });
    }
  });

  it('refuses an address outside the area unless staff type a reason', () => {
    const e = refusal(() => staffAreaOverrideReason([far], area, undefined));
    expect(e.code).toBe('ADDRESS_NOT_SERVICEABLE');
    expect(e.details).toMatchObject({ addressId: 'a-far', reason: 'OUTSIDE_RADIUS', canOverride: true });
    expect((e.details as { distanceKm: number }).distanceKm).toBeGreaterThan(8);
    expect(refusal(() => staffAreaOverrideReason([far], area, '   ')).code).toBe('ADDRESS_NOT_SERVICEABLE');
    expect(refusal(() => staffAreaOverrideReason([unlistedPin], area, undefined)).details).toMatchObject({ reason: 'PINCODE_NOT_SERVED' });
  });

  it('returns the reason it used, trimmed', () => {
    expect(staffAreaOverrideReason([far], area, '  Regular customer, partner passes by  ')).toBe('Regular customer, partner passes by');
    expect(staffAreaOverrideReason([inside, far], area, 'one of two is outside')).toBe('one of two is outside');
  });

  it('judges the pickup and delivery addresses together, asking for a pin before a reason', () => {
    // With no PIN list, an address without a pin cannot be checked at all, while the other is outside by distance.
    const radiusOnly = { ...area, servicePincodes: [] };
    expect(refusal(() => staffAreaOverrideReason([far, nothing], radiusOnly, 'reason enough')).code).toBe('ADDRESS_LOCATION_REQUIRED');
    expect(staffAreaOverrideReason([inside, inside], area, undefined)).toBeNull();
  });
});
