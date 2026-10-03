import createClient from "openapi-fetch";
import type { paths } from "./schema";

export const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:4000";

/** Typed client generated from packages/contracts/openapi.json (`pnpm gen:api`). */
export const api = createClient<paths>({ baseUrl: API_URL });

let tokenProvider: () => Promise<string | null> = async () => null;

/** The auth provider registers how to get the current token (Firebase ID token or dev token). */
export function setTokenProvider(fn: () => Promise<string | null>): void {
  tokenProvider = fn;
}

export function getToken(): Promise<string | null> {
  return tokenProvider();
}

api.use({
  async onRequest({ request }) {
    const token = await tokenProvider();
    if (token) request.headers.set("Authorization", `Bearer ${token}`);
    return request;
  },
});

/** Error body the API returns: { statusCode, code, message, details? }. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super(message);
  }

  static from(status: number, body: unknown): ApiError {
    const b = (body ?? {}) as { code?: string; message?: string | string[]; details?: Record<string, unknown> };
    // Validation errors arrive as an array of messages.
    const message = Array.isArray(b.message) ? b.message.join(". ") : (b.message ?? `Request failed (${status})`);
    return new ApiError(status, b.code ?? `HTTP_${status}`, message, b.details);
  }
}

/** Unwraps an openapi-fetch result, throwing ApiError on failure. */
export async function unwrap<T>(
  call: Promise<{ data?: T; error?: unknown; response: Response }>,
): Promise<T> {
  let result: { data?: T; error?: unknown; response: Response };
  try {
    result = await call;
  } catch {
    throw new ApiError(0, "NETWORK", "Cannot reach the server. Check your connection.");
  }
  if (!result.response.ok) throw ApiError.from(result.response.status, result.error);
  return result.data as T;
}

export function errorMessage(err: unknown): string {
  if (err instanceof ApiError) return err.message;
  if (err instanceof Error) return err.message;
  return "Something went wrong";
}

/** Re-throws an API error with a clearer message for the error codes listed. */
export async function explainErrors<T>(call: Promise<T>, messages: Record<string, string>): Promise<T> {
  try {
    return await call;
  } catch (err) {
    if (err instanceof ApiError && messages[err.code]) {
      throw new ApiError(err.status, err.code, messages[err.code], err.details);
    }
    throw err;
  }
}
