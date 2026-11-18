import { storageUrl } from '../uploads/file-storage.js';

/** The longest care note, in characters (a CHECK in the database says the same). */
export const CARE_NOTE_MAX = 500;
/** Photos that can go with one order. */
export const CARE_PHOTOS_PER_ORDER = 3;
/** Care photos one customer can upload in a day (report photos allow 20 a day). */
export const CARE_PHOTOS_PER_DAY = 20;

/** Where a customer's care photos are stored. Nothing else is stored under this prefix. */
export const carePhotoPrefix = (userId: string): string => `care/${userId}/`;

let publicBase = '';

/**
 * Sets the public base URL of the file storage. Order responses are built by plain functions with no access to the storage
 * service, so the orders service tells this module once at start-up how to turn a stored key into a public URL.
 */
export function setCarePhotoBaseUrl(url: string): void {
  publicBase = url;
}

/** The public URL of a stored care photo. */
export function carePhotoUrl(key: string): string {
  return storageUrl(publicBase, key);
}

/** The care note as stored: trimmed, and null when there is nothing to say. */
export function careNoteOf(dto: { careNote?: string | null }): string | null {
  return dto.careNote?.trim() || null;
}

/**
 * The storage key behind a care photo URL, or null when the URL is not one of this customer's care photo URLs
 * (another account's, another kind of file, or a made-up address).
 */
export function carePhotoKey(userId: string, url: string): string | null {
  const prefix = storageUrl(publicBase, carePhotoPrefix(userId));
  const name = url.startsWith(prefix) ? url.slice(prefix.length) : '';
  return /^[0-9a-f-]{36}\.webp$/.test(name) ? `${carePhotoPrefix(userId)}${name}` : null;
}
