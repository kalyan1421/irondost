import { ImageIcon } from "lucide-react";
import { cn } from "@/lib/utils";

/** Small square preview of an uploaded or linked image, with a placeholder when there is none. */
export function Thumbnail({ src, alt, className }: { src: string | null | undefined; alt: string; className?: string }) {
  return (
    <span className={cn("inline-flex size-9 shrink-0 items-center justify-center overflow-hidden rounded-md border bg-muted", className)}>
      {src ? (
        // Remote and uploaded images; next/image is not configured for arbitrary hosts.
        // eslint-disable-next-line @next/next/no-img-element
        <img src={src} alt={alt} className="size-full object-cover" loading="lazy" />
      ) : (
        <ImageIcon className="size-4 text-muted-foreground/60" aria-hidden />
      )}
    </span>
  );
}
