const IST = "Asia/Kolkata";

const rupeeFmt = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 2 });
const rupeeWholeFmt = new Intl.NumberFormat("en-IN", { style: "currency", currency: "INR", maximumFractionDigits: 0 });

/** ₹1,234.50 from paise; whole rupees drop the decimals. */
export function rupees(paise: number): string {
  return paise % 100 === 0 ? rupeeWholeFmt.format(paise / 100) : rupeeFmt.format(paise / 100);
}

/** Converts a rupee amount typed by a person ("15", "15.5") to paise. Returns null if invalid. */
export function toPaise(input: string): number | null {
  const v = input.trim();
  if (!/^\d+(\.\d{1,2})?$/.test(v)) return null;
  return Math.round(Number(v) * 100);
}

export function paiseToInput(paise: number | null | undefined): string {
  if (paise == null) return "";
  return paise % 100 === 0 ? String(paise / 100) : (paise / 100).toFixed(2);
}

/** "+919876543210" → "+91 98765 43210" */
export function phone(e164: string): string {
  const m = /^\+91(\d{5})(\d{5})$/.exec(e164);
  return m ? `+91 ${m[1]} ${m[2]}` : e164;
}

const dateFmt = new Intl.DateTimeFormat("en-IN", { timeZone: IST, day: "numeric", month: "short", year: "numeric" });
const shortDateFmt = new Intl.DateTimeFormat("en-IN", { timeZone: IST, weekday: "short", day: "numeric", month: "short" });
const timeFmt = new Intl.DateTimeFormat("en-IN", { timeZone: IST, hour: "numeric", minute: "2-digit" });

/** A timestamp shown as "2 Oct 2026, 2:45 pm" in IST. */
export function dateTime(value: string | Date): string {
  const d = new Date(value);
  return `${dateFmt.format(d)}, ${timeFmt.format(d)}`;
}

export function date(value: string | Date): string {
  return dateFmt.format(new Date(value));
}

/** A YYYY-MM-DD business date shown as "Mon, 5 Oct". */
export function calendarDate(isoDate: string): string {
  // Noon UTC is the same calendar day in IST, so no timezone surprises.
  return shortDateFmt.format(new Date(`${isoDate}T12:00:00Z`));
}

/** "Mon, 5 Oct · 07:00–11:00" */
export function slot(isoDate: string, label: string): string {
  return `${calendarDate(isoDate)} · ${label}`;
}

/** Today's date in IST as YYYY-MM-DD. */
export function istToday(): string {
  return new Intl.DateTimeFormat("en-CA", { timeZone: IST }).format(new Date());
}

export function relativeTime(value: string | Date): string {
  const diff = Date.now() - new Date(value).getTime();
  const min = Math.round(diff / 60_000);
  if (min < 1) return "just now";
  if (min < 60) return `${min} min ago`;
  const h = Math.round(min / 60);
  if (h < 24) return `${h} h ago`;
  return date(value);
}
