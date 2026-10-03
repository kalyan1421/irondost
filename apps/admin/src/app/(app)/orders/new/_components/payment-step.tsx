"use client";

import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import type { PaymentMethod } from "@/lib/api/types";

export const INSTRUCTIONS_MAX = 500;

const METHODS: { value: PaymentMethod; title: string; hint: string }[] = [
  { value: "COD", title: "Cash on delivery", hint: "The delivery partner collects cash when the clothes are returned." },
  { value: "ONLINE", title: "Online", hint: "The customer pays in the IronDost app." },
];

export function PaymentStep({
  method,
  onMethod,
  instructions,
  onInstructions,
}: {
  method: PaymentMethod;
  onMethod: (m: PaymentMethod) => void;
  instructions: string;
  onInstructions: (v: string) => void;
}) {
  return (
    <div className="grid gap-5">
      <fieldset className="grid gap-2 sm:grid-cols-2">
        <legend className="sr-only">Payment method</legend>
        {METHODS.map((m) => {
          const id = `payment-${m.value}`;
          return (
            <Label
              key={m.value}
              htmlFor={id}
              className="cursor-pointer items-start gap-3 rounded-lg border p-3 font-normal leading-normal transition-colors hover:bg-accent/40 has-checked:border-primary has-checked:bg-primary/5 has-focus-visible:ring-3 has-focus-visible:ring-ring/50"
            >
              <input
                type="radio"
                id={id}
                name="payment-method"
                className="mt-1 accent-primary outline-none"
                checked={method === m.value}
                onChange={() => onMethod(m.value)}
              />
              <span className="grid gap-0.5">
                <span className="font-medium">{m.title}</span>
                <span className="text-xs text-muted-foreground">{m.hint}</span>
              </span>
            </Label>
          );
        })}
      </fieldset>
      <div className="grid gap-1.5">
        <Label htmlFor="order-instructions">
          Instructions for the partner <span className="font-normal text-muted-foreground">(optional)</span>
        </Label>
        <Textarea
          id="order-instructions"
          placeholder="e.g. Call before arriving. Gate code 4512."
          maxLength={INSTRUCTIONS_MAX}
          value={instructions}
          onChange={(e) => onInstructions(e.target.value)}
        />
        <p className="tabular text-right text-xs text-muted-foreground">
          {instructions.length}/{INSTRUCTIONS_MAX}
        </p>
      </div>
    </div>
  );
}
