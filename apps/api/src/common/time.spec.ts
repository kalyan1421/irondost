import { TimeSlot } from '../generated/prisma/enums.js';
import { addDays, daysBetween, fromDbDate, isIsoDate, istDate, slotEnd, slotStart, toDbDate } from './time.js';

describe('IST time helpers', () => {
  it('reads the IST calendar date, which rolls over at 18:30 UTC', () => {
    expect(istDate(new Date('2026-10-02T18:29:59Z'))).toBe('2026-10-02');
    expect(istDate(new Date('2026-10-02T18:30:00Z'))).toBe('2026-10-03');
  });

  it('places slots at IST wall-clock hours', () => {
    expect(slotStart('2026-10-05', TimeSlot.MORNING).toISOString()).toBe('2026-10-05T01:30:00.000Z'); // 07:00 IST
    expect(slotEnd('2026-10-05', TimeSlot.MORNING).toISOString()).toBe('2026-10-05T05:30:00.000Z'); // 11:00 IST
    expect(slotStart('2026-10-05', TimeSlot.NOON).toISOString()).toBe('2026-10-05T05:30:00.000Z');
    expect(slotEnd('2026-10-05', TimeSlot.EVENING).toISOString()).toBe('2026-10-05T14:30:00.000Z'); // 20:00 IST
  });

  it('does date arithmetic across month and year boundaries', () => {
    expect(addDays('2026-12-31', 1)).toBe('2027-01-01');
    expect(addDays('2028-02-28', 1)).toBe('2028-02-29');
    expect(daysBetween('2026-10-30', '2026-11-02')).toBe(3);
  });

  it('validates real calendar dates', () => {
    expect(isIsoDate('2026-02-28')).toBe(true);
    expect(isIsoDate('2026-02-30')).toBe(false);
    expect(isIsoDate('2026-2-3')).toBe(false);
  });

  it('round-trips @db.Date values', () => {
    expect(fromDbDate(toDbDate('2026-10-05'))).toBe('2026-10-05');
  });
});
