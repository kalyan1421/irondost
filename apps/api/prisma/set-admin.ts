/**
 * Creates a super admin who signs in to the admin console with email + password, or resets that admin's password.
 * Idempotent; run it again with a new ADMIN_PASSWORD to change the password. The password is hashed before it is stored.
 *
 * Run: DATABASE_URL='postgresql://…' ADMIN_EMAIL=you@example.com ADMIN_PASSWORD='…' pnpm db:admin
 */
import { existsSync } from 'node:fs';
import { PrismaPg } from '@prisma/adapter-pg';
import { hashPassword } from '../src/auth/password.js';
import { PrismaClient } from '../src/generated/prisma/client.js';
import { Role } from '../src/generated/prisma/enums.js';

if (!process.env.DATABASE_URL && existsSync('.env')) process.loadEnvFile('.env');

function decode(part: string): string {
  try {
    return decodeURIComponent(part);
  } catch {
    return part;
  }
}

/**
 * Reads DATABASE_URL and checks it before anything connects. The `pg` driver reads any text that is not a clean
 * `postgresql://` URL (one wrapped in quotes, with a leading space, a pasted `psql` command, or empty) as the placeholder
 * host `base`, and the only symptom is "Can't reach database server at `base`". This says what is wrong instead, and
 * prints the host it will use, never the password.
 */
function databaseUrl(): string {
  const raw = (process.env.DATABASE_URL ?? '').trim().replace(/^(["'])(.*)\1$/, '$2').trim();
  if (!raw) {
    throw new Error('Set DATABASE_URL to the Supabase session pooler string (postgresql://…@…pooler.supabase.com:5432/postgres)');
  }

  let url: URL;
  try {
    url = new URL(raw);
  } catch {
    throw new Error(
      'DATABASE_URL is not a valid URL. Paste only the connection string, with no quotes and no `psql` command. If the ' +
        'password contains @ : / ? # or %, write each as its percent code (%40 %3A %2F %3F %23 %25) or use a password of ' +
        'only letters and digits.',
    );
  }
  if (url.protocol !== 'postgresql:' && url.protocol !== 'postgres:') {
    throw new Error(`DATABASE_URL must start with postgresql:// but it starts with ${url.protocol}//`);
  }
  if (!url.hostname || !url.username || !url.password) throw new Error('DATABASE_URL needs a host, a user and a password');
  if (/YOUR-PASSWORD/i.test(decode(url.password))) {
    throw new Error('DATABASE_URL still has the [YOUR-PASSWORD] placeholder; replace it, brackets included, with the real password');
  }
  if (url.port === '6543') {
    console.warn('Warning: port 6543 is the transaction pooler. Use the session pooler on port 5432.');
  }

  console.log(`Connecting to ${url.hostname}:${url.port || '5432'}${url.pathname} as ${decode(url.username)} (password hidden)`);
  return raw;
}

async function main(): Promise<void> {
  const email = (process.env.ADMIN_EMAIL ?? '').trim().toLowerCase();
  const password = process.env.ADMIN_PASSWORD ?? '';
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) throw new Error('Set ADMIN_EMAIL to a valid email address');
  if (password.length < 10) throw new Error('Set ADMIN_PASSWORD to at least 10 characters');
  const connectionString = databaseUrl();

  const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString }) });
  try {
    const passwordHash = await hashPassword(password);

    // Every call selects only the columns it needs. Prisma otherwise reads every column in this checkout's schema, so a
    // column added by a migration the production database has not run yet (this script is run against production from a
    // newer checkout) would make it fail with "column does not exist".
    const existing = await prisma.user.findFirst({
      where: { email: { equals: email, mode: 'insensitive' }, role: { in: [Role.ADMIN, Role.SUPER_ADMIN] }, deletedAt: null },
      select: { id: true, role: true },
    });

    if (existing) {
      await prisma.user.update({
        where: { id: existing.id },
        data: { passwordHash, isActive: true },
        select: { id: true },
      });
      console.log(`Updated the password for ${existing.role} ${email}`);
      return;
    }
    // users.phone is required and unique, and this admin has no phone, so it holds a marker that is never a valid number.
    await prisma.user.create({
      data: { phone: `email:${email}`, email, name: 'Admin', role: Role.SUPER_ADMIN, passwordHash },
      select: { id: true },
    });
    console.log(`Created super admin ${email}`);
  } finally {
    await prisma.$disconnect();
  }
}

main().catch((err: unknown) => {
  console.error(err);
  process.exitCode = 1;
});
