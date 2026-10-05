import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { PutObjectCommand, S3Client } from '@aws-sdk/client-s3';
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

/**
 * Production: S3 or an S3-compatible store such as Supabase Storage (set S3_ENDPOINT), served from STORAGE_PUBLIC_BASE_URL.
 * Files never change, so cache them for a year.
 */
export class S3FileStorage extends FileStorage {
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(env: Env) {
    super(env.STORAGE_PUBLIC_BASE_URL);
    this.client = new S3Client({
      region: env.S3_REGION,
      // S3-compatible stores address buckets by path and reject the SDK's default checksum headers.
      ...(env.S3_ENDPOINT && {
        endpoint: env.S3_ENDPOINT,
        forcePathStyle: true,
        requestChecksumCalculation: 'WHEN_REQUIRED' as const,
        responseChecksumValidation: 'WHEN_REQUIRED' as const,
      }),
    });
    this.bucket = env.S3_BUCKET;
  }

  async put(key: string, body: Buffer, contentType: string): Promise<void> {
    await this.client.send(
      new PutObjectCommand({
        Bucket: this.bucket,
        Key: key,
        Body: body,
        ContentType: contentType,
        CacheControl: 'public, max-age=31536000, immutable',
      }),
    );
  }
}

export function createFileStorage(env: Env): FileStorage {
  return env.STORAGE_DRIVER === 's3' ? new S3FileStorage(env) : new LocalFileStorage(env);
}
