"use client";

import { ImageOff } from "lucide-react";
import { useState } from "react";
import { cn } from "@/lib/utils";

/**
 * Banner artwork at the app's 16:9 shape. A plain <img> because next/image is not
 * configured for remote hosts; falls back to a message when there is nothing to show.
 */
export function BannerImage({
  src,
  alt,
  emptyText = "No image",
  className,
}: {
  src: string | null;
  alt: string;
  emptyText?: string;
  className?: string;
}) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null);

  if (!src || failedSrc === src) {
    return (
      <div
        className={cn(
          "flex aspect-video w-full flex-col items-center justify-center gap-1.5 bg-muted px-4 text-center text-xs text-muted-foreground",
          className,
        )}
      >
        <ImageOff className="size-5" aria-hidden />
        {src ? "This image could not be loaded. Check that the link opens an image." : emptyText}
      </div>
    );
  }

  return (
    // eslint-disable-next-line @next/next/no-img-element
    <img
      src={src}
      alt={alt}
      loading="lazy"
      className={cn("aspect-video w-full bg-muted object-cover", className)}
      onError={() => setFailedSrc(src)}
    />
  );
}
