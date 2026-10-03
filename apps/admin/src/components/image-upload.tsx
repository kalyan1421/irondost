"use client";

import { ImageOff, ImageUp, Link2, Loader2, RefreshCw, Trash2 } from "lucide-react";
import { useId, useRef, useState } from "react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { errorMessage } from "@/lib/api/client";
import { ACCEPTED_IMAGE_TYPES, MAX_IMAGE_BYTES, uploadImage, type ImagePurpose } from "@/lib/api/upload";
import { cn } from "@/lib/utils";

const ASPECT = {
  square: "aspect-square max-w-48",
  wide: "aspect-video w-full",
} as const;

const SIZE_NOTE: Record<ImagePurpose, string> = {
  catalog: "Square images look best. Resized to at most 800 px.",
  promotion: "Resized to at most 1200 px.",
  banner: "Use a wide image, about 16:9. Resized to at most 1600 px.",
};

/**
 * Image picker for imageUrl fields: upload (click or drag and drop) with a
 * preview, or paste a link. `value` is the URL to save ("" for none).
 * Pass the props from <FormField> so the label and error are wired up.
 */
export function ImageUpload({
  id,
  value,
  onChange,
  purpose,
  aspect = "square",
  alt,
  required = false,
  "aria-invalid": invalid,
  "aria-describedby": describedBy,
}: {
  id: string;
  value: string;
  onChange: (url: string) => void;
  purpose: ImagePurpose;
  aspect?: keyof typeof ASPECT;
  /** Describes the image for screen readers in the preview. */
  alt: string;
  required?: boolean;
  "aria-invalid"?: boolean;
  "aria-describedby"?: string;
}) {
  const fileInput = useRef<HTMLInputElement>(null);
  const [uploading, setUploading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [dragging, setDragging] = useState(false);
  const [showLink, setShowLink] = useState(false);
  const [broken, setBroken] = useState<string | null>(null);
  const linkId = useId();
  const statusId = useId();

  async function handleFile(file: File | undefined) {
    if (!file) return;
    if (!ACCEPTED_IMAGE_TYPES.includes(file.type)) return setError("Choose a JPG, PNG, WebP, AVIF or GIF image.");
    if (file.size > MAX_IMAGE_BYTES) return setError("That image is larger than 8 MB. Choose a smaller one.");
    setError(null);
    setUploading(true);
    try {
      const uploaded = await uploadImage(file, purpose);
      onChange(uploaded.url);
      setBroken(null);
      setShowLink(false);
    } catch (err) {
      setError(errorMessage(err));
    } finally {
      setUploading(false);
      if (fileInput.current) fileInput.current.value = "";
    }
  }

  const describedByIds = [describedBy, error ? statusId : undefined].filter(Boolean).join(" ") || undefined;
  const isBroken = Boolean(value) && broken === value;

  return (
    <div className="grid gap-2">
      <input
        ref={fileInput}
        type="file"
        accept={ACCEPTED_IMAGE_TYPES.join(",")}
        className="sr-only"
        tabIndex={-1}
        aria-hidden
        onChange={(e) => void handleFile(e.target.files?.[0])}
      />
      <div
        className={cn(
          "relative overflow-hidden rounded-lg border bg-muted/40 transition-colors",
          ASPECT[aspect],
          !value && "border-dashed",
          dragging && "border-primary bg-primary/5 ring-2 ring-primary/30",
          invalid && !value && "border-destructive",
        )}
        onDragOver={(e) => {
          e.preventDefault();
          setDragging(true);
        }}
        onDragLeave={() => setDragging(false)}
        onDrop={(e) => {
          e.preventDefault();
          setDragging(false);
          void handleFile(e.dataTransfer.files?.[0]);
        }}
      >
        {value && !isBroken ? (
          // Remote and uploaded images; next/image is not configured for arbitrary hosts.
          // eslint-disable-next-line @next/next/no-img-element
          <img src={value} alt={alt} className="size-full object-cover" onError={() => setBroken(value)} />
        ) : value && isBroken ? (
          <div className="flex size-full flex-col items-center justify-center gap-1 p-3 text-center text-xs text-muted-foreground">
            <ImageOff className="size-5" />
            This image could not be loaded. Check the link or upload the image instead.
          </div>
        ) : (
          <div className="flex size-full flex-col items-center justify-center gap-2 p-3 text-center">
            <ImageUp className="size-6 text-muted-foreground" />
            <p className="text-xs text-muted-foreground">Drag an image here, or</p>
            <Button
              id={id}
              type="button"
              size="sm"
              variant="outline"
              disabled={uploading}
              aria-invalid={invalid}
              aria-describedby={describedByIds}
              onClick={() => fileInput.current?.click()}
            >
              Choose image
            </Button>
          </div>
        )}
        {uploading ? (
          <div className="absolute inset-0 flex items-center justify-center gap-2 bg-background/80 text-sm font-medium" role="status">
            <Loader2 className="size-4 animate-spin" /> Uploading…
          </div>
        ) : null}
      </div>

      <div className="flex flex-wrap items-center gap-x-1 gap-y-1">
        {value ? (
          <>
            <Button
              id={id}
              type="button"
              size="sm"
              variant="outline"
              disabled={uploading}
              aria-describedby={describedByIds}
              onClick={() => fileInput.current?.click()}
            >
              <RefreshCw /> Replace
            </Button>
            {!required ? (
              <Button type="button" size="sm" variant="ghost" disabled={uploading} onClick={() => onChange("")}>
                <Trash2 /> Remove
              </Button>
            ) : null}
          </>
        ) : null}
        <Button type="button" size="sm" variant="ghost" className="text-muted-foreground" onClick={() => setShowLink((s) => !s)} aria-expanded={showLink} aria-controls={linkId}>
          <Link2 /> {showLink ? "Hide link" : "Paste a link instead"}
        </Button>
      </div>

      {showLink ? (
        <Input
          id={linkId}
          aria-label="Image link"
          type="url"
          inputMode="url"
          placeholder="https://"
          value={value}
          aria-invalid={invalid}
          onChange={(e) => {
            setBroken(null);
            onChange(e.target.value);
          }}
        />
      ) : null}

      <p id={statusId} className={cn("text-xs", error ? "text-destructive" : "text-muted-foreground")} aria-live="polite">
        {error ?? `JPG, PNG or WebP up to 8 MB. ${SIZE_NOTE[purpose]}`}
      </p>
    </div>
  );
}
