import { registerDecorator, type ValidationOptions } from 'class-validator';

let uploadsBaseUrl: string | null = null;

/** Set once from the validated config, so links to our own uploads are accepted. */
export function setUploadsBaseUrl(url: string): void {
  uploadsBaseUrl = url.replace(/\/$/, '');
}

/**
 * An image link the apps can load: any https:// URL, or a file stored by our
 * own uploader (STORAGE_PUBLIC_BASE_URL, which is plain http on a dev machine).
 */
export function isImageUrl(value: unknown): boolean {
  if (typeof value !== 'string' || value.length > 2048) return false;
  if (uploadsBaseUrl && value.startsWith(`${uploadsBaseUrl}/`)) return true;
  try {
    const url = new URL(value);
    return url.protocol === 'https:' && url.hostname.includes('.');
  } catch {
    return false;
  }
}

export function IsImageUrl(options?: ValidationOptions): PropertyDecorator {
  return (target, propertyName) =>
    registerDecorator({
      name: 'isImageUrl',
      target: target.constructor,
      propertyName: String(propertyName),
      options: { message: `${String(propertyName)} must be an https:// link or an uploaded image`, ...options },
      validator: { validate: isImageUrl },
    });
}
