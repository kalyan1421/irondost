"use client";

import { useQuery } from "@tanstack/react-query";
import { Lock } from "lucide-react";
import { ErrorState, PageBody, PageHeader } from "@/components/page";
import { Alert, AlertDescription } from "@/components/ui/alert";
import { Skeleton } from "@/components/ui/skeleton";
import { api, unwrap } from "@/lib/api/client";
import { useAuth } from "@/lib/auth/auth-provider";
import { dateTime } from "@/lib/format";
import { SettingsForm } from "./_components/settings-form";

export default function SettingsPage() {
  const { isSuperAdmin } = useAuth();
  const settings = useQuery({ queryKey: ["settings"], queryFn: () => unwrap(api.GET("/v1/admin/settings")) });

  return (
    <>
      <PageHeader
        title="Business settings"
        description={
          settings.data
            ? `Pricing, booking and dispatch rules. Last updated ${dateTime(settings.data.updatedAt)}.`
            : "Pricing, booking and dispatch rules."
        }
      />
      <PageBody>
        {!isSuperAdmin ? (
          <Alert role="note" className="max-w-4xl">
            <Lock />
            <AlertDescription>Only super admins can change these settings. You can see the current values here.</AlertDescription>
          </Alert>
        ) : null}
        {settings.isError ? (
          <ErrorState error={settings.error} onRetry={() => void settings.refetch()} />
        ) : !settings.data ? (
          <div className="grid max-w-4xl gap-6">
            {Array.from({ length: 3 }, (_, i) => (
              <Skeleton key={i} className="h-48" />
            ))}
          </div>
        ) : (
          <SettingsForm settings={settings.data} canEdit={isSuperAdmin} />
        )}
      </PageBody>
    </>
  );
}
