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

    /** Where uploaded images go: `local` (a folder served by the API, for development) or `s3`. */
    STORAGE_DRIVER: z.enum(['local', 's3']).default('local'),
    STORAGE_LOCAL_DIR: z.string().default('uploads'),
    /** Public URL prefix for stored files, e.g. https://cdn.irondost.in or http://localhost:4000/uploads */
    STORAGE_PUBLIC_BASE_URL: z.string().default('http://localhost:4000/uploads'),
    S3_BUCKET: z.string().default(''),
    S3_REGION: z.string().default('ap-south-1'),

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
          message: 'must be s3 in production (container disks are not persistent)',
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
    if (env.STORAGE_DRIVER === 's3' && !env.S3_BUCKET) {
      ctx.addIssue({ code: 'custom', path: ['S3_BUCKET'], message: 'is required when STORAGE_DRIVER=s3' });
    }
  });

export type Env = z.infer<typeof envSchema>;

export function parseEnv(source: NodeJS.ProcessEnv): Env {
  const result = envSchema.safeParse(source);
  if (!result.success) {
    const issues = result.error.issues.map((i) => `  - ${i.path.join('.')}: ${i.message}`).join('\n');
    throw new Error(`Invalid environment configuration:\n${issues}`);
  }
  return result.data;
}
