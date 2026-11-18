import { customerPhone, normalizeIndianPhone } from './phone.js';

describe('normalizeIndianPhone', () => {
  it.each([
    ['9876543210', '+919876543210'],
    ['09876543210', '+919876543210'],
    ['919876543210', '+919876543210'],
    ['+91 98765 43210', '+919876543210'],
    ['+91-98765-43210', '+919876543210'],
    ['6000000000', '+916000000000'],
  ])('accepts %s', (input, expected) => {
    expect(normalizeIndianPhone(input)).toBe(expected);
  });

  it.each(['5876543210', '987654321', '98765432100', '+1 415 555 0100', 'abcdefghij', ''])('rejects %s', (input) => {
    expect(normalizeIndianPhone(input)).toBeNull();
  });
});

describe('customerPhone', () => {
  it('prefers the verified sign-in number over the one typed at checkout', () => {
    expect(customerPhone({ phone: '+919111111111', contactPhone: '+919222222222' })).toBe('+919111111111');
  });

  it('falls back to the number typed at checkout', () => {
    expect(customerPhone({ phone: null, contactPhone: '+919222222222' })).toBe('+919222222222');
  });

  it('is null until the customer has given one', () => {
    expect(customerPhone({ phone: null, contactPhone: null })).toBeNull();
  });
});
