import { cn } from "@/lib/utils";

/**
 * IronDost mark on its white tile, matching the app icon. This is the simplified
 * small-size drawing from packages/brand (irondost-mark-small); logo colours are
 * fixed and do not follow the theme.
 */
export function BrandMark({ className }: { className?: string }) {
  return (
    <span aria-hidden className={cn("inline-flex size-8 shrink-0 items-center justify-center rounded-lg bg-white ring-1 ring-black/10", className)}>
      <svg viewBox="2.2 6.2 122.9 71.7" className="w-[82%]">
        <g transform="translate(2 6)" strokeLinejoin="round" strokeLinecap="round">
          <rect x="8" y="65" width="9" height="6" rx="2" fill="#0E1E3D" />
          <rect x="43" y="65" width="9" height="6" rx="2" fill="#0E1E3D" />
          <rect x="2" y="2" width="56" height="66" rx="9" fill="#FFFFFF" />
          <path d="M11 2H49Q58 2 58 11V18H2V11Q2 2 11 2Z" fill="#E6EEF8" />
          <rect x="2" y="2" width="56" height="66" rx="9" fill="none" stroke="#0E1E3D" strokeWidth="3.6" />
          <path d="M2 18H58" fill="none" stroke="#0E1E3D" strokeWidth="3.2" />
          <circle cx="12" cy="10" r="3.8" fill="#1F4FD1" stroke="#0E1E3D" strokeWidth="2.6" />
          <circle cx="30" cy="43" r="18" fill="#DCE4EE" stroke="#0E1E3D" strokeWidth="3.6" />
          <circle cx="30" cy="43" r="12" fill="#BFEAF8" />
          <path d="M18.09 44.5Q21.07 41.2 24.05 44.5T30 44.5T35.95 44.5T41.91 44.5A12 12 0 0 1 18.09 44.5Z" fill="#3FB8EA" />
          <circle cx="30" cy="43" r="12" fill="none" stroke="#0E1E3D" strokeWidth="3.2" />
        </g>
        <g transform="translate(43.1 31.4) scale(0.7)" strokeLinejoin="round" strokeLinecap="round" stroke="#0E1E3D" strokeWidth="4.8">
          <path
            d="M38 40C41 27 48 14.5 60 13L97 11.5C104 11.5 107.5 15.5 107.5 22L108 40ZM57 36C58.5 29 62 23.5 68 23L94 22.5C96 22.5 97 23.5 97 25.5L97 36Z"
            fill="#FFFFFF"
            fillRule="evenodd"
          />
          <path d="M7 57C12 46 26 37.5 44 36L102 34Q110.5 34 111.5 43L112 57Z" fill="#1F4FD1" />
          <path d="M3 61Q8 55 22 54H109Q114 54 114 58.75Q114 63.5 109 63.5H12Q5 63.5 3 61Z" fill="#C9D2DD" />
        </g>
      </svg>
    </span>
  );
}

/** Mark plus "IronDost". Pass `inverse` on dark surfaces so "Dost" switches from royal to sky. */
export function BrandWordmark({ className, subtitle, inverse }: { className?: string; subtitle?: string; inverse?: boolean }) {
  return (
    <span className={cn("flex items-center gap-2.5", className)}>
      <BrandMark />
      <span className="flex flex-col leading-none">
        <span className="font-heading text-[17px] font-bold tracking-tight">
          Iron<span className={inverse ? "text-brand" : "text-primary"}>Dost</span>
        </span>
        {subtitle ? <span className="mt-1 text-[11px] font-medium uppercase tracking-wider opacity-60">{subtitle}</span> : null}
      </span>
    </span>
  );
}
