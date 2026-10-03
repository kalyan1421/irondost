import { checkServiceArea, distanceKm, type ServiceAreaSettings } from './service-area.js';

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
