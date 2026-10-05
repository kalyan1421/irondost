import { createServer, type IncomingMessage, type Server } from 'node:http';
import type { AddressInfo } from 'node:net';
import { parseEnv } from '../config/env.js';
import { S3FileStorage } from './file-storage.js';

describe('S3FileStorage with an S3-compatible endpoint (Supabase Storage)', () => {
  let server: Server;
  let received: IncomingMessage | undefined;
  let endpoint: string;

  beforeAll(async () => {
    server = createServer((req, res) => {
      received = req;
      req.resume();
      req.on('end', () => res.writeHead(200).end());
    });
    await new Promise<void>((done) => server.listen(0, '127.0.0.1', done));
    endpoint = `http://127.0.0.1:${(server.address() as AddressInfo).port}/storage/v1/s3`;
  });

  afterAll(() => server.close());

  it('puts the file under /<bucket>/<key> on that endpoint, without default checksum headers', async () => {
    process.env.AWS_ACCESS_KEY_ID = 'test-key';
    process.env.AWS_SECRET_ACCESS_KEY = 'test-secret';
    const env = parseEnv({
      DATABASE_URL: 'postgresql://x',
      STORAGE_DRIVER: 's3',
      S3_BUCKET: 'irondost-uploads',
      S3_REGION: 'ap-southeast-1',
      S3_ENDPOINT: endpoint,
      STORAGE_PUBLIC_BASE_URL: 'https://ref.supabase.co/storage/v1/object/public/irondost-uploads',
    });
    const storage = new S3FileStorage(env);

    await storage.put('banner/2026/10/a.webp', Buffer.from('img'), 'image/webp');

    expect(received?.method).toBe('PUT');
    expect(new URL(received?.url ?? '', endpoint).pathname).toBe('/storage/v1/s3/irondost-uploads/banner/2026/10/a.webp');
    expect(received?.headers['cache-control']).toBe('public, max-age=31536000, immutable');
    expect(received?.headers['x-amz-sdk-checksum-algorithm']).toBeUndefined();
    expect(storage.publicUrl('banner/2026/10/a.webp')).toBe(
      'https://ref.supabase.co/storage/v1/object/public/irondost-uploads/banner/2026/10/a.webp',
    );
  });
});
