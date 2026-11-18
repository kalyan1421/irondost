import { existsSync } from 'node:fs';
import { NestFactory } from '@nestjs/core';
import { Logger } from 'nestjs-pino';
import { AppModule } from './app.module.js';
import { configureApp } from './app.setup.js';
import { productionWarnings } from './config/production-warnings.js';

if (existsSync('.env')) process.loadEnvFile('.env');

async function bootstrap() {
  // rawBody is needed to verify Razorpay webhook signatures.
  const app = await NestFactory.create(AppModule, { rawBody: true, bufferLogs: true });
  app.useLogger(app.get(Logger));
  const env = configureApp(app);
  const logger = app.get(Logger);
  for (const warning of productionWarnings(env)) logger.warn(warning);
  await app.listen(env.PORT);
}
await bootstrap();
