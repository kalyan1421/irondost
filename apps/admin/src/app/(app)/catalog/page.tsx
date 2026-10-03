"use client";

import { useQuery } from "@tanstack/react-query";
import { FolderPlus, Info, Plus, Shirt } from "lucide-react";
import { useState } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, TableSkeleton } from "@/components/page";
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert";
import { Button } from "@/components/ui/button";
import { api, unwrap } from "@/lib/api/client";
import type { CatalogCategory, CatalogItem } from "@/lib/api/types";
import { CategoryCard } from "./_components/category-card";
import { CategoryDialog } from "./_components/category-dialog";
import { ItemDialog } from "./_components/item-dialog";

type DialogState =
  | { kind: "category"; category?: CatalogCategory }
  | { kind: "item"; item?: CatalogItem; categoryId?: string }
  | null;

export default function CatalogPage() {
  const catalog = useQuery({
    queryKey: ["catalog", "admin"],
    queryFn: () => unwrap(api.GET("/v1/admin/catalog")),
  });
  const [dialog, setDialog] = useState<DialogState>(null);
  const close = () => setDialog(null);

  const categories = catalog.data ?? [];
  const nextCategorySort = categories.reduce((n, c) => Math.max(n, c.sortOrder + 1), 0);

  return (
    <>
      <PageHeader
        title="Services & prices"
        description="The categories and items customers can book, and what each one costs."
        actions={
          catalog.data ? (
            <>
              <Button variant="outline" onClick={() => setDialog({ kind: "category" })}>
                <FolderPlus /> Add category
              </Button>
              {categories.length > 0 ? (
                <Button onClick={() => setDialog({ kind: "item" })}>
                  <Plus /> Add item
                </Button>
              ) : null}
            </>
          ) : null
        }
      />
      <PageBody className="gap-5">
        <Alert>
          <Info />
          <AlertTitle>What customers see</AlertTitle>
          <AlertDescription>
            Customers see only active categories and active items. Price changes apply to new orders only; orders already placed keep the
            prices they were booked at.
          </AlertDescription>
        </Alert>

        {catalog.isError ? (
          <ErrorState error={catalog.error} onRetry={() => void catalog.refetch()} />
        ) : !catalog.data ? (
          <TableSkeleton rows={8} />
        ) : categories.length === 0 ? (
          <EmptyState
            icon={Shirt}
            title="No categories yet"
            description="Categories such as Ironing or Wash & Iron appear here with their items and prices. Add the first category, then add items to it."
            action={
              <Button onClick={() => setDialog({ kind: "category" })}>
                <FolderPlus /> Add category
              </Button>
            }
          />
        ) : (
          categories.map((c) => (
            <CategoryCard
              key={c.id}
              category={c}
              onEdit={() => setDialog({ kind: "category", category: c })}
              onAddItem={() => setDialog({ kind: "item", categoryId: c.id })}
              onEditItem={(item) => setDialog({ kind: "item", item })}
            />
          ))
        )}
      </PageBody>

      {dialog?.kind === "category" ? (
        <CategoryDialog category={dialog.category} nextSortOrder={nextCategorySort} onClose={close} />
      ) : null}
      {dialog?.kind === "item" ? (
        <ItemDialog categories={categories} item={dialog.item} categoryId={dialog.categoryId} onClose={close} />
      ) : null}
    </>
  );
}
