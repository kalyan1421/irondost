import { createParamDecorator, ExecutionContext, SetMetadata } from '@nestjs/common';
import type { Request } from 'express';
import type { User } from '../generated/prisma/client.js';
import type { Role } from '../generated/prisma/enums.js';
import type { VerifiedIdentity } from './token-verifier.js';

export const IS_PUBLIC = 'auth:public';
export const ALLOW_UNREGISTERED = 'auth:allow-unregistered';
export const ROLES = 'auth:roles';

/** No token required. */
export const Public = () => SetMetadata(IS_PUBLIC, true);

/** A valid token is required, but the caller may not have a user record yet. */
export const AllowUnregistered = () => SetMetadata(ALLOW_UNREGISTERED, true);

/** Restricts a route (or controller) to these roles. */
export const Roles = (...roles: Role[]) => SetMetadata(ROLES, roles);

export interface AuthedRequest extends Request {
  identity?: VerifiedIdentity;
  user?: User;
}

/** The signed-in user's database record. */
export const CurrentUser = createParamDecorator((_: unknown, ctx: ExecutionContext): User => {
  const req = ctx.switchToHttp().getRequest<AuthedRequest>();
  if (!req.user) throw new Error('CurrentUser used on a route without a registered user');
  return req.user;
});

/** The verified token identity (available even before the user is registered). */
export const CurrentIdentity = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): VerifiedIdentity => {
    const req = ctx.switchToHttp().getRequest<AuthedRequest>();
    if (!req.identity) throw new Error('CurrentIdentity used on a public route');
    return req.identity;
  },
);
