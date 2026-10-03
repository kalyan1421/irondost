/** ₹248 or ₹248.50 from paise, for notification copy. */
export const rupees = (paise: number): string => `₹${(paise / 100).toFixed(paise % 100 === 0 ? 0 : 2)}`;
