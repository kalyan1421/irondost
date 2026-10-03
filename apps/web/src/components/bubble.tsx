/** A soap bubble: foam fill, ink rim. Decoration only. */
export function Bubble({ className = "" }: { className?: string }) {
  return <span aria-hidden className={`absolute rounded-full border-[3px] border-ink bg-foam ${className}`} />;
}
