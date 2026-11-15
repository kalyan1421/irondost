"use client";
import { keepPreviousData, useQuery } from '@tanstack/react-query';
import Link from 'next/link';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';
import { Suspense } from 'react';
import { EmptyState, ErrorState, PageBody, PageHeader, Pager, TableSkeleton } from '@/components/page';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { api, unwrap } from '@/lib/api/client';
import { useAuth } from '@/lib/auth/auth-provider';
import { dateTime, relativeTime } from '@/lib/format';
import type { components } from '@/lib/api/schema';

type Status = components['schemas']['IssueStatus'];
const labels: Record<Status, string> = { OPEN: 'New', ACKNOWLEDGED: 'In progress', RESOLVED: 'Resolved', REJECTED: 'Closed with an explanation' };
function Reports() {
  const params = useSearchParams(); const router = useRouter(); const path = usePathname(); const { user } = useAuth();
  const status = (params.get('status') ?? 'OPEN') as Status | 'all';
  const page = Number(params.get('page') ?? 1) || 1;
  const overdue = params.get('overdue') === '1';
  const mine = params.get('mine') === '1';
  const search = params.get('q') ?? '';
  function change(values: Record<string, string | null>) {
    const next = new URLSearchParams(params.toString());
    for (const [key, value] of Object.entries(values)) { if (value === null || value === '') next.delete(key); else next.set(key, value); }
    if (!('page' in values)) next.delete('page');
    router.replace(`${path}?${next}`, { scroll: false });
  }
  const query = { page, pageSize: 25, ...(status !== 'all' ? { status } : {}), ...(overdue ? { overdue: true } : {}),
    ...(mine && user ? { handledById: user.id } : {}), ...(search ? { search } : {}) };
  const reports = useQuery({ queryKey: ['issues', query], queryFn: () => unwrap(api.GET('/v1/admin/issues', { params: { query } })), placeholderData: keepPreviousData, refetchInterval: 30_000 });
  return <><PageHeader title="Customer reports" description="Review problems, own the response, and record how they were resolved." />
    <PageBody>
      <div className="flex flex-wrap items-end gap-3">
        <div className="grid gap-1"><Label htmlFor="report-status">Status</Label><Select value={status} onValueChange={(v) => change({ status: v, overdue: null })}>
          <SelectTrigger id="report-status" className="w-56"><SelectValue /></SelectTrigger><SelectContent>
            {Object.entries(labels).map(([value, label]) => <SelectItem key={value} value={value}>{label}</SelectItem>)}<SelectItem value="all">All reports</SelectItem>
          </SelectContent></Select></div>
        <form className="grid gap-1" onSubmit={(e) => { e.preventDefault(); change({ q: String(new FormData(e.currentTarget).get('q') ?? '') }); }}>
          <Label htmlFor="report-search">Order number</Label><div className="flex gap-2"><Input id="report-search" name="q" defaultValue={search} placeholder="Search order number" /><Button variant="outline">Search</Button></div>
        </form>
        <Button variant={overdue ? 'default' : 'outline'} aria-pressed={overdue} onClick={() => change({ overdue: overdue ? null : '1', status: 'OPEN' })}>Response overdue</Button>
        <Button variant={mine ? 'default' : 'outline'} aria-pressed={mine} onClick={() => change({ mine: mine ? null : '1' })}>Assigned to me</Button>
        <Button variant="ghost" onClick={() => void reports.refetch()}>Refresh</Button>
      </div>
      <p role="status" className="text-sm text-muted-foreground">{reports.isFetching ? 'Updating reports…' : 'Reports refresh every 30 seconds. A response target appears only when configured.'}</p>
      {reports.isError ? <ErrorState error={reports.error} onRetry={() => void reports.refetch()} /> : !reports.data ? <TableSkeleton /> : reports.data.items.length === 0
        ? <EmptyState title="No reports match these filters" description="Try another status or clear the assignment and overdue filters." />
        : <div className="rounded-lg border bg-card"><Table><TableHeader><TableRow><TableHead>Report</TableHead><TableHead>Order</TableHead><TableHead>Problem</TableHead><TableHead>Status</TableHead><TableHead>Received</TableHead><TableHead>First response target</TableHead></TableRow></TableHeader>
          <TableBody>{reports.data.items.map((report) => <TableRow key={report.id}>
            <TableCell><Link className="font-mono underline underline-offset-4" href={`/issues/${report.id}`}>{report.id.slice(0, 8)}</Link></TableCell>
            <TableCell><Link className="underline underline-offset-4" href={`/orders/${report.orderId}`}>{report.orderNumber}</Link></TableCell>
            <TableCell>{report.category.toLowerCase().replaceAll('_', ' ')}</TableCell><TableCell>{labels[report.status]}</TableCell><TableCell>{relativeTime(report.createdAt)}</TableCell>
            <TableCell>{report.acknowledgedAt ? `Seen ${dateTime(report.acknowledgedAt)}` : report.firstResponseDueAt ? dateTime(report.firstResponseDueAt) : 'No public deadline'}</TableCell>
          </TableRow>)}</TableBody></Table></div>}
      {reports.data ? <Pager page={page} pageSize={25} total={reports.data.total} onPage={(p) => change({ page: String(p) })} /> : null}
    </PageBody></>;
}
export default function IssuesPage() { return <Suspense><Reports /></Suspense>; }
