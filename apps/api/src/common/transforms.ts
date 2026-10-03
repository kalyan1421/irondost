/** class-transformer helper: treat "" (a cleared form field) as null. */
export const blankToNull = ({ value }: { value: unknown }): unknown =>
  typeof value === 'string' && value.trim() === '' ? null : value;
