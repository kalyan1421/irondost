import { API_URL, ApiError, getToken } from "./client";

export interface DownloadedFile {
  filename: string;
  /** The server left some rows out of an export that hit its size limit. */
  truncated: boolean;
}

/** `attachment; filename="payments-ledger-2026-11-15.csv"` → the name, if it is a plain file name. */
function filenameFrom(disposition: string | null): string | null {
  const name = disposition ? /filename="?([^";]+)"?/i.exec(disposition)?.[1] : null;
  return name && /^[\w.-]+$/.test(name) ? name : null;
}

/**
 * Downloads a file the API serves behind sign-in. A plain link cannot send the bearer token, so this fetches it with
 * the token, then hands the bytes to the browser to save.
 */
export async function downloadFile(
  path: string,
  query: Record<string, string | number | undefined>,
  fallbackName: string,
): Promise<DownloadedFile> {
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value !== undefined && value !== "") params.set(key, String(value));
  }
  const queryString = params.toString();
  const token = await getToken();

  let res: Response;
  try {
    res = await fetch(`${API_URL}${path}${queryString ? `?${queryString}` : ""}`, {
      headers: token ? { Authorization: `Bearer ${token}` } : undefined,
    });
  } catch {
    throw new ApiError(0, "NETWORK", "Cannot reach the server. Check your connection.");
  }
  if (!res.ok) throw ApiError.from(res.status, await res.json().catch(() => null));

  const filename = filenameFrom(res.headers.get("Content-Disposition")) ?? fallbackName;
  const url = URL.createObjectURL(await res.blob());
  const link = document.createElement("a");
  link.href = url;
  link.download = filename;
  document.body.append(link);
  link.click();
  link.remove();
  // The browser needs the URL for a moment after the click to start saving.
  setTimeout(() => URL.revokeObjectURL(url), 10_000);
  return { filename, truncated: res.headers.get("X-Export-Truncated") === "true" };
}
