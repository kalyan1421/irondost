"use client";

import { Pencil, Plus, Trash2 } from "lucide-react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { ActiveDot } from "@/components/status";
import { Button } from "@/components/ui/button";
import { Thumbnail } from "@/components/thumbnail";
import { Card, CardAction, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { Switch } from "@/components/ui/switch";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { CatalogCategory, CatalogItem } from "@/lib/api/types";
import { rupees } from "@/lib/format";
import { cn } from "@/lib/utils";
import { CATALOG_KEYS } from "./category-dialog";
import { explainErrors } from "@/lib/api/client";
import { UNIT_LABEL } from "./item-dialog";

function plural(n: number, one: string, many: string): string {
  return `${n} ${n === 1 ? one : many}`;
}

export function CategoryCard({
  category,
  onEdit,
  onAddItem,
  onEditItem,
}: {
  category: CatalogCategory;
  onEdit: () => void;
  onAddItem: () => void;
  onEditItem: (item: CatalogItem) => void;
}) {
  const items = category.items;
  const hiddenItems = items.filter((i) => !i.isActive).length;

  const remove = useApiMutation(
    () =>
      explainErrors(unwrap(api.DELETE("/v1/admin/catalog/categories/{id}", { params: { path: { id: category.id } } })), {
        CATEGORY_NOT_EMPTY: `${category.name} still has ${plural(items.length, "item", "items")}, so it cannot be deleted. Move them to another category first, or edit ${category.name} and turn off "Show to customers" to hide it.`,
      }),
    { invalidate: CATALOG_KEYS, success: `${category.name} deleted` },
  );

  return (
    <Card>
      <CardHeader className="border-b">
        <CardTitle className="flex flex-wrap items-center gap-x-3 gap-y-1">
          {category.imageUrl ? <Thumbnail src={category.imageUrl} alt={`${category.name} category image`} className="size-8" /> : null}
          <span className="text-base font-semibold">{category.name}</span>
          <span className="font-normal">
            <ActiveDot active={category.isActive} on="Shown to customers" off="Hidden from customers" />
          </span>
        </CardTitle>
        <CardDescription className="flex flex-wrap items-center gap-x-2 gap-y-0.5">
          <span className="font-mono text-xs">{category.slug}</span>
          <span aria-hidden>·</span>
          <span className="tabular">Sort order {category.sortOrder}</span>
          <span aria-hidden>·</span>
          <span className="tabular">
            {plural(items.length, "item", "items")}
            {hiddenItems > 0 ? `, ${hiddenItems} hidden` : ""}
          </span>
          {!category.isActive && items.length > 0 ? (
            <span className="basis-full text-xs">All items in this category are hidden while it is off.</span>
          ) : null}
        </CardDescription>
        <CardAction className="flex items-center gap-1">
          <Button size="sm" variant="outline" onClick={onAddItem}>
            <Plus /> Add item
          </Button>
          <Button size="icon-sm" variant="ghost" aria-label={`Edit ${category.name}`} onClick={onEdit}>
            <Pencil />
          </Button>
          <ConfirmDialog
            destructive
            title={`Delete ${category.name}?`}
            confirmLabel="Delete category"
            description={
              items.length > 0
                ? `Only an empty category can be deleted, and ${category.name} has ${plural(items.length, "item", "items")}${hiddenItems > 0 ? ", including hidden ones" : ""}. Move them to another category first, or edit it and turn off "Show to customers" to hide it.`
                : "It is removed from the app straight away. This cannot be undone."
            }
            trigger={
              <Button size="icon-sm" variant="ghost" aria-label={`Delete ${category.name}`}>
                <Trash2 />
              </Button>
            }
            onConfirm={() => remove.mutateAsync(undefined)}
          />
        </CardAction>
      </CardHeader>
      <CardContent className="px-0">
        {items.length === 0 ? (
          <p className="px-4 py-4 text-sm text-muted-foreground">
            No items yet. Use Add item to list the first thing customers can book in {category.name}.
          </p>
        ) : (
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead className="pl-4">Item</TableHead>
                <TableHead>Unit</TableHead>
                <TableHead className="text-right">Price</TableHead>
                <TableHead className="text-right">Offer price</TableHead>
                <TableHead>Active</TableHead>
                <TableHead className="pr-4 text-right">
                  <span className="sr-only">Actions</span>
                </TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {items.map((item) => (
                <ItemRow key={item.id} item={item} onEdit={() => onEditItem(item)} />
              ))}
            </TableBody>
          </Table>
        )}
      </CardContent>
    </Card>
  );
}

function ItemRow({ item, onEdit }: { item: CatalogItem; onEdit: () => void }) {
  const toggle = useApiMutation(
    (isActive: boolean) =>
      unwrap(
        api.PATCH("/v1/admin/catalog/items/{id}", {
          params: { path: { id: item.id } },
          body: { isActive },
        }),
      ),
    {
      invalidate: CATALOG_KEYS,
      success: (i) => (i.isActive ? `${i.name} is now shown to customers` : `${i.name} is now hidden from customers`),
    },
  );

  const remove = useApiMutation(
    () => unwrap(api.DELETE("/v1/admin/catalog/items/{id}", { params: { path: { id: item.id } } })),
    {
      invalidate: CATALOG_KEYS,
      success: (r) =>
        r.deleted
          ? `${item.name} deleted`
          : `${item.name} is part of past orders, so it was turned off instead of deleted. Customers no longer see it.`,
    },
  );

  const hasOffer = item.offerPricePaise !== null;

  return (
    <TableRow className={cn(!item.isActive && "text-muted-foreground")}>
      <TableCell className="max-w-80 pl-4 whitespace-normal">
        <div className="flex items-center gap-3">
          <Thumbnail src={item.imageUrl} alt={`Photo of ${item.name}`} />
          <div className="min-w-0">
            <div className={cn("font-medium", item.isActive && "text-foreground")}>{item.name}</div>
            {item.description ? <div className="line-clamp-2 text-xs text-muted-foreground">{item.description}</div> : null}
          </div>
        </div>
      </TableCell>
      <TableCell className="whitespace-nowrap">{UNIT_LABEL[item.unit]}</TableCell>
      <TableCell className="tabular text-right">
        {hasOffer ? (
          <s className="text-muted-foreground">
            <span className="sr-only">Regular price </span>
            {rupees(item.pricePaise)}
          </s>
        ) : (
          <span className="font-medium">{rupees(item.pricePaise)}</span>
        )}
      </TableCell>
      <TableCell className="tabular text-right">
        {hasOffer ? (
          <span className="font-medium">{rupees(item.effectivePricePaise)}</span>
        ) : (
          <span className="text-muted-foreground">
            —<span className="sr-only">No offer</span>
          </span>
        )}
      </TableCell>
      <TableCell>
        <Switch
          checked={item.isActive}
          disabled={toggle.isPending}
          aria-label={`Show ${item.name} to customers`}
          onCheckedChange={(v) => toggle.mutate(v)}
        />
      </TableCell>
      <TableCell className="pr-4 text-right">
        <div className="flex justify-end gap-1">
          <Button size="icon-sm" variant="ghost" aria-label={`Edit ${item.name}`} onClick={onEdit}>
            <Pencil />
          </Button>
          <ConfirmDialog
            destructive
            title={`Delete ${item.name}?`}
            confirmLabel="Delete item"
            description="If past orders include this item, it is turned off instead of deleted so those orders keep their details."
            trigger={
              <Button size="icon-sm" variant="ghost" aria-label={`Delete ${item.name}`}>
                <Trash2 />
              </Button>
            }
            onConfirm={() => remove.mutateAsync(undefined)}
          />
        </div>
      </TableCell>
    </TableRow>
  );
}
