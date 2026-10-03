"use client";

import { Label } from "@/components/ui/label";
import { cn } from "@/lib/utils";

export interface ControlProps {
  id: string;
  "aria-invalid"?: boolean;
  "aria-describedby"?: string;
}

/** Label, control, then either the error or a hint underneath, wired up for screen readers. */
export function FormField({
  id,
  label,
  hint,
  error,
  className,
  children,
}: {
  id: string;
  label: React.ReactNode;
  hint?: React.ReactNode;
  error?: string | false | null;
  className?: string;
  children: (props: ControlProps) => React.ReactNode;
}) {
  const note = error || hint;
  const noteId = `${id}-note`;
  return (
    <div className={cn("grid content-start gap-1.5", className)}>
      <Label htmlFor={id}>{label}</Label>
      {children({ id, "aria-invalid": error ? true : undefined, "aria-describedby": note ? noteId : undefined })}
      {note ? (
        <p id={noteId} className={cn("text-xs", error ? "text-destructive" : "text-muted-foreground")}>
          {note}
        </p>
      ) : null}
    </div>
  );
}
