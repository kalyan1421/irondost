import { HttpException, HttpStatus } from '@nestjs/common';

/**
 * Error with a stable machine-readable `code` that the apps can branch on.
 * Response body: { statusCode, code, message, details? }
 */
export class AppError extends HttpException {
  constructor(
    status: HttpStatus,
    readonly code: string,
    message: string,
    readonly details?: Record<string, unknown>,
  ) {
    super({ statusCode: status, code, message, ...(details ? { details } : {}) }, status);
  }

  static badRequest(code: string, message: string, details?: Record<string, unknown>): AppError {
    return new AppError(HttpStatus.BAD_REQUEST, code, message, details);
  }

  static notFound(what: string): AppError {
    return new AppError(HttpStatus.NOT_FOUND, 'NOT_FOUND', `${what} not found`);
  }

  static forbidden(code: string, message: string): AppError {
    return new AppError(HttpStatus.FORBIDDEN, code, message);
  }

  static conflict(code: string, message: string, details?: Record<string, unknown>): AppError {
    return new AppError(HttpStatus.CONFLICT, code, message, details);
  }
}
