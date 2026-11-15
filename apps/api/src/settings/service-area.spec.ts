import { checkServiceArea, checkStaffArea, distanceBand, distanceFromCentre, distanceKm, type ServiceAreaSettings } from './service-area.js';

// Hub at Banjara Hills, Hyderabad.
const HUB = { serviceCenterLatitude: 17.4126, serviceCenterLongitude: 78.4482 };
const open: ServiceAreaSettings = { serviceCenterLatitude: null, serviceCenterLongitude: null, serviceRadiusKm: null, servicePincodes: [] };
const radius8: ServiceAreaSettings = { ...open, ...HUB, serviceRadiusKm: 8 };
const pincodes: ServiceAreaSettings = { ...open, servicePincodes: ['500034', '500033'] };

const jubileeHills = { latitude: 17.4325, longitude: 78.4071, pincode: '500033' }; // ~4.8 km
const secunderabad = { latitude: 17.4399, longitude: 78.4983, pincode: '500003' }; // ~6.1 km
const gachibowli = { latitude: 17.4401, longitude: 78.3489, pincode: '500032' }; // ~11 km

describe('distanceKm', () => {
  it('matches known distances', () => {
    expect(distanceKm(HUB.serviceCenterLatitude, HUB.serviceCenterLongitude, jubileeHills.latitude, jubileeHills.longitude)).toBeCloseTo(4.9, 0);
    expect(distanceKm(0, 0, 0, 0)).toBe(0);
  });
});

describe('checkServiceArea', () => {
  it('serves everywhere when nothing is configured', () => {
    expect(checkServiceArea(gachibowli, open)).toEqual({ serviceable: true, reason: null, distanceKm: null });
  });

  it('applies the radius around the hub', () => {
    expect(checkServiceArea(jubileeHills, radius8)).toMatchObject({ serviceable: true, reason: null });
    const far = checkServiceArea(gachibowli, radius8);
    expect(far).toMatchObject({ serviceable: false, reason: 'OUTSIDE_RADIUS' });
    expect(far.distanceKm).toBeGreaterThan(8);
  });

  it('applies the PIN code allow-list', () => {
    expect(checkServiceArea(jubileeHills, pincodes).serviceable).toBe(true);
    expect(checkServiceArea(secunderabad, pincodes)).toEqual({ serviceable: false, reason: 'PINCODE_NOT_SERVED', distanceKm: null });
  });

  it('needs both rules to pass when both are set', () => {
    const both = { ...radius8, servicePincodes: ['500034', '500033'] };
    expect(checkServiceArea(jubileeHills, both).serviceable).toBe(true);
    // Inside the radius but on a PIN code the business does not serve.
    expect(checkServiceArea(secunderabad, both).reason).toBe('PINCODE_NOT_SERVED');
  });

  it('skips a rule when the place lacks what it needs', () => {
    // Map pin before the PIN code is known.
    expect(checkServiceArea({ latitude: jubileeHills.latitude, longitude: jubileeHills.longitude }, pincodes).serviceable).toBe(true);
    // Staff-typed address without coordinates.
    expect(checkServiceArea({ pincode: '500032' }, radius8).serviceable).toBe(true);
  });
});

describe('checkStaffArea', () => {
  const both = { ...radius8, servicePincodes: ['500034', '500033'] };

  it('is verified by a map pin, whatever the PIN list says', () => {
    expect(checkStaffArea({ latitude: jubileeHills.latitude, longitude: jubileeHills.longitude }, open)).toMatchObject({ serviceable: true, verified: true });
    expect(checkStaffArea(jubileeHills, radius8)).toMatchObject({ serviceable: true, verified: true, distanceKm: expect.any(Number) });
  });

  it('is verified by a PIN code on the served list when there is no pin', () => {
    expect(checkStaffArea({ pincode: '500033' }, pincodes)).toMatchObject({ serviceable: true, reason: null, verified: true });
    expect(checkStaffArea({ pincode: '500033' }, both)).toMatchObject({ serviceable: true, verified: true });
  });

  it('is not verified when nothing could be checked: no pin, and no PIN list to match', () => {
    expect(checkStaffArea({ pincode: '500033' }, open)).toMatchObject({ serviceable: true, verified: false });
    expect(checkStaffArea({ pincode: '500033' }, radius8)).toMatchObject({ serviceable: true, verified: false });
    expect(checkStaffArea({}, pincodes)).toMatchObject({ serviceable: true, verified: false });
  });

  it('says outside for a PIN code off the list or a pin beyond the radius', () => {
    expect(checkStaffArea({ pincode: '500003' }, pincodes)).toMatchObject({ serviceable: false, reason: 'PINCODE_NOT_SERVED', verified: false });
    expect(checkStaffArea(gachibowli, radius8)).toMatchObject({ serviceable: false, reason: 'OUTSIDE_RADIUS', verified: true });
  });
});

describe('distanceFromCentre', () => {
  it('measures a map pin whatever else decides the answer', () => {
    const both = { ...radius8, servicePincodes: ['500034'] };
    // Refused for its PIN code, but still 4.9 km from the centre.
    expect(checkServiceArea(jubileeHills, both).distanceKm).toBeNull();
    expect(distanceFromCentre(jubileeHills, both)).toBeCloseTo(4.9, 0);
  });

  it('is null without a centre or without a pin', () => {
    expect(distanceFromCentre(jubileeHills, open)).toBeNull();
    expect(distanceFromCentre({ pincode: '500033' }, radius8)).toBeNull();
  });
});

describe('distanceBand', () => {
  it.each([
    [null, 'UNKNOWN'],
    [0, 'UNDER_6'],
    [5.9, 'UNDER_6'],
    [6, 'KM_6_8'],
    [7.9, 'KM_6_8'],
    [8, 'KM_8_10'],
    [9.9, 'KM_8_10'],
    [10, 'KM_10_PLUS'],
    [42.5, 'KM_10_PLUS'],
  ] as const)('puts %s km in %s', (km, band) => {
    expect(distanceBand(km)).toBe(band);
  });
});
