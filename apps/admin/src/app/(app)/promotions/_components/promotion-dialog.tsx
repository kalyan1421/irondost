"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Switch } from "@/components/ui/switch";
import { Textarea } from "@/components/ui/textarea";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { components } from "@/lib/api/schema";
import type { Promotion } from "@/lib/api/types";
import { paiseToInput, rupees, toPaise } from "@/lib/format";
import { FormField } from "@/components/form-field";
import { ImageUpload } from "@/components/image-upload";
import { explainErrors } from "@/lib/api/client";
import { isImageUrl, wholeNumber } from "@/lib/validation";
import { defaultWindow, discountLabel, fromIstInput, toIstInput } from "./promotion-meta";

type DiscountType = Promotion["discountType"];
type UpdatePromotionBody = components["schemas"]["UpdatePromotionDto"];
/**
 * The API clears description and image when it receives null, but the generated
 * UpdatePromotionDto only allows strings there. Drop this once the contract says `| null`.
 */

const CODE = /^[A-Z0-9]{3,20}$/;

export function PromotionDialog({ promotion, onClose }: { promotion?: Promotion; onClose: () => void }) {
  const editing = Boolean(promotion);
  const [initial] = useState(() =>
    promotion ? { from: toIstInput(promotion.validFrom), to: toIstInput(promotion.validTo) } : defaultWindow(),
  );
  const [code, setCode] = useState(promotion?.code ?? "");
  const [title, setTitle] = useState(promotion?.title ?? "");
  const [description, setDescription] = useState(promotion?.description ?? "");
  const [type, setType] = useState<DiscountType>(promotion?.discountType ?? "PERCENT");
  const [value, setValue] = useState(
    promotion ? (promotion.discountType === "FLAT" ? paiseToInput(promotion.discountValue) : String(promotion.discountValue)) : "",
  );
  const [minOrder, setMinOrder] = useState(promotion && promotion.minOrderPaise > 0 ? paiseToInput(promotion.minOrderPaise) : "");
  const [maxDiscount, setMaxDiscount] = useState(paiseToInput(promotion?.maxDiscountPaise));
  const [limit, setLimit] = useState(promotion?.perCustomerLimit != null ? String(promotion.perCustomerLimit) : "");
  const [validFrom, setValidFrom] = useState(initial.from);
  const [validTo, setValidTo] = useState(initial.to);
  const [imageUrl, setImageUrl] = useState(promotion?.imageUrl ?? "");
  const [isActive, setIsActive] = useState(promotion?.isActive ?? true);
  const [submitted, setSubmitted] = useState(false);

  const percent = type === "PERCENT";
  const trimmedTitle = title.trim();
  const trimmedDescription = description.trim();
  const trimmedImage = imageUrl.trim();
  const discountValue = percent ? wholeNumber(value) : toPaise(value);
  const minOrderPaise = minOrder.trim() ? toPaise(minOrder) : 0;
  const maxDiscountPaise = percent && maxDiscount.trim() ? toPaise(maxDiscount) : null;
  const perCustomerLimit = limit.trim() ? wholeNumber(limit) : null;
  const fromIso = fromIstInput(validFrom);
  const toIso = fromIstInput(validTo);

  const errors = {
    code: CODE.test(code) ? null : "Use 3 to 20 letters or digits, with no spaces.",
    title: trimmedTitle.length < 3 || trimmedTitle.length > 80 ? "Enter a title of 3 to 80 characters." : null,
    description: trimmedDescription.length > 500 ? "Keep the description to 500 characters or fewer." : null,
    value: percent
      ? discountValue === null || discountValue < 1 || discountValue > 100
        ? "Enter a whole number from 1 to 100."
        : null
      : discountValue === null || discountValue < 1
        ? "Enter the discount in rupees, such as 50."
        : null,
    minOrder: minOrderPaise === null ? "Enter an amount in rupees, or leave it empty for no minimum." : null,
    maxDiscount:
      percent && maxDiscount.trim() && (maxDiscountPaise === null || maxDiscountPaise < 1)
        ? "Enter an amount in rupees, or leave it empty for no cap."
        : null,
    limit:
      limit.trim() && (perCustomerLimit === null || perCustomerLimit < 1)
        ? "Enter a whole number, 1 or more, or leave it empty for no limit."
        : null,
    validFrom: fromIso ? null : "Choose the start date and time.",
    validTo: !toIso ? "Choose the end date and time." : fromIso && toIso <= fromIso ? "The end must be after the start." : null,
    imageUrl: trimmedImage && !isImageUrl(trimmedImage) ? "Upload an image, or paste a link that starts with https://" : null,
  };
  const valid = Object.values(errors).every((e) => !e);
  const show = (field: keyof typeof errors, raw: string) => (submitted || raw !== "" ? errors[field] : null);

  const summary =
    discountValue !== null && !errors.value && !errors.minOrder && !errors.maxDiscount && !errors.limit
      ? [
          `Customers get ${discountLabel({ discountType: type, discountValue, maxDiscountPaise: maxDiscountPaise || null })}`,
          minOrderPaise ? `on orders of ${rupees(minOrderPaise)} or more` : "on any order",
          perCustomerLimit ? (perCustomerLimit === 1 ? "once per customer" : `up to ${perCustomerLimit} times per customer`) : null,
        ]
          .filter(Boolean)
          .join(", ") + "."
      : null;

  const save = useApiMutation(
    () => {
      const common = {
        code,
        title: trimmedTitle,
        discountType: type,
        discountValue: discountValue ?? 0,
        minOrderPaise: minOrderPaise ?? 0,
        maxDiscountPaise,
        perCustomerLimit,
        validFrom: fromIso ?? "",
        validTo: toIso ?? "",
        isActive,
      };
      const call = promotion
        ? api.PATCH("/v1/admin/promotions/{id}", {
            params: { path: { id: promotion.id } },
            body: {
              ...common,
              description: trimmedDescription || null,
              imageUrl: trimmedImage || null,
            } satisfies UpdatePromotionBody,
          })
        : api.POST("/v1/admin/promotions", {
            body: { ...common, description: trimmedDescription || undefined, imageUrl: trimmedImage || undefined },
          });
      return explainErrors(unwrap(call), {
        ALREADY_EXISTS: `Another promotion already uses the code ${code}. Choose a different code.`,
        INVALID_WINDOW: "The end must be after the start.",
      });
    },
    {
      invalidate: [["promotions"]],
      success: (p) => (editing ? `${p.code} saved` : `${p.code} created`),
      onSuccess: onClose,
    },
  );

  function submit(e: React.FormEvent) {
    e.preventDefault();
    setSubmitted(true);
    if (valid) save.mutate(undefined);
  }

  return (
    <Dialog open onOpenChange={(o) => !o && onClose()}>
      <DialogContent className="sm:max-w-xl">
        <DialogHeader>
          <DialogTitle>{editing ? `Edit ${promotion?.code}` : "New promotion"}</DialogTitle>
          <DialogDescription>Customers enter the code at checkout. Running promotions also appear on the app home screen.</DialogDescription>
        </DialogHeader>
        <form id="promotion-form" className="-mx-1 grid max-h-[65vh] gap-4 overflow-y-auto px-1 py-0.5" onSubmit={submit} noValidate>
          <div className="grid gap-4 sm:grid-cols-[minmax(0,2fr)_minmax(0,3fr)]">
            <FormField id="promo-code" label="Code" hint="3 to 20 letters or digits." error={show("code", code)}>
              {(p) => (
                <Input
                  {...p}
                  className="font-mono"
                  value={code}
                  maxLength={20}
                  placeholder="FIRST50"
                  autoFocus
                  autoComplete="off"
                  spellCheck={false}
                  onChange={(e) => setCode(e.target.value.toUpperCase().replace(/\s+/g, ""))}
                />
              )}
            </FormField>
            <FormField id="promo-title" label="Title" hint="Shown to customers." error={show("title", title)}>
              {(p) => (
                <Input {...p} value={title} maxLength={80} placeholder="50% off your first order" onChange={(e) => setTitle(e.target.value)} />
              )}
            </FormField>
          </div>
          <FormField id="promo-description" label="Description (optional)" error={show("description", description)}>
            {(p) => <Textarea {...p} rows={2} value={description} onChange={(e) => setDescription(e.target.value)} />}
          </FormField>

          <div className="grid gap-4 sm:grid-cols-2">
            <FormField id="promo-type" label="Discount type">
              {(p) => (
                <Select value={type} onValueChange={(v) => setType(v as DiscountType)}>
                  <SelectTrigger {...p} className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="PERCENT">Percentage off</SelectItem>
                    <SelectItem value="FLAT">Fixed amount off</SelectItem>
                  </SelectContent>
                </Select>
              )}
            </FormField>
            <FormField id="promo-value" label={percent ? "Discount (%)" : "Discount (₹)"} error={show("value", value)}>
              {(p) => (
                <Input
                  {...p}
                  className="tabular"
                  inputMode={percent ? "numeric" : "decimal"}
                  value={value}
                  placeholder={percent ? "20" : "50"}
                  onChange={(e) => setValue(e.target.value)}
                />
              )}
            </FormField>
            <FormField id="promo-min" label="Minimum order (₹, optional)" hint="Leave empty for no minimum." error={show("minOrder", minOrder)}>
              {(p) => <Input {...p} className="tabular" inputMode="decimal" value={minOrder} onChange={(e) => setMinOrder(e.target.value)} />}
            </FormField>
            {percent ? (
              <FormField
                id="promo-max"
                label="Maximum discount (₹, optional)"
                hint="Leave empty for no cap."
                error={show("maxDiscount", maxDiscount)}
              >
                {(p) => (
                  <Input {...p} className="tabular" inputMode="decimal" value={maxDiscount} onChange={(e) => setMaxDiscount(e.target.value)} />
                )}
              </FormField>
            ) : null}
            <FormField
              id="promo-limit"
              label="Uses per customer (optional)"
              hint="Leave empty to allow unlimited uses."
              error={show("limit", limit)}
            >
              {(p) => <Input {...p} className="tabular" inputMode="numeric" value={limit} onChange={(e) => setLimit(e.target.value)} />}
            </FormField>
          </div>

          <div className="grid gap-4 sm:grid-cols-2">
            <FormField id="promo-from" label="Starts (IST)" error={show("validFrom", validFrom)}>
              {(p) => <Input {...p} type="datetime-local" value={validFrom} onChange={(e) => setValidFrom(e.target.value)} />}
            </FormField>
            <FormField id="promo-to" label="Ends (IST)" error={show("validTo", validTo)}>
              {(p) => <Input {...p} type="datetime-local" value={validTo} min={validFrom || undefined} onChange={(e) => setValidTo(e.target.value)} />}
            </FormField>
          </div>

          <FormField id="promo-image" label="Image for the home screen (optional)" error={show("imageUrl", imageUrl)}>
            {(p) => (
              <ImageUpload {...p} purpose="promotion" aspect="wide" value={imageUrl} onChange={setImageUrl} alt={`Image for the ${code || "new"} promotion`} />
            )}
          </FormField>

          <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
            <div className="grid gap-0.5">
              <Label htmlFor="promo-active">Active</Label>
              <p className="text-xs text-muted-foreground">When off, the promotion is paused and the code is refused at checkout.</p>
            </div>
            <Switch id="promo-active" checked={isActive} onCheckedChange={setIsActive} />
          </div>

          {summary ? (
            <p className="rounded-lg bg-muted px-3 py-2 text-sm" aria-live="polite">
              {summary}
            </p>
          ) : null}
        </form>
        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button type="submit" form="promotion-form" disabled={save.isPending}>
            {editing ? "Save promotion" : "Create promotion"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
