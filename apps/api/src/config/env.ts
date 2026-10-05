import { z } from 'zod';

const flag = z
  .enum(['true', 'false'])
  .default('false')
  .transform((v) => v === 'true');

const csv = z
  .string()
  .default('')
  .transform((s) =>
    s
      .split(',')
      .map((x) => x.trim())
      .filter(Boolean),
  );

export const envSchema = z
  .object({
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    PORT: z.coerce.number().int().positive().default(4000),
    CORS_ORIGINS: csv,
    LOG_LEVEL: z.enum(['fatal', 'error', 'warn', 'info', 'debug', 'trace', 'silent']).default('info'),

    DATABASE_URL: z.string().min(1, 'DATABASE_URL is required'),
    /** Connections each pool may open (Prisma and pg-boss have one each). Keep 2 x this under the pooler's limit, e.g. Supabase free tier allows 15. */
    DATABASE_POOL_MAX: z.coerce.number().int().min(1).max(50).default(10),

    APP_NAME: z.string().min(1).default('Laundry'),
    ORDER_NUMBER_PREFIX: z
      .string()
      .regex(/^[A-Z]{1,4}$/, 'ORDER_NUMBER_PREFIX must be 1–4 uppercase letters')
      .default('LD'),

    FIREBASE_SERVICE_ACCOUNT_BASE64: z.string().default(''),
    AUTH_DEV_BYPASS: flag,

    RAZORPAY_KEY_ID: z.string().default(''),
    RAZORPAY_KEY_SECRET: z.string().default(''),
    RAZORPAY_WEBHOOK_SECRET: z.string().default(''),

    /** Where uploaded images go: `local` (a folder served by the API, for development) or `supabase` (Supabase Storage). */
    STORAGE_DRIVER: z.enum(['local', 'supabase']).default('local'),
    STORAGE_LOCAL_DIR: z.string().default('uploads'),
    /** Public URL prefix for local files, e.g. http://localhost:4000/uploads. With `supabase` it is derived from the project and bucket. */
    STORAGE_PUBLIC_BASE_URL: z.string().default('http://localhost:4000/uploads'),
    /** Supabase project URL, e.g. https://<project-ref>.supabase.co */
    SUPABASE_URL: z.string().default(''),
    /** Server-side secret key (service role). It can write to any bucket, so keep it out of the apps and the repo. */
    SUPABASE_SERVICE_ROLE_KEY: z.string().default(''),
    /** A public bucket that holds the uploaded images. */
    SUPABASE_STORAGE_BUCKET: z.string().default(''),

    /** Turn off the pg-boss worker (e.g. for one-off scripts). */
    JOBS_ENABLED: z
      .enum(['true', 'false'])
      .default('true')
      .transform((v) => v === 'true'),
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV === 'production') {
      if (env.AUTH_DEV_BYPASS) {
        ctx.addIssue({ code: 'custom', path: ['AUTH_DEV_BYPASS'], message: 'must be false in production' });
      }
      if (env.STORAGE_DRIVER === 'local') {
        ctx.addIssue({
          code: 'custom',
          path: ['STORAGE_DRIVER'],
          message: 'must be supabase in production (container disks are not persistent)',
        });
      }
      if (!env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
        ctx.addIssue({
          code: 'custom',
          path: ['FIREBASE_SERVICE_ACCOUNT_BASE64'],
          message: 'is required in production',
        });
      }
    }
    if (env.STORAGE_DRIVER === 'supabase') {
      for (const key of ['SUPABASE_URL', 'SUPABASE_SERVICE_ROLE_KEY', 'SUPABASE_STORAGE_BUCKET'] as const) {
        if (!env[key]) ctx.addIssue({ code: 'custom', path: [key], message: 'is required when STORAGE_DRIVER=supabase' });
      }
    }
  })
  .transform((env) =>
    env.STORAGE_DRIVER === 'supabase'
      ? {
          ...env,
          STORAGE_PUBLIC_BASE_URL: `${env.SUPABASE_URL.replace(/\/$/, '')}/storage/v1/object/public/${env.SUPABASE_STORAGE_BUCKET}`,
        }
      : env,
  );

export type Env = z.infer<typeof envSchema>;

export function parseEnv(source: NodeJS.ProcessEnv): Env {
  const result = envSchema.safeParse(source);
  if (!result.success) {
    const issues = result.error.issues.map((i) => `  - ${i.path.join('.')}: ${i.message}`).join('\n');
    throw new Error(`Invalid environment configuration:\n${issues}`);
  }
  return result.data;
}
