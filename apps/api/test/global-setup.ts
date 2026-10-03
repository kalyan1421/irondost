import { execSync } from 'node:child_process';
import pg from 'pg';
import type { TestProject } from 'vitest/node';

declare module 'vitest' {
  export interface ProvidedContext {
    databaseUrl: string;
  }
}

/**
 * Each e2e run gets its own throwaway database: created here, migrated with
 * `prisma migrate deploy`, and dropped when the run ends. Existing databases
 * are never reset or touched.
 *
 * TEST_DATABASE_SERVER_URL points at any database on the server the run may
 * connect to for CREATE/DROP DATABASE (default: local `postgres`).
 */
export default async function setup(project: TestProject): Promise<() => Promise<void>> {
  const server = new URL(
    process.env.TEST_DATABASE_SERVER_URL ?? `postgresql://${process.env.USER ?? 'postgres'}@localhost:5432/postgres`,
  );
  const name = `laundry_e2e_${process.pid}_${Date.now()}`;
  const url = new URL(server);
  url.pathname = `/${name}`;

  const admin = new pg.Client({ connectionString: server.toString() });
  await admin.connect();
  await admin.query(`CREATE DATABASE "${name}"`);
  await admin.end();

  execSync('pnpm exec prisma migrate deploy', {
    env: { ...process.env, DATABASE_URL: url.toString() },
    stdio: 'pipe',
  });
  project.provide('databaseUrl', url.toString());

  return async () => {
    const client = new pg.Client({ connectionString: server.toString() });
    await client.connect();
    await client.query(`DROP DATABASE IF EXISTS "${name}" WITH (FORCE)`);
    await client.end();
  };
}
