import { normalizeIndianPhone } from './phone.js';

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
