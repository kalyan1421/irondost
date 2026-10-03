/**
 * Idempotent bootstrap data:
 *  - the first super admin (SEED_SUPER_ADMIN_PHONE), who then adds everyone else from the admin
 *  - a SAMPLE catalogue with placeholder prices, only if the catalogue is empty
 *
 * Run: pnpm db:seed
 */
import { existsSync } from 'node:fs';
import { PrismaPg } from '@prisma/adapter-pg';
import { normalizeIndianPhone } from '../src/common/phone.js';
import { PrismaClient } from '../src/generated/prisma/client.js';

if (!process.env.DATABASE_URL && existsSync('.env')) process.loadEnvFile('.env');

const prisma = new PrismaClient({ adapter: new PrismaPg({ connectionString: process.env.DATABASE_URL! }) });

// Placeholder prices in paise. Replace them from the admin before launch.
const SAMPLE_CATALOGUE = [
  {
    name: 'Ironing',
    slug: 'ironing',
    items: [
      ['Shirt / T-shirt', 1500],
      ['Trousers / Jeans', 1500],
      ['Kurta', 2000],
      ['Saree', 5000],
      ['Dupatta', 1000],
      ['Bedsheet (single)', 2500],
    ],
  },
  {
    name: 'Wash & Iron',
    slug: 'wash-and-iron',
    items: [
      ['Shirt / T-shirt', 3500],
      ['Trousers / Jeans', 4000],
      ['Bedsheet (double)', 7000],
    ],
  },
  {
    name: 'Dry Cleaning',
    slug: 'dry-cleaning',
    items: [
      ['Suit (2 piece)', 35000],
      ['Blazer', 20000],
      ['Silk saree', 25000],
    ],
  },
] as const;

async function main(): Promise<void> {
  const phone = normalizeIndianPhone(process.env.SEED_SUPER_ADMIN_PHONE ?? '');
  if (!phone) throw new Error('Set SEED_SUPER_ADMIN_PHONE to a valid Indian mobile number');

  const existing = await prisma.user.findUnique({ where: { phone } });
  if (!existing) {
    await prisma.user.create({ data: { phone, name: 'Owner', role: 'SUPER_ADMIN' } });
    console.log(`Created super admin ${phone}`);
  } else if (existing.role !== 'SUPER_ADMIN') {
    console.warn(`${phone} already exists with role ${existing.role}; not changed`);
  }

  if ((await prisma.catalogCategory.count()) === 0) {
    for (const [i, cat] of SAMPLE_CATALOGUE.entries()) {
      await prisma.catalogCategory.create({
        data: {
          name: cat.name,
          slug: cat.slug,
          sortOrder: i,
          items: { create: cat.items.map(([name, pricePaise], j) => ({ name, pricePaise, sortOrder: j })) },
        },
      });
    }
    console.log('Created sample catalogue (placeholder prices)');
  }

  const settings = await prisma.businessSettings.upsert({ where: { id: 1 }, create: { id: 1 }, update: {} });
  // IronDost's support line; admins can change it in Settings. Only filled in when empty.
  if (!settings.supportPhone && !settings.supportEmail) {
    await prisma.businessSettings.update({
      where: { id: 1 },
      data: { supportPhone: '+919063290012', supportEmail: 'kalyan91333@gmail.com' },
    });
    console.log('Set the support contact');
  }
  // Launch area: Hyderabad, roughly everything inside the Outer Ring Road. Other cities can sign up
  // and save addresses but can't book. Only set when no area has been configured.
  if (settings.serviceRadiusKm === null && settings.servicePincodes.length === 0) {
    await prisma.businessSettings.update({
      where: { id: 1 },
      data: { serviceCenterLatitude: 17.385, serviceCenterLongitude: 78.4867, serviceRadiusKm: 25 },
    });
    console.log('Set the service area to Hyderabad (25 km)');
  }
}

main()
  .catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
