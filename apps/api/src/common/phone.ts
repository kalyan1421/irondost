/**
 * The number to call a customer on: the verified sign-in number when they have one, otherwise the contact number they
 * typed at checkout. Null until they have given either.
 */
export function customerPhone(u: { phone: string | null; contactPhone: string | null }): string | null {
  return u.phone ?? u.contactPhone;
}

/**
 * Normalises an Indian mobile number to E.164 (+91XXXXXXXXXX).
 * Accepts "9876543210", "09876543210", "919876543210", "+91 98765 43210".
 * Returns null when the input is not a valid Indian mobile number.
 */
export function normalizeIndianPhone(input: string): string | null {
  const digits = input.replace(/[\s()-]/g, '').replace(/^\+/, '');
  let local: string;
  if (/^91\d{10}$/.test(digits)) local = digits.slice(2);
  else if (/^0\d{10}$/.test(digits)) local = digits.slice(1);
  else if (/^\d{10}$/.test(digits)) local = digits;
  else return null;
  return /^[6-9]\d{9}$/.test(local) ? `+91${local}` : null;
}
