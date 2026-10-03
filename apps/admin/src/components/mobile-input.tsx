"use client";

import { InputGroup, InputGroupAddon, InputGroupInput, InputGroupText } from "@/components/ui/input-group";

export const MOBILE_HINT = "Enter a 10-digit mobile number starting with 6, 7, 8 or 9.";

/** True for a 10-digit Indian mobile number (starts with 6–9). */
export function isValidMobile(local: string): boolean {
  return /^[6-9]\d{9}$/.test(local);
}

/**
 * The 10-digit local number from whatever was typed or pasted:
 * "+91 98765 43210", "098765 43210" and "+919876543210" all become "9876543210".
 */
export function toLocalMobile(input: string): string {
  const d = input.replace(/\D/g, "");
  if (d.length >= 12 && d.startsWith("91")) return d.slice(2, 12);
  if (d.length === 11 && d.startsWith("0")) return d.slice(1);
  return d.slice(0, 10);
}

/** Mobile number field with a fixed +91 prefix. `value` is the 10-digit local part. */
export function MobileInput({
  id,
  value,
  onChange,
  onBlur,
  invalid,
  describedBy,
  autoFocus,
  autoComplete = "off",
}: {
  id: string;
  value: string;
  onChange: (local: string) => void;
  onBlur?: () => void;
  invalid?: boolean;
  describedBy?: string;
  autoFocus?: boolean;
  /** "tel-national" on the sign-in screen; "off" when typing someone else's number. */
  autoComplete?: string;
}) {
  return (
    <InputGroup>
      <InputGroupAddon>
        <InputGroupText className="tabular">+91</InputGroupText>
      </InputGroupAddon>
      <InputGroupInput
        id={id}
        type="tel"
        inputMode="numeric"
        autoComplete={autoComplete}
        placeholder="98765 43210"
        className="tabular"
        value={value}
        onChange={(e) => onChange(toLocalMobile(e.target.value))}
        onBlur={onBlur}
        aria-invalid={invalid || undefined}
        aria-describedby={describedBy}
        autoFocus={autoFocus}
      />
    </InputGroup>
  );
}
