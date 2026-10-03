/** "https://cdn.example.com/a.png" passes; http links and bare hosts do not (the API rejects them). */
export function isHttpsUrl(value: string): boolean {
  try {
    const url = new URL(value);
    return url.protocol === "https:" && url.hostname.includes(".");
  } catch {
    return false;
  }
}

/** A whole number typed by a person (up to 6 digits), or null. */
export function wholeNumber(value: string): number | null {
  const v = value.trim();
  return /^\d{1,6}$/.test(v) ? Number(v) : null;
}

/**
 * An image link the API accepts: any https:// URL, or a file uploaded to this
 * API (plain http://localhost/... on a development machine).
 */
export function isImageUrl(value: string): boolean {
  const apiUploads = `${(process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000").replace(/\/$/, "")}/uploads/`;
  return isHttpsUrl(value) || value.startsWith(apiUploads);
}
