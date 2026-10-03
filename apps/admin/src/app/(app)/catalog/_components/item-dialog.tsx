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
import type { CatalogCategory, CatalogItem } from "@/lib/api/types";
import { paiseToInput, rupees, toPaise } from "@/lib/format";
import { CATALOG_KEYS } from "./category-dialog";
import { FormField } from "@/components/form-field";
import { ImageUpload } from "@/components/image-upload";
import { isImageUrl, wholeNumber } from "@/lib/validation";

type ItemUnit = CatalogItem["unit"];
type UpdateItemBody = components["schemas"]["UpdateItemDto"];

export const UNIT_LABEL: Record<ItemUnit, string> = {
  PIECE: "per piece",
  PAIR: "per pair",
  SET: "per set",
  KG: "per kg",
};
const UNITS = Object.keys(UNIT_LABEL) as ItemUnit[];
const MAX_PRICE_PAISE = 10_000_000;

function nextSortOrder(categories: CatalogCategory[], categoryId: string): number {
  const items = categories.find((c) => c.id === categoryId)?.items ?? [];
  return items.reduce((n, i) => Math.max(n, i.sortOrder + 1), 0);
}

export function ItemDialog({
  categories,
  item,
  categoryId: initialCategoryId,
  onClose,
}: {
  categories: CatalogCategory[];
  item?: CatalogItem;
  categoryId?: string;
  onClose: () => void;
}) {
  const editing = Boolean(item);
  const startCategory = item?.categoryId ?? initialCategoryId ?? categories[0]?.id ?? "";
  const [categoryId, setCategoryId] = useState(startCategory);
  const [name, setName] = useState(item?.name ?? "");
  const [description, setDescription] = useState(item?.description ?? "");
  const [unit, setUnit] = useState<ItemUnit>(item?.unit ?? "PIECE");
  const [price, setPrice] = useState(paiseToInput(item?.pricePaise));
  const [offer, setOffer] = useState(paiseToInput(item?.offerPricePaise));
  const [imageUrl, setImageUrl] = useState(item?.imageUrl ?? "");
  const [sortOrder, setSortOrder] = useState(String(item?.sortOrder ?? nextSortOrder(categories, startCategory)));
  const [sortEdited, setSortEdited] = useState(editing);
  const [isActive, setIsActive] = useState(item?.isActive ?? true);
  const [submitted, setSubmitted] = useState(false);

  const trimmedName = name.trim();
  const trimmedDescription = description.trim();
  const trimmedImage = imageUrl.trim();
  const pricePaise = toPaise(price);
  const offerPaise = offer.trim() ? toPaise(offer) : null;
  const sort = wholeNumber(sortOrder);

  const errors = {
    categoryId: categoryId ? null : "Choose a category.",
    name: trimmedName.length < 2 || trimmedName.length > 80 ? "Enter a name of 2 to 80 characters." : null,
    description: trimmedDescription.length > 300 ? "Keep the description to 300 characters or fewer." : null,
    price:
      pricePaise === null || pricePaise < 1
        ? "Enter the price in rupees, such as 15 or 12.50."
        : pricePaise > MAX_PRICE_PAISE
          ? `The price can be at most ${rupees(MAX_PRICE_PAISE)}.`
          : null,
    offer: !offer.trim()
      ? null
      : offerPaise === null || offerPaise < 1
        ? "Enter the offer price in rupees, or leave it empty."
        : pricePaise !== null && offerPaise >= pricePaise
          ? `The offer price must be lower than the price (${rupees(pricePaise)}).`
          : null,
    imageUrl: trimmedImage && !isImageUrl(trimmedImage) ? "Upload an image, or paste a link that starts with https://" : null,
    sortOrder: sort === null ? "Enter a whole number, 0 or more." : null,
  };
  const valid = Object.values(errors).every((e) => !e);
  const show = (field: keyof typeof errors, value: string) => (submitted || value !== "" ? errors[field] : null);
  const categoryName = categories.find((c) => c.id === categoryId)?.name ?? "";

  const save = useApiMutation(
    () => {
      if (item) {
        const body: UpdateItemBody = {
          categoryId,
          name: trimmedName,
          description: trimmedDescription || null,
          unit,
          pricePaise: pricePaise ?? 0,
          offerPricePaise: offerPaise,
          imageUrl: trimmedImage || null,
          sortOrder: sort ?? 0,
          isActive,
        };
        return unwrap(
          api.PATCH("/v1/admin/catalog/items/{id}", {
            params: { path: { id: item.id } },
            body,
          }),
        );
      }
      return unwrap(
        api.POST("/v1/admin/catalog/items", {
          body: {
            categoryId,
            name: trimmedName,
            description: trimmedDescription || undefined,
            unit,
            pricePaise: pricePaise ?? 0,
            offerPricePaise: offerPaise ?? undefined,
            imageUrl: trimmedImage || undefined,
            sortOrder: sort ?? 0,
            isActive,
          },
        }),
      );
    },
    {
      invalidate: CATALOG_KEYS,
      success: (i) => (editing ? `${i.name} saved` : `${i.name} added to ${categoryName}`),
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
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>{editing ? `Edit ${item?.name}` : "Add item"}</DialogTitle>
          <DialogDescription>
            {editing
              ? "Price changes apply to new orders. Orders already placed keep their price."
              : "Something customers can book, with its price."}
          </DialogDescription>
        </DialogHeader>
        <form id="item-form" className="-mx-1 grid max-h-[65vh] gap-4 overflow-y-auto px-1 py-0.5" onSubmit={submit} noValidate>
          <div className="grid gap-4 sm:grid-cols-2">
            <FormField id="item-category" label="Category" error={submitted ? errors.categoryId : null}>
              {(p) => (
                <Select
                  value={categoryId}
                  onValueChange={(v) => {
                    setCategoryId(v);
                    if (!sortEdited) setSortOrder(String(nextSortOrder(categories, v)));
                  }}
                >
                  <SelectTrigger {...p} className="w-full">
                    <SelectValue placeholder="Choose a category" />
                  </SelectTrigger>
                  <SelectContent>
                    {categories.map((c) => (
                      <SelectItem key={c.id} value={c.id}>
                        {c.name}
                        {c.isActive ? "" : " (hidden)"}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            </FormField>
            <FormField id="item-unit" label="Charged">
              {(p) => (
                <Select value={unit} onValueChange={(v) => setUnit(v as ItemUnit)}>
                  <SelectTrigger {...p} className="w-full">
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    {UNITS.map((u) => (
                      <SelectItem key={u} value={u}>
                        {UNIT_LABEL[u]}
                      </SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              )}
            </FormField>
          </div>
          <FormField id="item-name" label="Name" error={show("name", name)}>
            {(p) => (
              <Input {...p} value={name} maxLength={80} placeholder="e.g. Shirt / T-shirt" autoFocus onChange={(e) => setName(e.target.value)} />
            )}
          </FormField>
          <FormField
            id="item-description"
            label="Description (optional)"
            hint="A short note shown under the name in the app."
            error={show("description", description)}
          >
            {(p) => <Textarea {...p} value={description} rows={2} onChange={(e) => setDescription(e.target.value)} />}
          </FormField>
          <div className="grid gap-4 sm:grid-cols-2">
            <FormField id="item-price" label={`Price (₹ ${UNIT_LABEL[unit]})`} error={show("price", price)}>
              {(p) => <Input {...p} className="tabular" inputMode="decimal" value={price} placeholder="15" onChange={(e) => setPrice(e.target.value)} />}
            </FormField>
            <FormField
              id="item-offer"
              label="Offer price (₹, optional)"
              hint="Shown instead of the price, with the price struck through."
              error={show("offer", offer)}
            >
              {(p) => <Input {...p} className="tabular" inputMode="decimal" value={offer} onChange={(e) => setOffer(e.target.value)} />}
            </FormField>
          </div>
          <FormField id="item-image" label="Image (optional)" error={show("imageUrl", imageUrl)}>
            {(p) => (
              <ImageUpload {...p} purpose="catalog" aspect="square" value={imageUrl} onChange={setImageUrl} alt={trimmedName ? `Photo of ${trimmedName}` : "Item photo"} />
            )}
          </FormField>
          <FormField
            id="item-sort"
            label="Sort order"
            hint="Lower numbers appear first within the category."
            error={show("sortOrder", sortOrder)}
          >
            {(p) => (
              <Input
                {...p}
                className="tabular w-28"
                inputMode="numeric"
                value={sortOrder}
                onChange={(e) => {
                  setSortOrder(e.target.value);
                  setSortEdited(true);
                }}
              />
            )}
          </FormField>
          <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
            <div className="grid gap-0.5">
              <Label htmlFor="item-active">Show to customers</Label>
              <p className="text-xs text-muted-foreground">When off, customers cannot book this item.</p>
            </div>
            <Switch id="item-active" checked={isActive} onCheckedChange={setIsActive} />
          </div>
        </form>
        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button type="submit" form="item-form" disabled={save.isPending}>
            {editing ? "Save item" : "Add item"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
