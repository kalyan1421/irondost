import { afterEach, beforeEach, vi } from 'vitest';
import type { Env } from '../config/env.js';
import type { PrismaService } from '../prisma/prisma.service.js';
import { KeepAliveService } from './keep-alive.service.js';

function setup(overrides: Partial<Env> = {}) {
  const upsert = vi.fn().mockResolvedValue({});
  const prisma = { serviceHeartbeat: { upsert } } as unknown as PrismaService;
  const env = {
    KEEP_ALIVE_INTERVAL_MINUTES: 10,
    KEEP_ALIVE_URLS: [],
    RENDER_EXTERNAL_URL: 'https://irondost-api.onrender.com/',
    ...overrides,
  } as Env;
  return { service: new KeepAliveService(prisma, env), upsert };
}

describe('KeepAliveService', () => {
  const fetchMock = vi.fn();

  beforeEach(() => {
    vi.useFakeTimers();
    fetchMock.mockReset().mockResolvedValue({ ok: true, status: 200 });
    vi.stubGlobal('fetch', fetchMock);
  });

  afterEach(() => {
    vi.useRealTimers();
    vi.unstubAllGlobals();
  });

  it('does nothing when the interval is 0', async () => {
    const { service, upsert } = setup({ KEEP_ALIVE_INTERVAL_MINUTES: 0 });
    service.onApplicationBootstrap();
    await vi.advanceTimersByTimeAsync(60 * 60_000);
    expect(upsert).not.toHaveBeenCalled();
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it('writes the heartbeat and requests its own address and the extra ones, once each', async () => {
    const { service, upsert } = setup({
      KEEP_ALIVE_URLS: ['https://irondost-admin.onrender.com/login', 'https://irondost-api.onrender.com/v1/health'],
    });
    await service.beat();
    expect(upsert).toHaveBeenCalledTimes(1);
    expect(upsert.mock.calls[0]![0]).toMatchObject({ where: { service: 'api' }, update: { beats: { increment: 1 } } });
    expect(fetchMock.mock.calls.map((c) => c[0])).toEqual([
      'https://irondost-api.onrender.com/v1/health',
      'https://irondost-admin.onrender.com/login',
    ]);
  });

  it('beats on start and then every interval, and stops on shutdown', async () => {
    const { service, upsert } = setup();
    service.onApplicationBootstrap();
    await vi.advanceTimersByTimeAsync(0);
    expect(upsert).toHaveBeenCalledTimes(1);
    await vi.advanceTimersByTimeAsync(10 * 60_000);
    expect(upsert).toHaveBeenCalledTimes(2);
    await vi.advanceTimersByTimeAsync(10 * 60_000);
    expect(upsert).toHaveBeenCalledTimes(3);
    service.onApplicationShutdown();
    await vi.advanceTimersByTimeAsync(30 * 60_000);
    expect(upsert).toHaveBeenCalledTimes(3);
  });

  it('still requests the addresses when the database write fails, and never throws', async () => {
    const { service, upsert } = setup();
    upsert.mockRejectedValue(new Error('relation does not exist'));
    await expect(service.beat()).resolves.toBeUndefined();
    expect(fetchMock).toHaveBeenCalledTimes(1);
  });

  it('still writes the heartbeat when an address is unreachable, and never throws', async () => {
    const { service, upsert } = setup({ KEEP_ALIVE_URLS: ['https://irondost-admin.onrender.com/login'] });
    fetchMock.mockRejectedValueOnce(new Error('timeout'));
    await expect(service.beat()).resolves.toBeUndefined();
    expect(upsert).toHaveBeenCalledTimes(1);
    expect(fetchMock).toHaveBeenCalledTimes(2);
  });

  it('skips a beat while the previous one is still waiting', async () => {
    const { service, upsert } = setup();
    let release: (value: unknown) => void = () => undefined;
    fetchMock.mockReturnValueOnce(new Promise((resolve) => (release = resolve)));
    const first = service.beat();
    await service.beat();
    expect(upsert).toHaveBeenCalledTimes(1);
    release({ ok: true, status: 200 });
    await first;
    await service.beat();
    expect(upsert).toHaveBeenCalledTimes(2);
  });

  it('has no own address to request outside Render', async () => {
    const { service } = setup({ RENDER_EXTERNAL_URL: '' });
    await service.beat();
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
