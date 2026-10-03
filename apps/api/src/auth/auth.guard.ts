import { CanActivate, ExecutionContext, HttpStatus, Injectable, UnauthorizedException } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AppError } from '../common/errors.js';
import type { Role } from '../generated/prisma/enums.js';
import { PrismaService } from '../prisma/prisma.service.js';
import { ALLOW_UNREGISTERED, IS_PUBLIC, ROLES, type AuthedRequest } from './decorators.js';
import { TokenVerifier } from './token-verifier.js';

/**
 * Global guard: every route needs a valid token unless marked @Public().
 * Loads the caller's user record and enforces @Roles().
 */
@Injectable()
export class AuthGuard implements CanActivate {
  constructor(
    private readonly reflector: Reflector,
    private readonly verifier: TokenVerifier,
    private readonly prisma: PrismaService,
  ) {}

  async canActivate(ctx: ExecutionContext): Promise<boolean> {
    if (ctx.getType() !== 'http') return true;
    const targets = [ctx.getHandler(), ctx.getClass()];
    if (this.reflector.getAllAndOverride<boolean>(IS_PUBLIC, targets)) return true;

    const req = ctx.switchToHttp().getRequest<AuthedRequest>();
    const header = req.headers.authorization ?? '';
    const [scheme, token] = header.split(' ');
    if (scheme !== 'Bearer' || !token) throw new UnauthorizedException('Missing bearer token');

    req.identity = await this.verifier.verify(token);

    const user = await this.prisma.user.findUnique({ where: { firebaseUid: req.identity.uid } });
    if (!user) {
      if (this.reflector.getAllAndOverride<boolean>(ALLOW_UNREGISTERED, targets)) return true;
      throw new AppError(HttpStatus.UNAUTHORIZED, 'SESSION_REQUIRED', 'Call POST /v1/auth/session first');
    }
    if (!user.isActive || user.deletedAt) {
      throw AppError.forbidden('ACCOUNT_DISABLED', 'This account is disabled');
    }
    req.user = user;

    const roles = this.reflector.getAllAndOverride<Role[] | undefined>(ROLES, targets);
    if (roles && !roles.includes(user.role)) {
      throw AppError.forbidden('FORBIDDEN_ROLE', 'You do not have access to this resource');
    }
    return true;
  }
}
