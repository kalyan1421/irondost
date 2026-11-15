"use client";

import { keepPreviousData, useQuery } from "@tanstack/react-query";
import { AlertTriangle, ArrowDownLeft, Download, Search, Undo2 } from "lucide-react";
import Link from "next/link";
import { usePathname, useRouter, useSearchParams } from "next/navigation";
import { Suspense, useEffect, useState } from "react";
import { EmptyState, ErrorState, PageBody, PageHeader, Pager, TableSkeleton } from "@/components/page";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Skeleton } from "@/components/ui/skeleton";
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from "@/components/ui/table";
import { useDebounced } from "@/hooks/use-debounced";
import { api, unwrap } from "@/lib/api/client";
import { downloadFile, type DownloadedFile } from "@/lib/api/download";
import { useApiMutation } from "@/lib/api/mutation";
import type { LedgerEntry, LedgerKind, LedgerMethod, LedgerStatus, LedgerStatusFilter, LedgerTotals } from "@/lib/api/types";
import { dateTime, phone, rupees } from "@/lib/format";
import { cn } from "@/lib/utils";

const PAGE_SIZE = 25;
/** The most entries one export holds (the API's limit). */
const EXPORT_LIMIT = 10_000;
const ANY = "any";

const KINDS: { value: LedgerKind; label: string }[] = [
  { value: "PAYMENT", label: "Payments" },
  { value: "REFUND", label: "Refunds" },
];

const STATUSES: { value: LedgerStatusFilter; label: string }[] = [
  { value: "problem", label: "Needs attention" },
  { value: "PENDING", label: "Pending refunds" },
  { value: "FAILED", label: "Failed" },
  { value: "CAPTURED", label: "Paid" },
  { value: "PROCESSED", label: "Refunded" },
  { value: "CREATED", label: "Checkout started" },
];

const METHODS: { value: LedgerMethod; label: string }[] = [
  { value: "RAZORPAY", label: "Razorpay" },
  { value: "CASH", label: "Cash" },
  { value: "BANK_TRANSFER", label: "Bank transfer / UPI" },
];

const METHOD_LABEL = Object.fromEntries(METHODS.map((m) => [m.value, m.label])) as Record<LedgerMethod, string>;

const STATUS_META: Record<LedgerStatus, { label: string; className: string }> = {
  CREATED: {
    label: "Started",
    className: "bg-zinc-100 text-zinc-700 ring-zinc-500/20 dark:bg-zinc-400/10 dark:text-zinc-400 dark:ring-zinc-400/20",
  },
  CAPTURED: {
    label: "Paid",
    className: "bg-emerald-100 text-emerald-900 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-300 dark:ring-emerald-400/20",
  },
  FAILED: {
    label: "Failed",
    className: "bg-red-100 text-red-900 ring-red-600/20 dark:bg-red-400/10 dark:text-red-300 dark:ring-red-400/20",
  },
  REFUNDED: {
    label: "Refunded",
    className: "bg-zinc-100 text-zinc-700 ring-zinc-500/20 dark:bg-zinc-400/10 dark:text-zinc-400 dark:ring-zinc-400/20",
  },
  PENDING: {
    label: "Pending",
    className: "bg-amber-100 text-amber-900 ring-amber-600/20 dark:bg-amber-400/10 dark:text-amber-300 dark:ring-amber-400/20",
  },
  PROCESSED: {
    label: "Refunded",
    className: "bg-emerald-100 text-emerald-900 ring-emerald-600/20 dark:bg-emerald-400/10 dark:text-emerald-300 dark:ring-emerald-400/20",
  },
};

const IS_DATE = /^\d{4}-\d{2}-\d{2}$/;

/** A value from the address bar, or nothing when it is not one of the allowed ones (a hand-edited link). */
function oneOf<T extends string>(value: string | null, allowed: readonly { value: T }[]): T | undefined {
  return allowed.find((a) => a.value === value)?.value;
}

function StatusBadge({ status }: { status: LedgerStatus }) {
  const meta = STATUS_META[status];
  return (
    <span className={cn("inline-flex items-center whitespace-nowrap rounded-full px-2 py-0.5 text-xs font-medium ring-1 ring-inset", meta.className)}>
      {meta.label}
    </span>
  );
}

function PaymentsLedger() {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();

  const kind = oneOf(params.get("kind"), KINDS);
  const status = oneOf(params.get("status"), STATUSES);
  const method = oneOf(params.get("method"), METHODS);
  const from = IS_DATE.test(params.get("from") ?? "") ? (params.get("from") as string) : "";
  const to = IS_DATE.test(params.get("to") ?? "") ? (params.get("to") as string) : "";
  const page = Number(params.get("page") ?? "1") || 1;
  const [search, setSearch] = useState(params.get("q") ?? "");
  const q = useDebounced(search.trim(), 300);

  function update(next: Record<string, string | null>) {
    const sp = new URLSearchParams(params.toString());
    for (const [key, value] of Object.entries(next)) {
      if (value === null || value === "") sp.delete(key);
      else sp.set(key, value);
    }
    if (!("page" in next)) sp.delete("page");
    router.replace(`${pathname}?${sp.toString()}`, { scroll: false });
  }

  useEffect(() => {
    if ((params.get("q") ?? "") !== q) update({ q: q || null });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  /** What the list and the export are both narrowed by. */
  const filters = {
    ...(kind ? { kind } : {}),
    ...(status ? { status } : {}),
    ...(method ? { method } : {}),
    ...(from ? { from } : {}),
    ...(to ? { to } : {}),
    ...(q ? { search: q } : {}),
  };
  const filtered = Object.keys(filters).length > 0;
  const needsAttention = status === "problem";

  const query = { page, pageSize: PAGE_SIZE, ...filters };
  const ledger = useQuery({
    queryKey: ["ledger", query],
    queryFn: () => unwrap(api.GET("/v1/admin/ledger", { params: { query } })),
    placeholderData: keepPreviousData,
    refetchInterval: 60_000,
  });

  // The filters go in as the mutation's variable, so the file always matches what the button was showing when clicked.
  const exportCsv = useApiMutation<typeof filters, DownloadedFile>((narrowedBy) => downloadFile("/v1/admin/ledger/export", narrowedBy, "payments-ledger.csv"), {
    success: (file) =>
      file.truncated
        ? `Saved ${file.filename} with the newest ${EXPORT_LIMIT.toLocaleString("en-IN")} entries. Narrow the dates to get the rest.`
        : `Saved ${file.filename}`,
  });

  const total = ledger.data?.total ?? 0;

  return (
    <>
      <PageHeader
        title="Payments"
        description="Every payment and refund, newest first."
        actions={
          <Button variant="outline" disabled={exportCsv.isPending || total === 0} onClick={() => exportCsv.mutate(filters)}>
            <Download /> {exportCsv.isPending ? "Exporting…" : "Export CSV"}
          </Button>
        }
      />
      <PageBody className="gap-4">
        <div className="flex flex-wrap items-end gap-3">
          <div className="relative min-w-56 flex-1 sm:max-w-xs">
            <Search className="pointer-events-none absolute left-2.5 top-1/2 size-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              aria-label="Search payments"
              placeholder="Order number or phone"
              className="pl-8"
              maxLength={60}
              value={search}
              onChange={(e) => setSearch(e.target.value)}
            />
          </div>
          <div className="grid gap-1">
            <Label htmlFor="ledger-kind" className="text-xs text-muted-foreground">Type</Label>
            <Select value={kind ?? ANY} onValueChange={(v) => update({ kind: v === ANY ? null : v })}>
              <SelectTrigger id="ledger-kind" className="w-36">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ANY}>All types</SelectItem>
                {KINDS.map((k) => (
                  <SelectItem key={k.value} value={k.value}>{k.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-1">
            <Label htmlFor="ledger-status" className="text-xs text-muted-foreground">Status</Label>
            <Select value={status ?? ANY} onValueChange={(v) => update({ status: v === ANY ? null : v })}>
              <SelectTrigger id="ledger-status" className="w-44">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ANY}>All statuses</SelectItem>
                {STATUSES.map((s) => (
                  <SelectItem key={s.value} value={s.value}>{s.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-1">
            <Label htmlFor="ledger-method" className="text-xs text-muted-foreground">Method</Label>
            <Select value={method ?? ANY} onValueChange={(v) => update({ method: v === ANY ? null : v })}>
              <SelectTrigger id="ledger-method" className="w-44">
                <SelectValue />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={ANY}>All methods</SelectItem>
                {METHODS.map((m) => (
                  <SelectItem key={m.value} value={m.value}>{m.label}</SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>
          <div className="grid gap-1">
            <Label htmlFor="ledger-from" className="text-xs text-muted-foreground">From</Label>
            <Input id="ledger-from" type="date" className="w-40" value={from} max={to || undefined} onChange={(e) => update({ from: e.target.value })} />
          </div>
          <div className="grid gap-1">
            <Label htmlFor="ledger-to" className="text-xs text-muted-foreground">To</Label>
            <Input id="ledger-to" type="date" className="w-40" value={to} min={from || undefined} onChange={(e) => update({ to: e.target.value })} />
          </div>
          <Button
            variant={needsAttention ? "default" : "outline"}
            aria-pressed={needsAttention}
            onClick={() => update({ status: needsAttention ? null : "problem" })}
          >
            <AlertTriangle /> Needs attention
          </Button>
          {filtered ? (
            <Button
              variant="ghost"
              onClick={() => {
                setSearch("");
                router.replace(pathname);
              }}
            >
              Clear filters
            </Button>
          ) : null}
        </div>

        {ledger.isError ? (
          <ErrorState error={ledger.error} onRetry={() => void ledger.refetch()} />
        ) : !ledger.data ? (
          <>
            <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
              {Array.from({ length: 4 }, (_, i) => (
                <Skeleton key={i} className="h-20" />
              ))}
            </div>
            <TableSkeleton />
          </>
        ) : (
          <>
            <Totals totals={ledger.data.totals} total={ledger.data.total} />
            {ledger.data.items.length === 0 && ledger.data.total > 0 ? (
              <EmptyState
                title="Nothing on this page"
                description="There are fewer entries than this page number reaches."
                action={<Button variant="outline" onClick={() => update({ page: null })}>Go to the first page</Button>}
              />
            ) : ledger.data.items.length === 0 ? (
              <EmptyState
                icon={needsAttention ? undefined : Search}
                title={needsAttention ? "Nothing needs attention" : filtered ? "No payments or refunds match these filters" : "No payments yet"}
                description={
                  needsAttention
                    ? "No payment or refund is pending or failed for these filters."
                    : filtered
                      ? "Try a different search, or clear the filters."
                      : "Payments and refunds appear here as customers pay and staff refund."
                }
              />
            ) : (
              <div className={cn("rounded-lg border bg-card transition-opacity", ledger.isPlaceholderData && "opacity-60")}>
                <LedgerTable items={ledger.data.items} />
              </div>
            )}
            {ledger.data.items.length > 0 ? <Pager page={ledger.data.page} pageSize={ledger.data.pageSize} total={ledger.data.total} onPage={(p) => update({ page: String(p) })} /> : null}
          </>
        )}
      </PageBody>
    </>
  );
}

/** Counts and sums over every entry the filters match, not only this page. */
function Totals({ totals, total }: { totals: LedgerTotals; total: number }) {
  const entries = (n: number) => `${n.toLocaleString("en-IN")} ${n === 1 ? "entry" : "entries"}`;
  const items = [
    { label: "Collected", bucket: totals.captured, detail: (n: number) => `${n.toLocaleString("en-IN")} ${n === 1 ? "payment" : "payments"}`, tone: "" },
    { label: "Refunded", bucket: totals.refunded, detail: (n: number) => `${n.toLocaleString("en-IN")} ${n === 1 ? "refund" : "refunds"}`, tone: "" },
    {
      label: "Refund pending",
      bucket: totals.refundPending,
      detail: (n: number) => `${n.toLocaleString("en-IN")} ${n === 1 ? "refund" : "refunds"}`,
      tone: totals.refundPending.count > 0 ? "text-amber-700 dark:text-amber-300" : "",
    },
    { label: "Failed", bucket: totals.failed, detail: entries, tone: totals.failed.count > 0 ? "text-red-700 dark:text-red-300" : "" },
  ];
  return (
    <section aria-label="Totals" className="grid gap-2">
      <div className="grid grid-cols-2 gap-3 xl:grid-cols-4">
        {items.map((item) => (
          <div key={item.label} className="flex min-w-0 flex-col gap-1 rounded-lg border bg-card p-3 sm:p-4">
            <span className="text-xs font-medium text-muted-foreground">{item.label}</span>
            <span className={cn("tabular break-words text-xl font-semibold tracking-tight sm:text-2xl", item.tone)}>{rupees(item.bucket.amountPaise)}</span>
            <span className="tabular text-xs text-muted-foreground">{item.detail(item.bucket.count)}</span>
          </div>
        ))}
      </div>
      <p className="text-xs text-muted-foreground">
        Totals cover all {entries(total)} that match, not only this page.
        {total > EXPORT_LIMIT ? ` An export holds the newest ${EXPORT_LIMIT.toLocaleString("en-IN")}; narrow the dates to export the rest.` : ""}
      </p>
    </section>
  );
}

function LedgerTable({ items }: { items: LedgerEntry[] }) {
  return (
    <Table>
      <TableHeader>
        <TableRow>
          <TableHead>Time</TableHead>
          <TableHead>Type</TableHead>
          <TableHead>Order</TableHead>
          <TableHead>Customer</TableHead>
          <TableHead>Method</TableHead>
          <TableHead className="text-right">Amount</TableHead>
          <TableHead>Status</TableHead>
          <TableHead>Reference</TableHead>
        </TableRow>
      </TableHeader>
      <TableBody>
        {items.map((e) => {
          const refund = e.kind === "REFUND";
          // No money moved for a checkout that was only started, or an entry that failed.
          const noMoney = e.status === "CREATED" || e.status === "FAILED";
          return (
            <TableRow key={`${e.kind}-${e.id}`}>
              <TableCell className="whitespace-nowrap text-sm">{dateTime(e.occurredAt)}</TableCell>
              <TableCell>
                <span className="inline-flex items-center gap-1.5 whitespace-nowrap text-sm">
                  {refund ? <Undo2 className="size-3.5 text-muted-foreground" /> : <ArrowDownLeft className="size-3.5 text-muted-foreground" />}
                  {refund ? "Refund" : "Payment"}
                </span>
              </TableCell>
              <TableCell>
                <Link href={`/orders/${e.orderId}`} className="font-mono font-medium hover:underline">
                  {e.orderNumber}
                </Link>
              </TableCell>
              <TableCell>
                <div className="font-medium">{e.customerName ?? "—"}</div>
                {e.customerPhone ? <div className="text-xs text-muted-foreground">{phone(e.customerPhone)}</div> : null}
              </TableCell>
              <TableCell className="whitespace-nowrap text-sm">{METHOD_LABEL[e.method]}</TableCell>
              <TableCell className={cn("tabular whitespace-nowrap text-right font-medium", noMoney && "text-muted-foreground line-through")}>
                {refund ? "−" : ""}
                {rupees(e.amountPaise)}
              </TableCell>
              <TableCell>
                <StatusBadge status={e.status} />
              </TableCell>
              <TableCell className="max-w-64 whitespace-normal">
                {e.reference ? <span className="break-all font-mono text-xs">{e.reference}</span> : <span className="text-muted-foreground">—</span>}
                {e.failureReason ? <div className="text-xs text-red-700 dark:text-red-300">{e.failureReason}</div> : null}
                {e.note ? (
                  <div className="line-clamp-2 text-xs text-muted-foreground" title={e.note}>
                    {e.note}
                  </div>
                ) : null}
              </TableCell>
            </TableRow>
          );
        })}
      </TableBody>
    </Table>
  );
}

export default function PaymentsPage() {
  return (
    <Suspense>
      <PaymentsLedger />
    </Suspense>
  );
}
