// Writes the API's OpenAPI document to packages/contracts/openapi.json.
// The admin (TypeScript) and mobile apps (Dart) generate their API clients from it.
// Runs Nest in preview mode: no database connection or providers are started.
import { mkdirSync, writeFileSync } from 'node:fs';
import { NestFactory } from '@nestjs/core';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import { AppModule } from '../dist/app.module.js';

const app = await NestFactory.create(AppModule, { preview: true, logger: false });
app.setGlobalPrefix('v1');
const config = new DocumentBuilder()
  .setTitle('Laundry API')
  .setDescription('Firebase phone-OTP ID token as Bearer. Money in paise. Dates are IST (YYYY-MM-DD).')
  .setVersion('1.0')
  .addBearerAuth()
  .build();
const document = SwaggerModule.createDocument(app, config);

const out = new URL('../../../packages/contracts/openapi.json', import.meta.url);
mkdirSync(new URL('.', out), { recursive: true });
writeFileSync(out, `${JSON.stringify(document, null, 2)}\n`);
console.log(`Wrote ${Object.keys(document.paths).length} paths to packages/contracts/openapi.json`);
await app.close();
