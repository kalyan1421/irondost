/**
 * Creates a super admin who signs in to the admin console with email + password, or resets that admin's password.
 * Idempotent; run it again with a new ADMIN_PASSWORD to change the password. The password is hashed before it is stored.
 *
 * Run: ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='…' pnpm db:admin
 */
import { existsSync } from 'node:fs';
import { PrismaPg } from '@prisma/adapter-pg';
import { hashPassword } from '../src/auth/password.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { Role } from '../src/generated/prisma/enums.js';

if (!process.env.DATABASE_URL && existsSync('.env')) process.loadEnvFile('.env');

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });

async function main(): Promise<void> {
  const email = (process.env.ADMIN_EMAIL ?? '').trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD ?? '';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error('Set ADMIN_EMAIL to a valid email address');
  if (password.length < 10) throw new Error('Set ADMIN_PASSWORD to at least 10 characters');

  const passwordHash = await hashPassword(password);
  const existing = await prisma.user.findFirst({
    where: { email: { equals: email, mode: 'insensitive' }, role: { in: [Role.ADMIN, Role.SUPER_ADMIN] }, deletedAt: null },
  });

  if (existing) {
    await prisma.user.update({ where: { id: existing.id }, data: { passwordHash, isActive: true } });
    console.log(`Updated the password for ${existing.role} ${email}`);
    return;
  }
  // users.phone is required and unique, and this admin has no phone, so it holds a marker that is never a valid number.
  await prisma.user.create({
    data: { phone: `email:${email}`, email, name: 'Admin', role: Role.SUPER_ADMIN, passwordHash },
  });
  console.log(`Created super admin ${email}`);
}

main()
  .catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
