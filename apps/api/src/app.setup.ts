import { resolve } from 'node:path';
import { ValidationPipe, type INestApplication } from '@nestjs/common';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import express from 'express';
import helmet from 'helmet';
import { PrismaExceptionFilter } from './common/prisma-exception.filter.js';
import { APP_ENV } from './config/config.module.js';
import type { Env } from './config/env.js';

/** HTTP pipeline shared by main.ts and the e2e tests. */
export function configureApp(app: INestApplication): Env {
  const env = app.get<Env>(APP_ENV);

  app.setGlobalPrefix('v1');
  app.use(helmet());
  app.enableCors({ origin: env.CORS_ORIGINS, credentials: true, exposedHeaders: ['Idempotent-Replayed'] });
  app.useGlobalPipes(
    new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true }),
  );
  app.useGlobalFilters(new PrismaExceptionFilter());

  if (env.STORAGE_DRIVER === 'local') {
    // Development image hosting. Files are immutable (new upload = new name), and other
    // origins (the admin on :3000, the apps) must be allowed to display them.
    app.use(
      '/uploads',
      express.static(resolve(env.STORAGE_LOCAL_DIR), {
        immutable: true,
        maxAge: '365d',
        index: false,
        setHeaders: (res) => res.setHeader('Cross-Origin-Resource-Policy', 'cross-origin'),
      }),
    );
  }
  app.enableShutdownHooks();

  if (env.NODE_ENV !== 'production') {
    const config = new DocumentBuilder()
      .setTitle(`${env.APP_NAME} API`)
      .setDescription(
        'Authenticate with a Firebase phone-OTP ID token: `Authorization: Bearer <token>`. ' +
          'Money is in paise. Dates are IST calendar dates (YYYY-MM-DD).',
      )
      .setVersion('1.0')
      .addBearerAuth()
      .build();
    const document = SwaggerModule.createDocument(app, config);
    SwaggerModule.setup('docs', app, document, { jsonDocumentUrl: 'docs/openapi.json' });
  }

  return env;
}
