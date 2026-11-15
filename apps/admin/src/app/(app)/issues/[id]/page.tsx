"use client";
import { useQuery } from '@tanstack/react-query';
import Image from 'next/image';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { useState } from 'react';
import { ErrorState, PageBody, PageHeader, TableSkeleton } from '@/components/page';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card';
import { Label } from '@/components/ui/label';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Textarea } from '@/components/ui/textarea';
import { api, unwrap } from '@/lib/api/client';
import { useApiMutation } from '@/lib/api/mutation';
import { useAuth } from '@/lib/auth/auth-provider';
import type { components } from '@/lib/api/schema';
import { dateTime, rupees } from '@/lib/format';
import { Input } from '@/components/ui/input';
import { useDraftText, useUnsavedChanges } from '@/hooks/use-unsaved-changes';

type Status = components['schemas']['IssueStatus'];
const labels: Record<Status, string> = { OPEN: 'New', ACKNOWLEDGED: 'In progress', RESOLVED: 'Resolved', REJECTED: 'Closed with an explanation' };
export default function IssueDetailPage() {
  const { id } = useParams<{ id: string }>(); const { user } = useAuth();
  const report = useQuery({ queryKey: ['issue', id], queryFn: () => unwrap(api.GET('/v1/admin/issues/{id}', { params: { path: { id } } })), refetchInterval: 30_000 });
  const [reply, setReply] = useDraftText(`irondost.report.reply.${user?.id}.${id}`);
  const [note, setNote] = useDraftText(`irondost.report.resolution.${user?.id}.${id}`);
  const [nextStatus, setNextStatus] = useState<Status | null>(null);
  const [remedy, setRemedy] = useState('');
  const [refundChoice, setRefundChoice] = useState('none');
  useUnsavedChanges(Boolean(reply || note || nextStatus || remedy || refundChoice !== 'none'));
  const invalidate = [['issue', id], ['issues'], ['dashboard'], ['notifications']];
  const send = useApiMutation(() => unwrap(api.POST('/v1/admin/issues/{id}/messages', { params: { path: { id } }, body: { body: reply.trim() } })), {
    invalidate, success: 'Reply sent', onSuccess: () => setReply(''),
  });
  const update = useApiMutation((body: components['schemas']['UpdateIssueDto']) => unwrap(api.PATCH('/v1/admin/issues/{id}', { params: { path: { id } }, body })), {
    invalidate, success: 'Report updated', onSuccess: () => { setNote(''); setNextStatus(null); setRemedy(''); setRefundChoice('none'); },
  });
  const issue = report.data; const status = nextStatus ?? issue?.status;
  const closing = status === 'RESOLVED' || status === 'REJECTED';
  // The refunds already made on this order, so the remedy can point at the one that paid it out.
  const order = useQuery({ queryKey: ['order', issue?.orderId], queryFn: () => unwrap(api.GET('/v1/admin/orders/{id}', { params: { path: { id: issue!.orderId } } })), enabled: Boolean(issue) });
  const remedyPaise = remedy.trim() === '' ? null : Math.round(Number(remedy) * 100);
  const remedyInvalid = remedyPaise !== null && (!Number.isFinite(remedyPaise) || remedyPaise < 0 || remedyPaise > 10_000_000);
  const linked = order.data?.refunds?.find((r) => r.id === refundChoice);
  const remedyTooSmall = Boolean(linked) && remedyPaise !== null && linked!.amountPaise > remedyPaise;
  const busy = send.isPending || update.isPending;
  return <><PageHeader title="Report details" back={<Link href="/issues" className="text-sm underline">Customer reports</Link>}
    actions={issue ? <Button asChild variant="outline"><Link href={`/orders/${issue.orderId}`}>Open order & payments</Link></Button> : null} />
    <PageBody>{report.isError ? <ErrorState error={report.error} onRetry={() => void report.refetch()} /> : !issue ? <TableSkeleton /> : <>
      <Card><CardHeader><CardTitle>{issue.orderNumber} · {issue.category.toLowerCase().replaceAll('_', ' ')}</CardTitle></CardHeader><CardContent className="grid gap-3">
        <p className="break-all font-mono text-xs text-muted-foreground">Report {issue.id}</p><p className="font-medium">{labels[issue.status]}</p><p className="whitespace-pre-wrap">{issue.description}</p>
        <p className="text-sm text-muted-foreground">Received {dateTime(issue.createdAt)} · {issue.firstResponseDueAt ? `First response target ${dateTime(issue.firstResponseDueAt)}` : 'No public reply deadline has been promised.'}</p>
        <div className="flex flex-wrap items-center gap-3"><span className="text-sm">{issue.handledById === user?.id ? 'Assigned to you' : issue.handledById ? 'Assigned to another staff member' : 'Unassigned'}</span>
          <Button variant="outline" disabled={busy || issue.handledById === user?.id || !user} onClick={() => update.mutate({ handledById: user!.id })}>Assign to me</Button>
          {issue.handledById ? <Button variant="ghost" disabled={busy} onClick={() => update.mutate({ handledById: null })}>Unassign</Button> : null}</div>
        <div className="grid gap-3 sm:grid-cols-2">{issue.photoUrls.map((url, index) => <a key={url} href={url} target="_blank" rel="noreferrer" className="rounded-md border p-2"><Image unoptimized src={url} alt={`Customer garment evidence ${index + 1}; open full image`} width={800} height={800} className="max-h-64 w-full object-contain" /></a>)}</div>
      </CardContent></Card>
      <Card><CardHeader><CardTitle>Conversation</CardTitle></CardHeader><CardContent className="grid gap-4">
        {issue.messages.length === 0 ? <p className="text-muted-foreground">No replies yet.</p> : issue.messages.map((m) => <article key={m.id} className="grid gap-1 border-b pb-3"><p className="font-medium">{m.fromStaff ? 'IronDost team' : 'Customer'} <span className="text-xs font-normal text-muted-foreground">{dateTime(m.createdAt)}</span></p><p className="whitespace-pre-wrap break-words">{m.body}</p></article>)}
        {issue.status === 'OPEN' || issue.status === 'ACKNOWLEDGED' ? <form className="grid gap-2" onSubmit={(e) => { e.preventDefault(); if (reply.trim() && !busy) send.mutate(undefined); }}>
          <Label htmlFor="issue-reply">Reply to the customer</Label><Textarea id="issue-reply" maxLength={2000} rows={4} value={reply} disabled={busy} onChange={(e) => setReply(e.target.value)} />
          {send.isError ? <p role="alert" className="text-sm text-destructive">Reply was not confirmed. Your text is kept; retry or refresh the conversation.</p> : null}
          <Button className="justify-self-start" disabled={!reply.trim() || busy}>{send.isPending ? 'Sending…' : 'Send reply'}</Button>
        </form> : <p>Conversation closed. Reopen the report to continue.</p>}
      </CardContent></Card>
      <Card><CardHeader><CardTitle>Status and resolution</CardTitle></CardHeader><CardContent className="grid max-w-2xl gap-3">
        {issue.resolutionNote ? <p className="whitespace-pre-wrap">Recorded resolution: {issue.resolutionNote}</p> : null}
        {issue.compensationPaise != null ? <p>Agreed remedy: {issue.compensationPaise > 0 ? rupees(issue.compensationPaise) : 'no payout'}{issue.refundId ? ' · linked to a refund on the order' : ''}</p> : null}
        <Label htmlFor="issue-next-status">Status</Label><Select value={status} onValueChange={(v) => setNextStatus(v as Status)} disabled={busy}><SelectTrigger id="issue-next-status"><SelectValue /></SelectTrigger><SelectContent>{Object.entries(labels).map(([key, label]) => <SelectItem key={key} value={key}>{label}</SelectItem>)}</SelectContent></Select>
        <Label htmlFor="issue-resolution">Resolution shown to the customer {closing ? '(required)' : '(when closing)'}</Label><Textarea id="issue-resolution" maxLength={2000} rows={3} value={note} disabled={busy} onChange={(e) => setNote(e.target.value)} placeholder="Explain what was checked and the agreed remedy. Record any refund from the order's Payments panel." />
        {status === 'RESOLVED' ? <div className="grid gap-3 rounded-md border p-3">
          <Label htmlFor="issue-remedy">Agreed remedy in rupees (optional)</Label>
          <Input id="issue-remedy" inputMode="decimal" placeholder={issue.compensationPaise != null ? String(issue.compensationPaise / 100) : 'e.g. 50'} value={remedy} disabled={busy} onChange={(e) => setRemedy(e.target.value)} aria-invalid={remedyInvalid || remedyTooSmall} />
          <Label htmlFor="issue-refund">Refund that pays it</Label>
          <Select value={refundChoice} onValueChange={setRefundChoice} disabled={busy || order.isError}><SelectTrigger id="issue-refund"><SelectValue /></SelectTrigger><SelectContent>
            <SelectItem value="none">No refund linked</SelectItem>
            {order.data?.refunds?.map((r) => <SelectItem key={r.id} value={r.id}>{rupees(r.amountPaise)} · {r.method.toLowerCase().replaceAll('_', ' ')} · {r.status.toLowerCase()}</SelectItem>)}
          </SelectContent></Select>
          <p className="text-sm text-muted-foreground">Make the refund first from the order&apos;s Payments panel, then link it here. Without a linked refund the amount is only a record of what was agreed.</p>
          {remedyInvalid ? <p role="alert" className="text-sm text-destructive">Enter an amount from 0 to 1,00,000.</p> : null}
          {remedyTooSmall ? <p role="alert" className="text-sm text-destructive">The linked refund ({rupees(linked!.amountPaise)}) is larger than the agreed remedy.</p> : null}
        </div> : null}
        <Button className="justify-self-start" disabled={busy || remedyInvalid || remedyTooSmall || (closing && (note.trim() || issue.resolutionNote || '').length < 3)}
          onClick={() => update.mutate({ status, ...(note.trim() ? { resolutionNote: note.trim() } : {}),
            ...(status === 'RESOLVED' && remedyPaise !== null ? { compensationPaise: remedyPaise } : {}),
            ...(status === 'RESOLVED' && refundChoice !== 'none' ? { refundId: refundChoice } : {}) })}>{update.isPending ? 'Saving…' : 'Save status'}</Button>
      </CardContent></Card>
    </>}</PageBody></>;
}
