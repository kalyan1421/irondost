import { Check } from "lucide-react";
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";

/** One numbered part of the new-order form. The number turns into a tick once the part is filled in. */
export function Section({
  step,
  title,
  description,
  done,
  action,
  children,
}: {
  step: number;
  title: string;
  description?: React.ReactNode;
  done?: boolean;
  action?: React.ReactNode;
  children: React.ReactNode;
}) {
  const headingId = `new-order-step-${step}`;
  return (
    <Card role="group" aria-labelledby={headingId}>
      <CardHeader>
        <CardTitle>
          <h2 id={headingId} className="flex items-center gap-2.5 text-base font-medium">
            <span
              className={cn(
                "tabular flex size-6 shrink-0 items-center justify-center rounded-full text-xs font-semibold",
                done ? "bg-primary text-primary-foreground" : "bg-muted text-muted-foreground",
              )}
              aria-hidden
            >
              {done ? <Check className="size-3.5" /> : step}
            </span>
            {title}
            {done ? <span className="sr-only">(complete)</span> : null}
          </h2>
        </CardTitle>
        {description ? <CardDescription className="pl-8.5">{description}</CardDescription> : null}
        {action ? <CardAction>{action}</CardAction> : null}
      </CardHeader>
      <CardContent>{children}</CardContent>
    </Card>
  );
}
