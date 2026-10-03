"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { CatalogCategory } from "@/lib/api/types";
import { FormField } from "@/components/form-field";
import { ImageUpload } from "@/components/image-upload";
import { explainErrors } from "@/lib/api/client";
import { isImageUrl, wholeNumber } from "@/lib/validation";

export const CATALOG_KEYS = [
  ["catalog", "admin"],
  ["catalog", "public"],
];

const SLUG = /^[a-z0-9]+(?:-[a-z0-9]+)*$/;

/** "Wash & Iron" → "wash-and-iron" */
export function slugify(name: string): string {
  return name
    .normalize("NFKD")
    .replace(/[̀-ͯ]/g, "")
    .toLowerCase()
    .replace(/&/g, " and ")
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 60)
    .replace(/-+$/, "");
}

export function CategoryDialog({
  category,
  nextSortOrder,
  onClose,
}: {
  category?: CatalogCategory;
  nextSortOrder: number;
  onClose: () => void;
}) {
  const editing = Boolean(category);
  const [name, setName] = useState(category?.name ?? "");
  const [slug, setSlug] = useState(category?.slug ?? "");
  // A new category's slug follows its name until someone edits the slug. Existing slugs never change on their own.
  const [slugEdited, setSlugEdited] = useState(editing);
  const [sortOrder, setSortOrder] = useState(String(category?.sortOrder ?? nextSortOrder));
  const [isActive, setIsActive] = useState(category?.isActive ?? true);
  const [imageUrl, setImageUrl] = useState(category?.imageUrl ?? "");
  const [submitted, setSubmitted] = useState(false);

  const trimmed = name.trim();
  const sort = wholeNumber(sortOrder);
  const errors = {
    name: trimmed.length < 2 || trimmed.length > 60 ? "Enter a name of 2 to 60 characters." : null,
    slug:
      slug.length < 2 || slug.length > 60 || !SLUG.test(slug)
        ? "Use 2 to 60 lowercase letters or digits, with hyphens between words."
        : null,
    sortOrder: sort === null ? "Enter a whole number, 0 or more." : null,
    imageUrl: imageUrl.trim() && !isImageUrl(imageUrl.trim()) ? "Upload an image, or paste a link that starts with https://" : null,
  };
  const valid = Object.values(errors).every((e) => !e);
  const show = (field: keyof typeof errors, value: string) => (submitted || value !== "" ? errors[field] : null);

  const save = useApiMutation(
    () => {
      const body = { name: trimmed, slug, sortOrder: sort ?? 0, isActive, imageUrl: imageUrl.trim() || null };
      const call = category
        ? api.PATCH("/v1/admin/catalog/categories/{id}", { params: { path: { id: category.id } }, body })
        : api.POST("/v1/admin/catalog/categories", { body });
      return explainErrors(unwrap(call), {
        ALREADY_EXISTS: `Another category already uses the slug "${slug}". Choose a different slug.`,
      });
    },
    {
      invalidate: CATALOG_KEYS,
      success: (c) => (editing ? `${c.name} saved` : `${c.name} added`),
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
      <DialogContent className="sm:max-w-md">
        <DialogHeader>
          <DialogTitle>{editing ? `Edit ${category?.name}` : "Add category"}</DialogTitle>
          <DialogDescription>
            Categories group the services customers book, such as Ironing or Wash &amp; Iron.
          </DialogDescription>
        </DialogHeader>
        <form id="category-form" className="-mx-1 grid max-h-[65vh] gap-4 overflow-y-auto px-1 py-0.5" onSubmit={submit} noValidate>
          <FormField id="category-name" label="Name" error={show("name", name)}>
            {(p) => (
              <Input
                {...p}
                value={name}
                maxLength={60}
                placeholder="e.g. Dry cleaning"
                autoFocus
                onChange={(e) => {
                  setName(e.target.value);
                  if (!slugEdited) setSlug(slugify(e.target.value));
                }}
              />
            )}
          </FormField>
          <FormField
            id="category-slug"
            label="Slug"
            hint="Used in links to this category. Lowercase letters, digits and hyphens."
            error={show("slug", slug)}
          >
            {(p) => (
              <Input
                {...p}
                className="font-mono"
                value={slug}
                maxLength={60}
                onChange={(e) => {
                  setSlug(e.target.value.toLowerCase());
                  setSlugEdited(true);
                }}
              />
            )}
          </FormField>
          <FormField
            id="category-sort"
            label="Sort order"
            hint="Lower numbers appear first in the app."
            error={show("sortOrder", sortOrder)}
          >
            {(p) => (
              <Input {...p} className="tabular w-28" inputMode="numeric" value={sortOrder} onChange={(e) => setSortOrder(e.target.value)} />
            )}
          </FormField>
          <FormField id="category-image" label="Image (optional)" error={show("imageUrl", imageUrl)}>
            {(p) => (
              <ImageUpload {...p} purpose="catalog" aspect="square" value={imageUrl} onChange={setImageUrl} alt={trimmed ? `${trimmed} category image` : "Category image"} />
            )}
          </FormField>
          <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
            <div className="grid gap-0.5">
              <Label htmlFor="category-active">Show to customers</Label>
              <p className="text-xs text-muted-foreground">When off, the category and all its items are hidden from the app.</p>
            </div>
            <Switch id="category-active" checked={isActive} onCheckedChange={setIsActive} />
          </div>
        </form>
        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button type="submit" form="category-form" disabled={save.isPending}>
            {editing ? "Save category" : "Add category"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
