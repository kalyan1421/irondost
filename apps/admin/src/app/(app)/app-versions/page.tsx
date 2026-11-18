"use client";

import { useQuery } from "@tanstack/react-query";
import { Smartphone } from "lucide-react";
import { useState } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, TableSkeleton } from "@/components/page";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { api, unwrap } from "@/lib/api/client";
import { useApiMutation } from "@/lib/api/mutation";
import { useAuth } from "@/lib/auth/auth-provider";

type Platform = "ANDROID" | "IOS";
const PLATFORMS: { key: Platform; label: string }[] = [
  { key: "IOS", label: "iPhone (App Store)" },
  { key: "ANDROID", label: "Android (Google Play)" },
];
const SEMVER = /^\d+\.\d+\.\d+$/;

interface VersionData {
  minVersion: string;
  latestVersion: string;
  storeUrl: string | null;
  message: string | null;
}

export default function AppVersionsPage() {
  const { isSuperAdmin } = useAuth();

  if (!isSuperAdmin) {
    return (
      <>
        <PageHeader title="App versions" />
        <PageBody>
          <EmptyState
            icon={Smartphone}
            title="Only super admins can set app versions"
            description="This is how an old version of the customer app is told to update."
          />
        </PageBody>
      </>
    );
  }

  return (
    <>
      <PageHeader
        title="App versions"
        description="Customers on a version below the minimum must update before they can use the app. Below the latest, they are only offered the update."
      />
      <PageBody className="grid gap-6 lg:grid-cols-2">
        {PLATFORMS.map((p) => (
          <VersionCard key={p.key} platform={p.key} label={p.label} />
        ))}
      </PageBody>
    </>
  );
}

function VersionCard({ platform, label }: { platform: Platform; label: string }) {
  const current = useQuery({
    queryKey: ["app-version", "CUSTOMER", platform],
    // The API answers null (an empty body) when nothing is set for this platform yet.
    queryFn: async (): Promise<VersionData | null> => {
      const data = (await unwrap(api.GET("/v1/app-versions", { params: { query: { app: "CUSTOMER", platform } } }))) as Partial<VersionData> | null | undefined;
      return data?.minVersion ? (data as VersionData) : null;
    },
  });

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base">{label}</CardTitle>
      </CardHeader>
      <CardContent>
        {current.isError ? (
          <ErrorState error={current.error} onRetry={() => void current.refetch()} />
        ) : current.data === undefined ? (
          <TableSkeleton rows={3} />
        ) : (
          <VersionForm
            platform={platform}
            initial={current.data}
            // A new key per saved value keeps the form in step with what the server holds.
            key={JSON.stringify(current.data)}
          />
        )}
      </CardContent>
    </Card>
  );
}

function VersionForm({
  platform,
  initial,
}: {
  platform: Platform;
  initial: VersionData | null;
}) {
  const [minVersion, setMin] = useState(initial?.minVersion ?? "");
  const [latestVersion, setLatest] = useState(initial?.latestVersion ?? "");
  const [storeUrl, setStoreUrl] = useState(initial?.storeUrl ?? "");
  const [message, setMessage] = useState(initial?.message ?? "");
  const [error, setError] = useState<string | null>(null);

  const save = useApiMutation(
    () =>
      unwrap(
        api.PUT("/v1/app-versions", {
          body: {
            app: "CUSTOMER",
            platform,
            minVersion: minVersion.trim(),
            latestVersion: latestVersion.trim(),
            ...(storeUrl.trim() ? { storeUrl: storeUrl.trim() } : {}),
            ...(message.trim() ? { message: message.trim() } : {}),
          },
        }),
      ),
    { invalidate: [["app-version", "CUSTOMER", platform]], success: "Saved. The app reads this on its next launch." },
  );

  function submit() {
    if (!SEMVER.test(minVersion.trim()) || !SEMVER.test(latestVersion.trim())) {
      setError("Versions look like 2.0.0 (three numbers).");
      return;
    }
    if (storeUrl.trim() && !storeUrl.trim().startsWith("https://")) {
      setError("The store link must start with https://");
      return;
    }
    setError(null);
    save.mutate(undefined);
  }

  const id = (name: string) => `${platform}-${name}`;
  return (
    <form
      className="grid gap-4"
      onSubmit={(e) => {
        e.preventDefault();
        submit();
      }}
    >
      {initial === null ? (
        <p className="text-sm text-muted-foreground">Nothing is set yet, so no one is asked to update.</p>
      ) : null}
      <div className="grid gap-4 sm:grid-cols-2">
        <div className="grid gap-1.5">
          <Label htmlFor={id("min")}>Minimum version</Label>
          <Input id={id("min")} placeholder="2.0.0" value={minVersion} onChange={(e) => setMin(e.target.value)} />
        </div>
        <div className="grid gap-1.5">
          <Label htmlFor={id("latest")}>Latest version</Label>
          <Input id={id("latest")} placeholder="2.0.0" value={latestVersion} onChange={(e) => setLatest(e.target.value)} />
        </div>
      </div>
      <div className="grid gap-1.5">
        <Label htmlFor={id("url")}>Store link</Label>
        <Input id={id("url")} placeholder="https://apps.apple.com/…" value={storeUrl} onChange={(e) => setStoreUrl(e.target.value)} />
      </div>
      <div className="grid gap-1.5">
        <Label htmlFor={id("msg")}>Message (optional)</Label>
        <Input id={id("msg")} maxLength={300} placeholder="Shown on the update screen" value={message} onChange={(e) => setMessage(e.target.value)} />
      </div>
      {error ? <p className="text-sm text-destructive">{error}</p> : null}
      <div>
        <Button type="submit" disabled={save.isPending}>
          {save.isPending ? "Saving…" : "Save"}
        </Button>
      </div>
    </form>
  );
}
