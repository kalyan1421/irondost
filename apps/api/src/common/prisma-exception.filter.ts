import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus, Logger } from '@nestjs/common';
import type { Response } from 'express';
import { Prisma } from '../generated/prisma/client.js';

/** Maps Prisma's known request errors to HTTP responses instead of a 500. */
@Catch(Prisma.PrismaClientKnownRequestError)
export class PrismaExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(error: Prisma.PrismaClientKnownRequestError, host: ArgumentsHost): void {
    const res = host.switchToHttp().getResponse<Response>();
    switch (error.code) {
      case 'P2002':
        res.status(HttpStatus.CONFLICT).json({
          statusCode: HttpStatus.CONFLICT,
          code: 'ALREADY_EXISTS',
          message: 'A record with these details already exists',
          details: { target: error.meta?.target },
        });
        return;
      case 'P2025':
        res.status(HttpStatus.NOT_FOUND).json({
          statusCode: HttpStatus.NOT_FOUND,
          code: 'NOT_FOUND',
          message: 'Record not found',
        });
        return;
      case 'P2003':
        res.status(HttpStatus.CONFLICT).json({
          statusCode: HttpStatus.CONFLICT,
          code: 'IN_USE',
          message: 'This record is referenced by other data',
        });
        return;
      default:
        this.logger.error(error);
        res.status(HttpStatus.INTERNAL_SERVER_ERROR).json({
          statusCode: HttpStatus.INTERNAL_SERVER_ERROR,
          code: 'INTERNAL',
          message: 'Unexpected database error',
        });
    }
  }
}
