"use client";
import { useQueryClient } from '@tanstack/react-query';
import { useRouter } from 'next/navigation';
import { useEffect, useState } from 'react';
import { io } from 'socket.io-client';
import { toast } from 'sonner';
import { Button } from '@/components/ui/button';
import { API_URL, getToken } from '@/lib/api/client';
import { useAuth } from '@/lib/auth/auth-provider';

const OPERATIONAL_QUERIES = ['orders', 'order', 'dashboard', 'drivers', 'notifications', 'issues', 'issue'];

export function RealtimeBridge() {
  const { state } = useAuth(); const queryClient = useQueryClient(); const router = useRouter();
  const [connection, setConnection] = useState<'connecting' | 'connected' | 'disconnected'>('connecting');
  const [refreshing, setRefreshing] = useState(false);
  const signedIn = state.status === 'signedIn';
  async function refresh() {
    setRefreshing(true);
    await queryClient.invalidateQueries({ predicate: (q) => OPERATIONAL_QUERIES.includes(String(q.queryKey[0])) });
    setRefreshing(false);
  }
  useEffect(() => {
    if (!signedIn) return;
    const socket = io(API_URL, { path: '/v1/realtime', transports: ['websocket'], auth: (cb) => { void getToken().then((token) => cb({ token })); } });
    let connectedBefore = false;
    socket.on('connect', () => {
      setConnection('connected');
      // Only a reconnect can have missed updates; the first connect follows a fresh page load.
      if (connectedBefore) void queryClient.invalidateQueries({ predicate: (q) => OPERATIONAL_QUERIES.includes(String(q.queryKey[0])) });
      connectedBefore = true;
    });
    socket.on('disconnect', () => setConnection('disconnected'));
    socket.on('connect_error', () => setConnection('disconnected'));
    socket.on('order.updated', (e: { orderId: string; orderNumber?: string; reason: string }) => {
      for (const key of [['orders'], ['order', e.orderId], ['dashboard'], ['notifications']]) void queryClient.invalidateQueries({ queryKey: key });
      if (e.reason === 'created' && e.orderNumber) toast.info(`New order ${e.orderNumber}`, { action: { label: 'Open', onClick: () => router.push(`/orders/${e.orderId}`) } });
    });
    socket.on('issue.updated', (e: { issueId: string }) => {
      for (const key of [['issues'], ['issue', e.issueId], ['dashboard'], ['notifications']]) void queryClient.invalidateQueries({ queryKey: key });
    });
    return () => { socket.disconnect(); };
  }, [signedIn, queryClient, router]);
  if (!signedIn) return null;
  return <div className="flex flex-wrap items-center justify-between gap-2 border-b px-4 py-1 text-xs text-muted-foreground md:px-6">
    <span role="status">{connection === 'connected' ? 'Live updates connected' : connection === 'connecting' ? 'Connecting live updates…' : 'Live updates disconnected. Information may be out of date.'}</span>
    <Button variant="ghost" size="sm" disabled={refreshing} onClick={() => void refresh()}>{refreshing ? 'Refreshing…' : 'Refresh data'}</Button>
  </div>;
}
