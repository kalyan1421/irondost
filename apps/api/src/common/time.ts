import { TimeSlot } from '../generated/prisma/enums.js';

/** India has no daylight saving, so IST is a fixed UTC+05:30. */
const IST_OFFSET_MS = 330 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

/** Slot windows in IST hours [start, end). */
export const SLOT_HOURS: Record<TimeSlot, readonly [number, number]> = {
  [TimeSlot.MORNING]: [7, 11],
  [TimeSlot.NOON]: [11, 16],
  [TimeSlot.EVENING]: [16, 20],
};

export const SLOT_ORDER: readonly TimeSlot[] = [TimeSlot.MORNING, TimeSlot.NOON, TimeSlot.EVENING];

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;

/** True for a real calendar date written as YYYY-MM-DD. */
export function isIsoDate(value: string): boolean {
  if (!DATE_RE.test(value)) return false;
  const d = new Date(`${value}T00:00:00.000Z`);
  return !Number.isNaN(d.getTime()) && d.toISOString().slice(0, 10) === value;
}

/** Today's calendar date in IST, as YYYY-MM-DD. */
export function istDate(now: Date): string {
  return new Date(now.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);
}

/** Adds whole days to a YYYY-MM-DD date. */
export function addDays(date: string, days: number): string {
  return new Date(Date.parse(`${date}T00:00:00.000Z`) + days * DAY_MS).toISOString().slice(0, 10);
}

/** Whole days from `a` to `b` (both YYYY-MM-DD). */
export function daysBetween(a: string, b: string): number {
  return Math.round((Date.parse(`${b}T00:00:00.000Z`) - Date.parse(`${a}T00:00:00.000Z`)) / DAY_MS);
}

/** The UTC instant of an IST wall-clock hour on a given date. */
export function istInstant(date: string, hour: number): Date {
  return new Date(Date.parse(`${date}T00:00:00.000Z`) + hour * 60 * 60 * 1000 - IST_OFFSET_MS);
}

export function slotStart(date: string, slot: TimeSlot): Date {
  return istInstant(date, SLOT_HOURS[slot][0]);
}

export function slotEnd(date: string, slot: TimeSlot): Date {
  return istInstant(date, SLOT_HOURS[slot][1]);
}

/** Converts a YYYY-MM-DD string to the Date Prisma stores in a `@db.Date` column. */
export function toDbDate(date: string): Date {
  return new Date(`${date}T00:00:00.000Z`);
}

/** Converts a `@db.Date` value back to YYYY-MM-DD. */
export function fromDbDate(date: Date): string {
  return date.toISOString().slice(0, 10);
}
