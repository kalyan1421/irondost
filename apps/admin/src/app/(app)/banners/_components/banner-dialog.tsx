"use client";

import { useState } from "react";
import { Button } from "@/components/ui/button";
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { components } from "@/lib/api/schema";
import type { Banner } from "@/lib/api/types";
import { FormField } from "@/components/form-field";
import { ImageUpload } from "@/components/image-upload";
import { isImageUrl, wholeNumber } from "@/lib/validation";

type UpdateBannerBody = components["schemas"]["UpdateBannerDto"];
/**
 * The API clears title and link when it receives null, but the generated
 * UpdateBannerDto only allows strings there. Drop this once the contract says `| null`.
 */


export function BannerDialog({
  banner,
  nextSortOrder,
  onClose,
}: {
  banner?: Banner;
  nextSortOrder: number;
  onClose: () => void;
}) {
  const editing = Boolean(banner);
  const [imageUrl, setImageUrl] = useState(banner?.imageUrl ?? "");
  const [title, setTitle] = useState(banner?.title ?? "");
  const [linkUrl, setLinkUrl] = useState(banner?.linkUrl ?? "");
  const [sortOrder, setSortOrder] = useState(String(banner?.sortOrder ?? nextSortOrder));
  const [isActive, setIsActive] = useState(banner?.isActive ?? true);
  const [submitted, setSubmitted] = useState(false);

  const trimmedImage = imageUrl.trim();
  const trimmedTitle = title.trim();
  const trimmedLink = linkUrl.trim();
  const sort = wholeNumber(sortOrder);

  const errors = {
    imageUrl: !trimmedImage
      ? "Add the banner image."
      : !isImageUrl(trimmedImage)
        ? "Upload an image, or paste a link that starts with https://"
        : null,
    title: trimmedTitle.length > 80 ? "Keep the title to 80 characters or fewer." : null,
    linkUrl: trimmedLink.length > 300 ? "Keep the link to 300 characters or fewer." : null,
    sortOrder: sort === null ? "Enter a whole number, 0 or more." : null,
  };
  const valid = Object.values(errors).every((e) => !e);
  const show = (field: keyof typeof errors, raw: string) => (submitted || raw !== "" ? errors[field] : null);

  const save = useApiMutation(
    () => {
      const common = { imageUrl: trimmedImage, sortOrder: sort ?? 0, isActive };
      return unwrap(
        banner
          ? api.PATCH("/v1/admin/banners/{id}", {
              params: { path: { id: banner.id } },
              body: {
                ...common,
                title: trimmedTitle || null,
                linkUrl: trimmedLink || null,
              } satisfies UpdateBannerBody,
            })
          : api.POST("/v1/admin/banners", {
              body: { ...common, title: trimmedTitle || undefined, linkUrl: trimmedLink || undefined },
            }),
      );
    },
    {
      invalidate: [["banners"]],
      success: editing ? "Banner saved" : "Banner added",
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
          <DialogTitle>{editing ? "Edit banner" : "Add banner"}</DialogTitle>
          <DialogDescription>Shown on the customer app home screen, in sort order.</DialogDescription>
        </DialogHeader>
        <form id="banner-form" className="-mx-1 grid max-h-[65vh] gap-4 overflow-y-auto px-1 py-0.5" onSubmit={submit} noValidate>
          <FormField id="banner-image" label="Banner image" error={show("imageUrl", imageUrl)}>
            {(p) => (
              <ImageUpload
                {...p}
                purpose="banner"
                aspect="wide"
                required
                value={imageUrl}
                onChange={setImageUrl}
                alt={trimmedTitle ? `Banner: ${trimmedTitle}` : "Banner image"}
              />
            )}
          </FormField>
          <FormField id="banner-title" label="Title (optional)" hint="A short name for the banner, such as the offer it promotes." error={show("title", title)}>
            {(p) => <Input {...p} value={title} maxLength={80} placeholder="e.g. Diwali offer: 20% off" onChange={(e) => setTitle(e.target.value)} />}
          </FormField>
          <FormField
            id="banner-link"
            label="Link when tapped (optional)"
            hint="An app deep link or a web address. Leave empty if tapping should do nothing."
            error={show("linkUrl", linkUrl)}
          >
            {(p) => <Input {...p} value={linkUrl} maxLength={300} spellCheck={false} onChange={(e) => setLinkUrl(e.target.value)} />}
          </FormField>
          <FormField id="banner-sort" label="Sort order" hint="Lower numbers appear first." error={show("sortOrder", sortOrder)}>
            {(p) => <Input {...p} className="tabular w-28" inputMode="numeric" value={sortOrder} onChange={(e) => setSortOrder(e.target.value)} />}
          </FormField>
          <div className="flex items-start justify-between gap-4 rounded-lg border p-3">
            <div className="grid gap-0.5">
              <Label htmlFor="banner-active">Show in the app</Label>
              <p className="text-xs text-muted-foreground">When off, the banner is kept here but hidden from customers.</p>
            </div>
            <Switch id="banner-active" checked={isActive} onCheckedChange={setIsActive} />
          </div>
        </form>
        <DialogFooter>
          <Button variant="ghost" onClick={onClose}>
            Close
          </Button>
          <Button type="submit" form="banner-form" disabled={save.isPending}>
            {editing ? "Save banner" : "Add banner"}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
