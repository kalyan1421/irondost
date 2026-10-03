import { Global, Module } from '@nestjs/common';
import { setUploadsBaseUrl } from '../common/validators.js';
import { parseEnv } from './env.js';

/** Injection token for the validated environment (`Env`). */
export const APP_ENV = Symbol('APP_ENV');

@Global()
@Module({
  providers: [
    {
      provide: APP_ENV,
      useFactory: () => {
        const env = parseEnv(process.env);
        setUploadsBaseUrl(env.STORAGE_PUBLIC_BASE_URL);
        return env;
      },
    },
  ],
  exports: [APP_ENV],
})
export class ConfigModule {}
