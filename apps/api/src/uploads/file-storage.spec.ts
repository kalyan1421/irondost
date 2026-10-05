import { createServer, type IncomingMessage, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { parseEnv } from '../config/env.js';
import { createFileStorage } from './file-storage.js';

describe('Supabase Storage driver', () => {
  let server: Server;
  let baseUrl: string;
  let status = 200;
  let request: { req: IncomingMessage; body: Buffer } | undefined;

  beforeAll(async () => {
    server = createServer((req, res) => {
      const chunks: Buffer[] = [];
      req.on('data', (c: Buffer) => chunks.push(c));
      req.on('end', () => {
        request = { req, body: Buffer.concat(chunks) };
        res.writeHead(status, { 'Content-Type': 'application/json' }).end(status === 200 ? '{"Key":"ok"}' : '{"error":"Unauthorized"}');
      });
    });
    await new Promise<void>((done) => server.listen(0, '127.0.0.1', done));
    baseUrl = `http://127.0.0.1:${(server.address() as AddressInfo).port}`;
  });

  afterAll(() => server.close());

  const storage = () =>
    createFileStorage(
      parseEnv({
        DATABASE_URL: 'postgresql://x',
        STORAGE_DRIVER: 'supabase',
        SUPABASE_URL: `${baseUrl}/`,
        SUPABASE_SERVICE_ROLE_KEY: 'secret-key',
        SUPABASE_STORAGE_BUCKET: 'irondost-uploads',
      }),
    );

  it('posts the file to the bucket with the secret key and a year of caching', async () => {
    status = 200;
    await storage().put('banner/2026/10/a.webp', Buffer.from('img'), 'image/webp');

    expect(request?.req.method).toBe('POST');
    expect(request?.req.url).toBe('/storage/v1/object/irondost-uploads/banner/2026/10/a.webp');
    expect(request?.req.headers).toMatchObject({
      apikey: 'secret-key',
      authorization: 'Bearer secret-key',
      'content-type': 'image/webp',
      'cache-control': 'max-age=31536000',
    });
    expect(request?.body.toString()).toBe('img');
  });

  it('serves files from the bucket’s public URL, derived from the project URL', () => {
    expect(storage().publicUrl('banner/2026/10/a.webp')).toBe(
      `${baseUrl}/storage/v1/object/public/irondost-uploads/banner/2026/10/a.webp`,
    );
  });

  it('fails the upload when Supabase rejects it', async () => {
    status = 401;
    await expect(storage().put('banner/a.webp', Buffer.from('img'), 'image/webp')).rejects.toThrow(/401.*Unauthorized/);
  });
});

describe('storage settings', () => {
  const base = { DATABASE_URL: 'postgresql://x' };

  it('requires the Supabase settings when the supabase driver is chosen', () => {
    expect(() => parseEnv({ ...base, STORAGE_DRIVER: 'supabase' })).toThrow(
      /SUPABASE_URL.*\n.*SUPABASE_SERVICE_ROLE_KEY.*\n.*SUPABASE_STORAGE_BUCKET/,
    );
  });

  it('refuses local storage in production', () => {
    expect(() =>
      parseEnv({ ...base, NODE_ENV: 'production', FIREBASE_SERVICE_ACCOUNT_BASE64: 'x' }),
    ).toThrow(/STORAGE_DRIVER: must be supabase in production/);
  });
});
