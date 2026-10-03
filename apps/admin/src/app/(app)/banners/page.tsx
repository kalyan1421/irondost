"use client";

import { useQuery } from "@tanstack/react-query";
import { GalleryHorizontalEnd, Info, Link2, Pencil, Plus, Trash2 } from "lucide-react";
import { useState } from "react";
import { ConfirmDialog } from "@/components/confirm-dialog";
import { EmptyState, ErrorState, PageBody, PageHeader } from "@/components/page";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { Card } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Skeleton } from "@/components/ui/skeleton";
import { Switch } from "@/components/ui/switch";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import type { Banner } from "@/lib/api/types";
import { cn } from "@/lib/utils";
import { BannerDialog } from "./_components/banner-dialog";
import { BannerImage } from "./_components/banner-image";

type DialogState = { banner?: Banner } | null;

export default function BannersPage() {
  const banners = useQuery({
    queryKey: ["banners"],
    queryFn: () => unwrap(api.GET("/v1/admin/banners")),
  });
  const [dialog, setDialog] = useState<DialogState>(null);
  const nextSortOrder = (banners.data ?? []).reduce((n, b) => Math.max(n, b.sortOrder + 1), 0);

  return (
    <>
      <PageHeader
        title="Banners"
        description="Promotional images at the top of the customer app home screen."
        actions={
          <Button onClick={() => setDialog({})}>
            <Plus /> Add banner
          </Button>
        }
      />
      <PageBody className="gap-5">
        <Alert>
          <Info />
          <AlertTitle>How banners appear</AlertTitle>
          <AlertDescription>
            Active banners are shown on the customer app home screen in sort order, lowest number first.
          </AlertDescription>
        </Alert>

        {banners.isError ? (
          <ErrorState error={banners.error} onRetry={() => void banners.refetch()} />
        ) : !banners.data ? (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {Array.from({ length: 3 }, (_, i) => (
              <Skeleton key={i} className="aspect-[4/3] w-full rounded-xl" />
            ))}
          </div>
        ) : banners.data.length === 0 ? (
          <EmptyState
            icon={GalleryHorizontalEnd}
            title="No banners yet"
            description="Banners appear here and on the customer app home screen. Add the first one with Add banner."
            action={
              <Button onClick={() => setDialog({})}>
                <Plus /> Add banner
              </Button>
            }
          />
        ) : (
          <div className="grid gap-4 sm:grid-cols-2 xl:grid-cols-3">
            {banners.data.map((b) => (
              <BannerCard key={b.id} banner={b} onEdit={() => setDialog({ banner: b })} />
            ))}
          </div>
        )}
      </PageBody>
      {dialog ? <BannerDialog banner={dialog.banner} nextSortOrder={nextSortOrder} onClose={() => setDialog(null)} /> : null}
    </>
  );
}

function BannerCard({ banner: b, onEdit }: { banner: Banner; onEdit: () => void }) {
  const name = b.title ?? "Untitled banner";

  const toggle = useApiMutation(
    (isActive: boolean) =>
      unwrap(
        api.PATCH("/v1/admin/banners/{id}", {
          params: { path: { id: b.id } },
          body: { isActive },
        }),
      ),
    {
      invalidate: [["banners"]],
      success: (r) => (r.isActive ? `${name} is now shown in the app` : `${name} is now hidden from the app`),
    },
  );

  const remove = useApiMutation(() => unwrap(api.DELETE("/v1/admin/banners/{id}", { params: { path: { id: b.id } } })), {
    invalidate: [["banners"]],
    success: `${name} deleted`,
  });

  return (
    <Card className="gap-0 py-0">
      <BannerImage src={b.imageUrl} alt={b.title ? `Banner: ${b.title}` : "Banner image"} className={cn(!b.isActive && "opacity-60")} />
      <div className="grid gap-3 p-4">
        <div className="flex items-start justify-between gap-3">
          <div className="min-w-0">
            <div className={cn("truncate font-medium", !b.title && "text-muted-foreground")}>{name}</div>
            <div className="mt-0.5 flex min-w-0 items-center gap-1 text-xs text-muted-foreground">
              <Link2 className="size-3 shrink-0" aria-hidden />
              {b.linkUrl ? (
                <span className="truncate" title={b.linkUrl}>
                  <span className="sr-only">Opens </span>
                  {b.linkUrl}
                </span>
              ) : (
                <span>No link: tapping does nothing</span>
              )}
            </div>
          </div>
          <span className="tabular shrink-0 rounded-md bg-muted px-1.5 py-0.5 text-xs text-muted-foreground">Sort order {b.sortOrder}</span>
        </div>
        <div className="flex items-center justify-between gap-2 border-t pt-3">
          <div className="flex items-center gap-2">
            <Switch
              id={`banner-active-${b.id}`}
              checked={b.isActive}
              disabled={toggle.isPending}
              onCheckedChange={(v) => toggle.mutate(v)}
            />
            <Label htmlFor={`banner-active-${b.id}`} className="font-normal">
              Show in the app<span className="sr-only">: {name}</span>
            </Label>
          </div>
          <div className="flex gap-1">
            <Button size="icon-sm" variant="ghost" aria-label={`Edit ${name}`} onClick={onEdit}>
              <Pencil />
            </Button>
            <ConfirmDialog
              destructive
              title="Delete this banner?"
              confirmLabel="Delete banner"
              description="It is removed from the customer app home screen straight away. This cannot be undone. To hide it for now instead, turn off Show in the app."
              trigger={
                <Button size="icon-sm" variant="ghost" aria-label={`Delete ${name}`}>
                  <Trash2 />
                </Button>
              }
              onConfirm={() => remove.mutateAsync(undefined)}
            />
          </div>
        </div>
      </div>
    </Card>
  );
}
