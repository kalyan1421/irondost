import { API_URL, ApiError, getToken } from "./client";
import type { components, paths } from "./schema";

type UploadBody = NonNullable<paths["/v1/admin/uploads/images"]["post"]["requestBody"]>["content"]["multipart/form-data"];
export type ImagePurpose = UploadBody["purpose"];
export type ImageUpload = components["schemas"]["ImageUploadDto"];

export const MAX_IMAGE_BYTES = 8 * 1024 * 1024;
export const ACCEPTED_IMAGE_TYPES = ["image/jpeg", "image/png", "image/webp", "image/avif", "image/gif"];

/**
 * Uploads an image to the API, which checks it, strips metadata, resizes it
 * for its purpose and stores it as WebP. Returns the public URL to save.
 */
export async function uploadImage(file: File, purpose: ImagePurpose): Promise<ImageUpload> {
  const form = new FormData();
  form.append("purpose", purpose);
  form.append("file", file);
  const token = await getToken();

  let res: Response;
  try {
    res = await fetch(`${API_URL}/v1/admin/uploads/images`, {
      method: "POST",
      body: form,
      headers: token ? { Authorization: `Bearer ${token}` } : undefined,
    });
  } catch {
    throw new ApiError(0, "NETWORK", "Cannot reach the server. Check your connection.");
  }
  const body: unknown = await res.json().catch(() => null);
  if (res.status === 413) throw new ApiError(413, "TOO_LARGE", "That image is larger than 8 MB.");
  if (!res.ok) throw ApiError.from(res.status, body);
  return body as ImageUpload;
}
