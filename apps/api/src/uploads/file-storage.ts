import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import type { Env } from '../config/env.js';

/** Where uploaded files live. Keys look like `banner/2026/10/<uuid>.webp`. */
export abstract class FileStorage {
  abstract put(key: string, body: Buffer, contentType: string): Promise<void>;

  constructor(protected readonly publicBaseUrl: string) {}

  publicUrl(key: string): string {
    return `${this.publicBaseUrl.replace(/\/$/, '')}/${key}`;
  }
}

/** Development: files on disk, served by the API at /uploads. */
export class LocalFileStorage extends FileStorage {
  private readonly root: string;

  constructor(env: Env) {
    super(env.STORAGE_PUBLIC_BASE_URL);
    this.root = resolve(env.STORAGE_LOCAL_DIR);
  }

  async put(key: string, body: Buffer): Promise<void> {
    const path = resolve(this.root, key);
    if (!path.startsWith(this.root)) throw new Error('Invalid storage key');
    await mkdir(dirname(path), { recursive: true });
    await writeFile(path, body);
  }
}

/** Production: Supabase Storage, a public bucket served from the project's CDN. Files never change, so cache them for a year. */
export class SupabaseFileStorage extends FileStorage {
  private readonly objectsUrl: string;
  private readonly secretKey: string;

  constructor(env: Env) {
    super(env.STORAGE_PUBLIC_BASE_URL);
    this.objectsUrl = `${env.SUPABASE_URL.replace(/\/$/, '')}/storage/v1/object/${env.SUPABASE_STORAGE_BUCKET}`;
    this.secretKey = env.SUPABASE_SERVICE_ROLE_KEY;
  }

  async put(key: string, body: Buffer, contentType: string): Promise<void> {
    const path = key.split('/').map(encodeURIComponent).join('/');
    const res = await fetch(`${this.objectsUrl}/${path}`, {
      method: 'POST',
      headers: {
        // Both headers, as the Supabase clients send them: newer secret keys are not JWTs and only work as `apikey`.
        apikey: this.secretKey,
        Authorization: `Bearer ${this.secretKey}`,
        'Content-Type': contentType,
        'Cache-Control': 'max-age=31536000',
      },
      body: new Uint8Array(body),
    });
    if (!res.ok) {
      throw new Error(`Supabase Storage rejected the upload (${res.status}): ${(await res.text()).slice(0, 200)}`);
    }
  }
}

export function createFileStorage(env: Env): FileStorage {
  return env.STORAGE_DRIVER === 'supabase' ? new SupabaseFileStorage(env) : new LocalFileStorage(env);
}
