import { ValidationPipe } from '@nestjs/common';
import { vi } from 'vitest';
import { AppError } from '../common/errors.js';
import type { User } from '../generated/prisma/client.js';
import { OrderSource, Role } from '../generated/prisma/enums.js';
import type { PrismaService } from '../prisma/prisma.service.js';
import { careNoteOf, carePhotoKey, carePhotoUrl, setCarePhotoBaseUrl } from './care-note.js';
import { AdminPlaceOrderDto, PlaceOrderDto, toOrderDto, type OrderWithRelations } from './order.dto.js';
import { OrdersService, placeRequestHash } from './orders.service.js';

const BASE = 'http://localhost:4999/uploads';
const ME = '22222222-2222-2222-2222-222222222222';
const OTHER = '33333333-3333-3333-3333-333333333333';
const PHOTO = (user: string, n: number) => `${BASE}/care/${user}/aaaaaaaa-aaaa-aaaa-aaaa-${String(n).padStart(12, '0')}.webp`;

beforeAll(() => setCarePhotoBaseUrl(BASE));

describe('care note text', () => {
  it('is trimmed, and blank means no note', () => {
    expect(careNoteOf({ careNote: '  Stain on the collar  ' })).toBe('Stain on the collar');
    expect(careNoteOf({ careNote: '   ' })).toBeNull();
    expect(careNoteOf({ careNote: '' })).toBeNull();
    expect(careNoteOf({})).toBeNull();
  });
});

describe('care photo addresses', () => {
  it('reads the key of the customer’s own photo', () => {
    expect(carePhotoKey(ME, PHOTO(ME, 1))).toBe(`care/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp`);
    expect(carePhotoUrl(`care/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp`)).toBe(PHOTO(ME, 1));
  });

  it.each([
    ['another customer’s photo', PHOTO(OTHER, 1)],
    ['a report photo', `${BASE}/issues/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp`],
    ['another host', PHOTO(ME, 1).replace('localhost:4999', 'example.com')],
    ['a path trick', `${BASE}/care/${ME}/../${OTHER}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp`],
    ['another file type', PHOTO(ME, 1).replace('.webp', '.png')],
    ['a nested folder', `${BASE}/care/${ME}/x/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp`],
    ['a query string', `${PHOTO(ME, 1)}?x=1`],
    ['nothing', ''],
  ])('refuses %s', (_, url) => {
    expect(carePhotoKey(ME, url)).toBeNull();
  });
});

describe('idempotency fingerprint with a care note', () => {
  const base = {
    items: [{ catalogItemId: 'item-1', quantity: 2 }],
    pickupDate: '2026-11-20',
    pickupSlot: 'MORNING',
    deliveryDate: '2026-11-22',
    deliverySlot: 'EVENING',
    pickupAddressId: 'address-1',
    paymentMethod: 'COD',
  } as unknown as PlaceOrderDto;

  it('does not change for a request that has no care note, so a retry that spans an upgrade still matches', () => {
    expect(placeRequestHash({ ...base, careNote: '  ' })).toBe(placeRequestHash(base));
    expect(placeRequestHash({ ...base, carePhotoUrls: [] })).toBe(placeRequestHash(base));
    expect(placeRequestHash({ ...base, careNote: undefined, carePhotoUrls: undefined })).toBe(placeRequestHash(base));
  });

  it('changes with the note and with the photos, and ignores spaces around the note', () => {
    const noted = placeRequestHash({ ...base, careNote: 'Stain on the collar' });
    expect(noted).not.toBe(placeRequestHash(base));
    expect(placeRequestHash({ ...base, careNote: '  Stain on the collar ' })).toBe(noted);
    expect(placeRequestHash({ ...base, careNote: 'Stain on the sleeve' })).not.toBe(noted);
    const photo = placeRequestHash({ ...base, careNote: 'Stain on the collar', carePhotoUrls: [PHOTO(ME, 1)] });
    expect(photo).not.toBe(noted);
    expect(placeRequestHash({ ...base, careNote: 'Stain on the collar', carePhotoUrls: [PHOTO(ME, 2)] })).not.toBe(photo);
    expect(placeRequestHash({ ...base, careNote: 'Stain on the collar', carePhotoUrls: [PHOTO(ME, 1), PHOTO(ME, 2)] })).not.toBe(photo);
  });
});

describe('care note on the order a viewer sees', () => {
  const date = new Date('2026-11-14T09:00:00Z');
  const order = (over: Record<string, unknown> = {}) =>
    ({
      id: 'order',
      status: 'PENDING',
      pickupDate: date,
      deliveryDate: date,
      pickupSlot: 'MORNING',
      deliverySlot: 'EVENING',
      items: [],
      careNote: 'Red silk saree: stain on the pallu',
      carePhotos: [
        { id: 'p1', key: `care/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp` },
        { id: 'p2', key: `care/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000002.webp` },
      ],
      ...over,
    }) as unknown as OrderWithRelations;

  it.each(['CUSTOMER', 'ADMIN', 'DRIVER'] as const)('shows the note and the photos in full to the %s', (viewer) => {
    expect(toOrderDto(order(), viewer)).toMatchObject({
      careNote: 'Red silk saree: stain on the pallu',
      carePhotoUrls: [PHOTO(ME, 1), PHOTO(ME, 2)],
    });
  });

  it('is empty, not missing, for an order without a care note', () => {
    expect(toOrderDto(order({ careNote: null, carePhotos: undefined }), 'CUSTOMER')).toMatchObject({ careNote: null, carePhotoUrls: [] });
  });
});

describe('care note in the request', () => {
  const pipe = new ValidationPipe({ whitelist: true, forbidNonWhitelisted: true, transform: true });
  const valid = {
    items: [{ catalogItemId: '11111111-1111-4111-8111-111111111111', quantity: 1 }],
    pickupDate: '2026-11-20',
    pickupSlot: 'MORNING',
    deliveryDate: '2026-11-22',
    deliverySlot: 'EVENING',
    pickupAddressId: '11111111-1111-4111-8111-111111111111',
    paymentMethod: 'COD',
  };
  const check = <T>(body: unknown, metatype: new () => T): Promise<unknown> =>
    pipe.transform(body, { type: 'body', metatype }).catch((e: unknown) => e);
  const refused = (result: unknown) => expect(result).toMatchObject({ name: 'BadRequestException' });

  it('trims the note and accepts up to 500 characters and 3 photos', async () => {
    const dto = (await check({ ...valid, careNote: `  ${'a'.repeat(500)}  `, carePhotoUrls: [PHOTO(ME, 1), PHOTO(ME, 2), PHOTO(ME, 3)] }, PlaceOrderDto)) as PlaceOrderDto;
    expect(dto.careNote).toHaveLength(500);
    expect(dto.carePhotoUrls).toHaveLength(3);
  });

  it('refuses a note over 500 characters, more than 3 photos and the same photo twice', async () => {
    refused(await check({ ...valid, careNote: 'a'.repeat(501) }, PlaceOrderDto));
    refused(await check({ ...valid, carePhotoUrls: [1, 2, 3, 4].map((n) => PHOTO(ME, n)) }, PlaceOrderDto));
    refused(await check({ ...valid, carePhotoUrls: [PHOTO(ME, 1), PHOTO(ME, 1)] }, PlaceOrderDto));
    refused(await check({ ...valid, carePhotoUrls: 'not a list' }, PlaceOrderDto));
  });

  it('lets staff add a note to a phone order but not photos', async () => {
    const phone = { ...valid, customerId: '11111111-1111-4111-8111-111111111111' };
    expect(await check({ ...phone, careNote: 'Delicate silk' }, AdminPlaceOrderDto)).toMatchObject({ careNote: 'Delicate silk' });
    refused(await check({ ...phone, carePhotoUrls: [PHOTO(ME, 1)] }, AdminPlaceOrderDto));
  });
});

describe('OrdersService.place with care photos', () => {
  const customer = { id: ME, role: Role.CUSTOMER, isActive: true, deletedAt: null, contactPhone: '+919876543210', phone: null } as unknown as User;
  const dto = (urls: string[]) => ({ carePhotoUrls: urls }) as unknown as PlaceOrderDto;
  const serviceFor = (rows: { key: string; id: string }[]) => {
    const findMany = vi.fn().mockResolvedValue(rows);
    const settings = { get: vi.fn().mockRejectedValue(new Error('past the photo check')) };
    const prisma = { user: { findUnique: vi.fn().mockResolvedValue(customer) }, orderCarePhoto: { findMany } } as unknown as PrismaService;
    return { service: new OrdersService(prisma, settings as never, {} as never, {} as never, {} as never, {} as never), findMany, settings };
  };
  const failure = (p: Promise<unknown>) => p.catch((e: unknown) => e) as Promise<AppError>;

  it('refuses a photo of another customer, a report photo and a made-up address without looking in the database', async () => {
    for (const url of [PHOTO(OTHER, 1), `${BASE}/issues/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp`, 'https://example.com/x.webp']) {
      const { service, findMany, settings } = serviceFor([]);
      const result = await failure(service.place(ME, dto([url]), OrderSource.CUSTOMER_APP, customer));
      expect(result).toMatchObject({ code: 'INVALID_PHOTO' });
      expect(findMany).not.toHaveBeenCalled();
      expect(settings.get).not.toHaveBeenCalled();
    }
  });

  it('refuses a photo that is unknown or already on an order', async () => {
    const { service } = serviceFor([{ id: 'p1', key: `care/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp` }]);
    const result = await failure(service.place(ME, dto([PHOTO(ME, 1), PHOTO(ME, 2)]), OrderSource.CUSTOMER_APP, customer));
    expect(result).toMatchObject({ code: 'INVALID_PHOTO' });
  });

  it('refuses more than 3 photos and the same photo twice', async () => {
    const { service } = serviceFor([]);
    expect(await failure(service.place(ME, dto([1, 2, 3, 4].map((n) => PHOTO(ME, n))), OrderSource.CUSTOMER_APP, customer))).toMatchObject({ code: 'TOO_MANY_PHOTOS' });
    expect(await failure(service.place(ME, dto([PHOTO(ME, 1), PHOTO(ME, 1)]), OrderSource.CUSTOMER_APP, customer))).toMatchObject({ code: 'INVALID_PHOTO' });
  });

  it('takes no photos on a phone order', async () => {
    const { service } = serviceFor([]);
    expect(await failure(service.place(ME, dto([PHOTO(ME, 1)]), OrderSource.ADMIN, customer))).toMatchObject({ code: 'INVALID_PHOTO' });
  });

  it('goes on to the rest of the order when the photos are the customer’s own', async () => {
    const { service, settings } = serviceFor([{ id: 'p1', key: `care/${ME}/aaaaaaaa-aaaa-aaaa-aaaa-000000000001.webp` }]);
    const result = await failure(service.place(ME, dto([PHOTO(ME, 1)]), OrderSource.CUSTOMER_APP, customer));
    expect(result.message).toBe('past the photo check');
    expect(settings.get).toHaveBeenCalled();
  });
});
