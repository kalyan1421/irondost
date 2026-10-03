import { createHmac } from 'node:crypto';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import sharp from 'sharp';
import type { INestApplication } from '@nestjs/common';
import { Test } from '@nestjs/testing';
import request from 'supertest';
import { inject } from 'vitest';
import { AppModule } from '../src/app.module.js';
import { configureApp } from '../src/app.setup.js';
import { addDays, istDate } from '../src/common/time.js';
import { JobScheduler } from '../src/jobs/job-scheduler.js';
import { RazorpayGateway } from '../src/payments/razorpay.gateway.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { FakeRazorpay, MemoryScheduler, waitFor } from './support.js';

const PHONES = {
  superAdmin: '9000000000',
  admin: '9000000001',
  driver1: '9111111111',
  driver2: '9222222222',
  customer: '9333333333',
  otherCustomer: '9444444444',
  leaver: '9555555555',
};
const bearer = (phone: string) => ({ Authorization: `Bearer dev:${phone}` });

describe('Laundry API (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const jobs = new MemoryScheduler();
  const razorpay = new FakeRazorpay();
  let http: ReturnType<typeof request>;

  const uploadDir = mkdtempSync(join(tmpdir(), 'irondost-uploads-'));
  const tomorrow = addDays(istDate(new Date()), 1);
  const dayAfter = addDays(tomorrow, 1);

  // Shared state across the sequential steps below.
  let shirtId: string;
  let sareeId: string;
  let driver1Id: string;
  let driver2Id: string;
  let addressId: string;
  let order1Id: string;

  beforeAll(async () => {
    Object.assign(process.env, {
      NODE_ENV: 'test',
      DATABASE_URL: inject('databaseUrl'),
      AUTH_DEV_BYPASS: 'true',
      LOG_LEVEL: 'silent',
      ORDER_NUMBER_PREFIX: 'TS',
      FIREBASE_SERVICE_ACCOUNT_BASE64: '',
      STORAGE_DRIVER: 'local',
      STORAGE_LOCAL_DIR: uploadDir,
      STORAGE_PUBLIC_BASE_URL: 'http://localhost:4999/uploads',
    });
    const moduleRef = await Test.createTestingModule({ imports: [AppModule] })
      .overrideProvider(JobScheduler)
      .useValue(jobs)
      .overrideProvider(RazorpayGateway)
      .useValue(razorpay)
      .compile();
    app = moduleRef.createNestApplication({ rawBody: true, logger: false });
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
    http = request(app.getHttpServer());

    await prisma.user.create({ data: { phone: `+91${PHONES.superAdmin}`, name: 'Owner', role: 'SUPER_ADMIN' } });
    await prisma.businessSettings.update({ where: { id: 1 }, data: { dispatchBatchSize: 3 } });
  });

  afterAll(async () => {
    await app?.close();
    rmSync(uploadDir, { recursive: true, force: true });
  });

  const session = (phone: string, appName: 'CUSTOMER' | 'PARTNER' | 'ADMIN') =>
    http.post('/v1/auth/session').set(bearer(phone)).send({ app: appName });

  /** Places an order for the main customer and runs its first dispatch round. */
  async function placeAndDispatch(items: { catalogItemId: string; quantity: number }[]) {
    const res = await http
      .post('/v1/orders')
      .set(bearer(PHONES.customer))
      .send({
        items,
        pickupDate: tomorrow,
        pickupSlot: 'MORNING',
        deliveryDate: dayAfter,
        deliverySlot: 'EVENING',
        pickupAddressId: addressId,
        paymentMethod: 'COD',
      })
      .expect(201);
    const orderId = res.body.id as string;
    await waitFor(() => jobs.has('dispatch-round', (d) => d.orderId === orderId));
    await jobs.run('dispatch-round', (d) => d.orderId === orderId);
    return res.body;
  }

  async function offerFor(phone: string, orderId: string): Promise<string> {
    const res = await http.get('/v1/driver/offers').set(bearer(phone)).expect(200);
    const offer = res.body.find((o: { orderId: string }) => o.orderId === orderId);
    expect(offer).toBeDefined();
    return offer.offerId as string;
  }

  describe('sign-in', () => {
    it('requires a token and a session', async () => {
      await http.get('/v1/me').expect(401);
      const res = await http.get('/v1/me').set(bearer(PHONES.customer)).expect(401);
      expect(res.body.code).toBe('SESSION_REQUIRED');
    });

    it('creates customers on first sign-in but not staff', async () => {
      const res = await session(PHONES.customer, 'CUSTOMER').expect(200);
      expect(res.body).toMatchObject({ phone: `+91${PHONES.customer}`, role: 'CUSTOMER', isProfileComplete: false });
      const denied = await session(PHONES.driver1, 'PARTNER').expect(403);
      expect(denied.body.code).toBe('NOT_REGISTERED');
    });

    it('keeps each role in its own app', async () => {
      const res = await session(PHONES.customer, 'ADMIN').expect(403);
      expect(res.body.code).toBe('WRONG_APP');
      await session(PHONES.superAdmin, 'ADMIN').expect(200);
    });

    it('blocks customers from admin routes', async () => {
      const res = await http.get('/v1/admin/orders').set(bearer(PHONES.customer)).expect(403);
      expect(res.body.code).toBe('FORBIDDEN_ROLE');
    });
  });

  describe('admin setup', () => {
    it('builds the catalogue', async () => {
      const cat = await http
        .post('/v1/admin/catalog/categories')
        .set(bearer(PHONES.superAdmin))
        .send({ name: 'Ironing', slug: 'ironing' })
        .expect(201);
      const shirt = await http
        .post('/v1/admin/catalog/items')
        .set(bearer(PHONES.superAdmin))
        .send({ categoryId: cat.body.id, name: 'Shirt', pricePaise: 1500 })
        .expect(201);
      const saree = await http
        .post('/v1/admin/catalog/items')
        .set(bearer(PHONES.superAdmin))
        .send({ categoryId: cat.body.id, name: 'Saree', pricePaise: 5000, offerPricePaise: 4000 })
        .expect(201);
      shirtId = shirt.body.id;
      sareeId = saree.body.id;
      expect(saree.body.effectivePricePaise).toBe(4000);

      const bad = await http
        .post('/v1/admin/catalog/items')
        .set(bearer(PHONES.superAdmin))
        .send({ categoryId: cat.body.id, name: 'Kurta', pricePaise: 2000, offerPricePaise: 2500 })
        .expect(400);
      expect(bad.body.code).toBe('INVALID_OFFER_PRICE');

      const pub = await http.get('/v1/catalog').expect(200);
      expect(pub.body[0].items.map((i: { name: string }) => i.name)).toEqual(['Saree', 'Shirt']);
    });

    it('adds staff and delivery partners who can then sign in', async () => {
      await http
        .post('/v1/admin/staff')
        .set(bearer(PHONES.superAdmin))
        .send({ phone: PHONES.admin, name: 'Ops', role: 'ADMIN' })
        .expect(201);
      await session(PHONES.admin, 'ADMIN').expect(200);
      const d1 = await http
        .post('/v1/admin/drivers')
        .set(bearer(PHONES.admin))
        .send({ phone: PHONES.driver1, name: 'Ravi', vehicleNumber: 'TS09AB1234' })
        .expect(201);
      const d2 = await http
        .post('/v1/admin/drivers')
        .set(bearer(PHONES.admin))
        .send({ phone: `+91 ${PHONES.driver2}`, name: 'Suresh' })
        .expect(201);
      driver1Id = d1.body.id;
      driver2Id = d2.body.id;
      expect(d2.body.phone).toBe(`+91${PHONES.driver2}`);

      for (const phone of [PHONES.driver1, PHONES.driver2]) {
        await session(phone, 'PARTNER').expect(200);
        await http.put('/v1/driver/online').set(bearer(phone)).send({ isOnline: true }).expect(204);
      }
      // Driver 1 is closer to the customer than driver 2.
      await http.put('/v1/driver/location').set(bearer(PHONES.driver1)).send({ latitude: 17.41, longitude: 78.45 }).expect(204);
      await http.put('/v1/driver/location').set(bearer(PHONES.driver2)).send({ latitude: 17.5, longitude: 78.6 }).expect(204);
    });

    it('only lets super admins change settings', async () => {
      await http.patch('/v1/admin/settings').set(bearer(PHONES.admin)).send({ deliveryFeePaise: 0 }).expect(403);
      await http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send({ deliveryFeePaise: 0 }).expect(200);
    });
  });

  describe('customer ordering', () => {
    it('completes the profile and saves an address', async () => {
      await http.patch('/v1/me').set(bearer(PHONES.customer)).send({ name: 'Priya' }).expect(200);
      const res = await http
        .post('/v1/me/addresses')
        .set(bearer(PHONES.customer))
        .send({
          houseNo: 'Flat 302',
          street: 'Road No. 12',
          area: 'Banjara Hills',
          city: 'Hyderabad',
          state: 'Telangana',
          pincode: '500034',
          latitude: 17.4126,
          longitude: 78.4482,
        })
        .expect(201);
      addressId = res.body.id;
      expect(res.body.isPrimary).toBe(true);
      await http.post('/v1/me/addresses').set(bearer(PHONES.customer)).send({ houseNo: '1', street: 'x', city: 'Hyderabad', state: 'TS', pincode: '012345' }).expect(400);
    });

    it('quotes on the server, with promo codes', async () => {
      await http
        .post('/v1/admin/promotions')
        .set(bearer(PHONES.admin))
        .send({
          code: 'first10',
          title: '10% off',
          discountType: 'PERCENT',
          discountValue: 10,
          minOrderPaise: 5000,
          validFrom: new Date(Date.now() - 60_000).toISOString(),
          validTo: new Date(Date.now() + 86_400_000).toISOString(),
        })
        .expect(201);

      const items = [
        { catalogItemId: shirtId, quantity: 4 },
        { catalogItemId: sareeId, quantity: 1 },
      ];
      const plain = await http.post('/v1/orders/quote').set(bearer(PHONES.customer)).send({ items }).expect(200);
      expect(plain.body).toMatchObject({ subtotalPaise: 10000, discountPaise: 0, totalPaise: 10000, canPlaceOrder: true });

      const promo = await http.post('/v1/orders/quote').set(bearer(PHONES.customer)).send({ items, promoCode: 'FIRST10' }).expect(200);
      expect(promo.body).toMatchObject({ discountPaise: 1000, totalPaise: 9000, promoCode: 'FIRST10', promoError: null });

      const small = await http
        .post('/v1/orders/quote')
        .set(bearer(PHONES.customer))
        .send({ items: [{ catalogItemId: shirtId, quantity: 1 }], promoCode: 'FIRST10' })
        .expect(200);
      expect(small.body).toMatchObject({ promoError: 'PROMO_MIN_ORDER', promoShortfallPaise: 3500, canPlaceOrder: false });

      const unknown = await http.post('/v1/orders/quote').set(bearer(PHONES.customer)).send({ items, promoCode: 'NOPE' }).expect(200);
      expect(unknown.body.promoError).toBe('PROMO_NOT_FOUND');
    });

    it('rejects closed slots and short turnarounds', async () => {
      const base = { items: [{ catalogItemId: shirtId, quantity: 1 }], pickupAddressId: addressId, paymentMethod: 'COD' };
      const past = await http
        .post('/v1/orders')
        .set(bearer(PHONES.customer))
        .send({ ...base, pickupDate: addDays(tomorrow, -2), pickupSlot: 'MORNING', deliveryDate: tomorrow, deliverySlot: 'EVENING' })
        .expect(400);
      expect(past.body.code).toBe('PICKUP_SLOT_CLOSED');
      const rushed = await http
        .post('/v1/orders')
        .set(bearer(PHONES.customer))
        .send({ ...base, pickupDate: tomorrow, pickupSlot: 'MORNING', deliveryDate: tomorrow, deliverySlot: 'EVENING' })
        .expect(400);
      expect(rushed.body.code).toBe('DELIVERY_TOO_SOON');
    });

    it('places an order and offers it to the nearest drivers', async () => {
      const res = await http
        .post('/v1/orders')
        .set(bearer(PHONES.customer))
        .send({
          items: [
            { catalogItemId: shirtId, quantity: 4 },
            { catalogItemId: sareeId, quantity: 1 },
          ],
          promoCode: 'FIRST10',
          pickupDate: tomorrow,
          pickupSlot: 'MORNING',
          deliveryDate: dayAfter,
          deliverySlot: 'MORNING',
          pickupAddressId: addressId,
          paymentMethod: 'COD',
          instructions: 'Ring the bell twice',
        })
        .expect(201);
      order1Id = res.body.id;
      expect(res.body).toMatchObject({ status: 'PENDING', totalPaise: 9000, amountDuePaise: 9000, paymentStatus: 'UNPAID' });
      expect(res.body.orderNumber).toMatch(/^TS\d{6}$/);
      expect(res.body.pickupAddress).toMatchObject({ contactName: 'Priya', area: 'Banjara Hills' });

      await waitFor(() => jobs.has('dispatch-round', (d) => d.orderId === order1Id));
      await jobs.run('dispatch-round', (d) => d.orderId === order1Id);

      const offers = await http.get('/v1/driver/offers').set(bearer(PHONES.driver1)).expect(200);
      expect(offers.body).toHaveLength(1);
      expect(offers.body[0]).toMatchObject({ orderId: order1Id, leg: 'PICKUP', area: 'Banjara Hills, Hyderabad', itemCount: 5 });
      expect(offers.body[0].distanceKm).toBeLessThan(1);
      // Offers show the area only, never the customer's phone or full address.
      expect(JSON.stringify(offers.body[0])).not.toContain(PHONES.customer);
      expect(jobs.has('dispatch-expire', (d) => d.orderId === order1Id)).toBe(true);
    });

    it('assigns the pickup to the driver who accepts', async () => {
      const offer2 = await offerFor(PHONES.driver2, order1Id);
      await http.post(`/v1/driver/offers/${offer2}/reject`).set(bearer(PHONES.driver2)).expect(204);
      const offer1 = await offerFor(PHONES.driver1, order1Id);
      const res = await http.post(`/v1/driver/offers/${offer1}/accept`).set(bearer(PHONES.driver1)).expect(200);
      expect(res.body).toMatchObject({ status: 'PICKUP_ASSIGNED', pickupDriver: { id: driver1Id } });

      const again = await http.post(`/v1/driver/offers/${offer2}/accept`).set(bearer(PHONES.driver2)).expect(409);
      expect(again.body.code).toBe('OFFER_CLOSED');

      const tasks = await http.get('/v1/driver/tasks').set(bearer(PHONES.driver1)).expect(200);
      expect(tasks.body.map((o: { id: string }) => o.id)).toContain(order1Id);
      await http.get(`/v1/driver/orders/${order1Id}`).set(bearer(PHONES.driver2)).expect(404);
    });

    it('lets exactly one driver win when two accept at once', async () => {
      const order = await placeAndDispatch([{ catalogItemId: shirtId, quantity: 2 }]);
      const [o1, o2] = await Promise.all([offerFor(PHONES.driver1, order.id), offerFor(PHONES.driver2, order.id)]);
      const results = await Promise.all([
        http.post(`/v1/driver/offers/${o1}/accept`).set(bearer(PHONES.driver1)),
        http.post(`/v1/driver/offers/${o2}/accept`).set(bearer(PHONES.driver2)),
      ]);
      expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
      const loser = results.find((r) => r.status === 409)!;
      expect(['OFFER_TAKEN', 'OFFER_CLOSED']).toContain(loser.body.code);
    });

    it('does not leave an order stuck when every driver declines', async () => {
      const order = await placeAndDispatch([{ catalogItemId: shirtId, quantity: 1 }]);
      for (const phone of [PHONES.driver1, PHONES.driver2]) {
        const id = await offerFor(phone, order.id);
        await http.post(`/v1/driver/offers/${id}/reject`).set(bearer(phone)).expect(204);
      }
      // The last rejection starts the next round at once; nobody is left, so admins are alerted.
      const flagged = await http.get('/v1/admin/orders?dispatchFailed=true').set(bearer(PHONES.admin)).expect(200);
      expect(flagged.body.items.map((o: { id: string }) => o.id)).toContain(order.id);
      expect(jobs.has('dispatch-round', (d) => d.orderId === order.id)).toBe(true); // retry queued
      await waitFor(async () =>
        (await prisma.notification.count({ where: { type: 'dispatch_failed', data: { path: ['orderId'], equals: order.id } } })) > 0,
      );

      const assigned = await http
        .post(`/v1/admin/orders/${order.id}/assign`)
        .set(bearer(PHONES.admin))
        .send({ leg: 'PICKUP', driverId: driver2Id })
        .expect(200);
      expect(assigned.body).toMatchObject({ status: 'PICKUP_ASSIGNED', dispatchFailedAt: null, pickupDriver: { id: driver2Id } });

      const dash = await http.get('/v1/admin/dashboard').set(bearer(PHONES.admin)).expect(200);
      expect(dash.body.needsAttention).toBe(0);
      expect(dash.body.driversOnline).toBe(2);
    });
  });

  describe('order lifecycle', () => {
    it('recounts items at pickup and reprices', async () => {
      const res = await http
        .put(`/v1/driver/orders/${order1Id}/items`)
        .set(bearer(PHONES.driver1))
        .send({ items: [{ catalogItemId: shirtId, quantity: 5 }, { catalogItemId: sareeId, quantity: 1 }], note: '1 extra shirt' })
        .expect(200);
      // 5×1500 + 4000 = 11500, minus 10% = 10350
      expect(res.body).toMatchObject({ subtotalPaise: 11500, discountPaise: 1150, totalPaise: 10350 });
    });

    it('moves through pickup and the workshop', async () => {
      await http.post(`/v1/driver/orders/${order1Id}/picked-up`).set(bearer(PHONES.driver2)).expect(403);
      await http.post(`/v1/driver/orders/${order1Id}/picked-up`).set(bearer(PHONES.driver1)).expect(200);

      const cancel = await http.post(`/v1/orders/${order1Id}/cancel`).set(bearer(PHONES.customer)).send({}).expect(409);
      expect(cancel.body.code).toBe('INVALID_TRANSITION');

      const skip = await http.post(`/v1/admin/orders/${order1Id}/status`).set(bearer(PHONES.admin)).send({ status: 'DELIVERED' }).expect(409);
      expect(skip.body.code).toBe('INVALID_TRANSITION');

      await http.post(`/v1/admin/orders/${order1Id}/status`).set(bearer(PHONES.admin)).send({ status: 'PROCESSING' }).expect(200);
      jobs.clear();
      const ready = await http.post(`/v1/admin/orders/${order1Id}/status`).set(bearer(PHONES.admin)).send({ status: 'READY_FOR_DELIVERY' }).expect(200);
      expect(ready.body.allowedNextStatuses).toEqual(expect.arrayContaining(['DELIVERY_ASSIGNED', 'CANCELLED']));
    });

    it('dispatches the delivery leg and collects cash on delivery', async () => {
      await waitFor(() => jobs.has('dispatch-round', (d) => d.orderId === order1Id && d.leg === 'DELIVERY'));
      await jobs.run('dispatch-round', (d) => d.orderId === order1Id);

      // Driver 2 holds one pickup; driver 1 holds two. Both can still take more.
      const offer = await offerFor(PHONES.driver2, order1Id);
      const accepted = await http.post(`/v1/driver/offers/${offer}/accept`).set(bearer(PHONES.driver2)).expect(200);
      expect(accepted.body).toMatchObject({ status: 'DELIVERY_ASSIGNED', deliveryDriver: { id: driver2Id } });

      await http.post(`/v1/driver/orders/${order1Id}/out-for-delivery`).set(bearer(PHONES.driver2)).expect(200);
      const due = await http.post(`/v1/driver/orders/${order1Id}/delivered`).set(bearer(PHONES.driver2)).send({}).expect(400);
      expect(due.body).toMatchObject({ code: 'PAYMENT_DUE', details: { amountDuePaise: 10350 } });

      const done = await http
        .post(`/v1/driver/orders/${order1Id}/delivered`)
        .set(bearer(PHONES.driver2))
        .send({ collectedCash: true })
        .expect(200);
      expect(done.body).toMatchObject({ status: 'DELIVERED', paymentStatus: 'PAID', paidPaise: 10350, amountDuePaise: 0 });
    });

    it('shows the customer a full timeline and notifications', async () => {
      const res = await http.get(`/v1/orders/${order1Id}`).set(bearer(PHONES.customer)).expect(200);
      expect(res.body.events.map((e: { toStatus: string }) => e.toStatus)).toEqual([
        'PENDING',
        'PICKUP_ASSIGNED',
        'PICKUP_ASSIGNED', // items recounted
        'PICKED_UP',
        'PROCESSING',
        'READY_FOR_DELIVERY',
        'DELIVERY_ASSIGNED',
        'OUT_FOR_DELIVERY',
        'DELIVERED',
      ]);
      await waitFor(async () => {
        const inbox = await http.get('/v1/me/notifications').set(bearer(PHONES.customer));
        return inbox.body.items.some((n: { type: string }) => n.type === 'payment_received');
      });
    });

    it('hides other customers’ orders', async () => {
      await session(PHONES.otherCustomer, 'CUSTOMER').expect(200);
      await http.get(`/v1/orders/${order1Id}`).set(bearer(PHONES.otherCustomer)).expect(404);
      const mine = await http.get('/v1/orders').set(bearer(PHONES.otherCustomer)).expect(200);
      expect(mine.body.total).toBe(0);
    });
  });

  describe('online payments', () => {
    let orderId: string;
    let total: number;

    it('creates a Razorpay order for the amount due and verifies the signature', async () => {
      const order = await placeAndDispatch([{ catalogItemId: sareeId, quantity: 2 }]);
      orderId = order.id;
      total = order.totalPaise;
      const checkout = await http.post(`/v1/orders/${orderId}/payments/razorpay`).set(bearer(PHONES.customer)).expect(201);
      expect(checkout.body).toMatchObject({ keyId: 'rzp_test_key', amountPaise: total, currency: 'INR' });

      const rpOrder = checkout.body.razorpayOrderId as string;
      const forged = await http
        .post('/v1/payments/razorpay/verify')
        .set(bearer(PHONES.customer))
        .send({ razorpayOrderId: rpOrder, razorpayPaymentId: 'pay_1', razorpaySignature: 'f'.repeat(64) })
        .expect(400);
      expect(forged.body.code).toBe('INVALID_SIGNATURE');

      const signature = createHmac('sha256', razorpay.keySecret).update(`${rpOrder}|pay_1`).digest('hex');
      const ok = await http
        .post('/v1/payments/razorpay/verify')
        .set(bearer(PHONES.customer))
        .send({ razorpayOrderId: rpOrder, razorpayPaymentId: 'pay_1', razorpaySignature: signature })
        .expect(200);
      expect(ok.body.paymentStatus).toBe('PAID');

      // The webhook for the same payment changes nothing.
      const body = JSON.stringify({
        event: 'payment.captured',
        payload: { payment: { entity: { id: 'pay_1', order_id: rpOrder, amount: total, status: 'captured' } } },
      });
      const webhookSig = createHmac('sha256', razorpay.webhookSecret).update(body).digest('hex');
      await http.post('/v1/webhooks/razorpay').set('content-type', 'application/json').set('x-razorpay-signature', webhookSig).send(body).expect(200);
      await http.post('/v1/webhooks/razorpay').set('content-type', 'application/json').set('x-razorpay-signature', 'bad').send(body).expect(401);

      const after = await http.get(`/v1/orders/${orderId}`).set(bearer(PHONES.customer)).expect(200);
      expect(after.body).toMatchObject({ paidPaise: total, paymentStatus: 'PAID' });
      const nothingDue = await http.post(`/v1/orders/${orderId}/payments/razorpay`).set(bearer(PHONES.customer)).expect(409);
      expect(nothingDue.body.code).toBe('NOTHING_DUE');
    });

    it('lets an unpaid online order become cash on delivery, but not a paid one or someone else\'s', async () => {
      const placeOnline = async () => {
        const res = await http
          .post('/v1/orders')
          .set(bearer(PHONES.customer))
          .send({
            items: [{ catalogItemId: sareeId, quantity: 1 }],
            pickupDate: tomorrow,
            pickupSlot: 'MORNING',
            deliveryDate: dayAfter,
            deliverySlot: 'EVENING',
            pickupAddressId: addressId,
            paymentMethod: 'ONLINE',
          })
          .expect(201);
        return res.body as { id: string; paymentMethod: string };
      };

      const unpaid = await placeOnline();
      expect(unpaid.paymentMethod).toBe('ONLINE');

      await http.post(`/v1/orders/${unpaid.id}/pay-on-delivery`).set(bearer(PHONES.otherCustomer)).expect(404);

      const switched = await http.post(`/v1/orders/${unpaid.id}/pay-on-delivery`).set(bearer(PHONES.customer)).expect(200);
      expect(switched.body).toMatchObject({ paymentMethod: 'COD', paymentStatus: 'UNPAID', paidPaise: 0 });
      expect(switched.body.events.at(-1).note).toBe('Customer chose to pay cash on delivery');

      // Asking again changes nothing and adds no second event.
      const again = await http.post(`/v1/orders/${unpaid.id}/pay-on-delivery`).set(bearer(PHONES.customer)).expect(200);
      expect(again.body.events).toHaveLength(switched.body.events.length);

      // An online order that has been paid cannot be switched.
      const paid = await placeOnline();
      const checkout = await http.post(`/v1/orders/${paid.id}/payments/razorpay`).set(bearer(PHONES.customer)).expect(201);
      const rpOrder = checkout.body.razorpayOrderId as string;
      const signature = createHmac('sha256', razorpay.keySecret).update(`${rpOrder}|pay_2`).digest('hex');
      await http
        .post('/v1/payments/razorpay/verify')
        .set(bearer(PHONES.customer))
        .send({ razorpayOrderId: rpOrder, razorpayPaymentId: 'pay_2', razorpaySignature: signature })
        .expect(200);
      const refused = await http.post(`/v1/orders/${paid.id}/pay-on-delivery`).set(bearer(PHONES.customer)).expect(409);
      expect(refused.body.code).toBe('ALREADY_PAID');
    });
  });

  describe('service area, order filters and retries', () => {
    // Hub at Banjara Hills with an 8 km radius.
    const HUB = { serviceCenterLatitude: 17.4126, serviceCenterLongitude: 78.4482, serviceRadiusKm: 8 };
    const gachibowli = { latitude: 17.4401, longitude: 78.3489 }; // ~11 km away
    const jubileeHills = { latitude: 17.4325, longitude: 78.4071 }; // ~5 km away
    // Signed in by the "hides other customers’ orders" test, with no orders yet.
    const customer = bearer(PHONES.otherCustomer);
    let farAddressId: string;
    let nearAddressId: string;
    let retriedOrderId: string;

    const order = (pickupAddressId: string, quantity = 3) => ({
      items: [{ catalogItemId: shirtId, quantity }],
      pickupDate: tomorrow,
      pickupSlot: 'MORNING',
      deliveryDate: dayAfter,
      deliverySlot: 'EVENING',
      pickupAddressId,
      paymentMethod: 'COD',
    });

    it('lets super admins set the area, all of the radius or none of it', async () => {
      const partial = await http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send({ serviceRadiusKm: 8 }).expect(400);
      expect(partial.body.code).toBe('SERVICE_AREA_INCOMPLETE');
      const res = await http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send(HUB).expect(200);
      expect(res.body).toMatchObject({ ...HUB, servicePincodes: [] });
    });

    it('answers "do you serve here?" without sign-in', async () => {
      const far = await http.get('/v1/service-area/check').query(gachibowli).expect(200);
      expect(far.body).toMatchObject({ serviceable: false, reason: 'OUTSIDE_RADIUS' });
      expect(far.body.distanceKm).toBeGreaterThan(8);
      const near = await http.get('/v1/service-area/check').query({ ...jubileeHills, pincode: '500033' }).expect(200);
      expect(near.body).toMatchObject({ serviceable: true, reason: null });
      await http.get('/v1/service-area/check').query({ latitude: 17.4 }).expect(400);
      await http.get('/v1/service-area/check').expect(400);
    });

    it('saves an address outside the area but refuses pickups there', async () => {
      await http.patch('/v1/me').set(customer).send({ name: 'Arjun' }).expect(200);
      const address = { houseNo: '12', street: 'ISB Road', city: 'Hyderabad', state: 'Telangana' };
      const far = await http.post('/v1/me/addresses').set(customer).send({ ...address, pincode: '500032', ...gachibowli }).expect(201);
      expect(far.body).toMatchObject({ serviceable: false, notServiceableReason: 'OUTSIDE_RADIUS' });
      farAddressId = far.body.id;

      const refused = await http.post('/v1/orders').set(customer).send(order(farAddressId)).expect(400);
      expect(refused.body).toMatchObject({ code: 'ADDRESS_NOT_SERVICEABLE', details: { addressId: farAddressId, reason: 'OUTSIDE_RADIUS' } });

      // Staff can still take a phone order there.
      const me = await http.get('/v1/me').set(customer).expect(200);
      await http.post('/v1/admin/orders').set(bearer(PHONES.admin)).send({ ...order(farAddressId), customerId: me.body.id }).expect(201);

      const near = await http.post('/v1/me/addresses').set(customer).send({ ...address, street: 'Road No. 36', pincode: '500033', ...jubileeHills }).expect(201);
      expect(near.body.serviceable).toBe(true);
      nearAddressId = near.body.id;
    });

    it('places an order once however often the app retries', async () => {
      const key = { 'Idempotency-Key': 'checkout-7f3a9c21' };
      const first = await http.post('/v1/orders').set(customer).set(key).send(order(nearAddressId)).expect(201);
      expect(first.headers['idempotent-replayed']).toBeUndefined();
      retriedOrderId = first.body.id;

      const retry = await http.post('/v1/orders').set(customer).set(key).send(order(nearAddressId)).expect(201);
      expect(retry.headers['idempotent-replayed']).toBe('true');
      expect(retry.body).toMatchObject({ id: retriedOrderId, orderNumber: first.body.orderNumber });

      const changed = await http.post('/v1/orders').set(customer).set(key).send(order(nearAddressId, 5)).expect(409);
      expect(changed.body.code).toBe('IDEMPOTENCY_KEY_REUSED');
      const bad = await http.post('/v1/orders').set(customer).set('Idempotency-Key', 'x').send(order(nearAddressId)).expect(400);
      expect(bad.body.code).toBe('INVALID_IDEMPOTENCY_KEY');

      // Two taps at once still make one order.
      const race = { 'Idempotency-Key': 'checkout-race-0001' };
      const [a, b] = await Promise.all([
        http.post('/v1/orders').set(customer).set(race).send(order(nearAddressId, 2)),
        http.post('/v1/orders').set(customer).set(race).send(order(nearAddressId, 2)),
      ]);
      expect([a.status, b.status]).toEqual([201, 201]);
      expect(a.body.id).toBe(b.body.id);
      expect(await prisma.order.count({ where: { idempotencyKey: { in: ['checkout-7f3a9c21', 'checkout-race-0001'] } } })).toBe(2);
    });

    it('splits orders into active and past', async () => {
      const all = await http.get('/v1/orders').set(customer).expect(200);
      expect(all.body.total).toBe(3);
      await http.post(`/v1/orders/${retriedOrderId}/cancel`).set(customer).send({ reason: 'Changed plans' }).expect(200);

      const active = await http.get('/v1/orders').query({ scope: 'active' }).set(customer).expect(200);
      const past = await http.get('/v1/orders').query({ scope: 'past' }).set(customer).expect(200);
      expect(active.body.total).toBe(2);
      expect(past.body.items.map((o: { id: string; status: string }) => [o.id, o.status])).toEqual([[retriedOrderId, 'CANCELLED']]);
      await http.get('/v1/orders').query({ scope: 'old' }).set(customer).expect(400);
    });

    it('serves everywhere again once the area is cleared', async () => {
      await http
        .patch('/v1/admin/settings')
        .set(bearer(PHONES.superAdmin))
        .send({ serviceCenterLatitude: null, serviceCenterLongitude: null, serviceRadiusKm: null })
        .expect(200);
      const addresses = await http.get('/v1/me/addresses').set(customer).expect(200);
      expect(addresses.body.every((a: { serviceable: boolean }) => a.serviceable)).toBe(true);
    });
  });

  describe('refunds', () => {
    // The main customer pays online in two goes for an order that is then cancelled.
    let onlineOrderId: string;
    const refunds = (orderId: string) => `/v1/admin/orders/${orderId}/refunds`;
    const placeFor = (items: { catalogItemId: string; quantity: number }[], paymentMethod: 'COD' | 'ONLINE') =>
      http
        .post('/v1/orders')
        .set(bearer(PHONES.customer))
        .send({ items, pickupDate: tomorrow, pickupSlot: 'NOON', deliveryDate: dayAfter, deliverySlot: 'EVENING', pickupAddressId: addressId, paymentMethod })
        .expect(201);

    async function payOnline(orderId: string, razorpayPaymentId: string) {
      const checkout = await http.post(`/v1/orders/${orderId}/payments/razorpay`).set(bearer(PHONES.customer)).expect(201);
      const razorpayOrderId = checkout.body.razorpayOrderId as string;
      const razorpaySignature = createHmac('sha256', razorpay.keySecret).update(`${razorpayOrderId}|${razorpayPaymentId}`).digest('hex');
      await http
        .post('/v1/payments/razorpay/verify')
        .set(bearer(PHONES.customer))
        .send({ razorpayOrderId, razorpayPaymentId, razorpaySignature })
        .expect(200);
    }

    /** Refund events carry the payment too; the refund is what they are about. */
    function refundWebhook(event: 'refund.processed' | 'refund.failed', refund: { id: string; paymentId: string; amountPaise: number }) {
      const body = JSON.stringify({
        event,
        payload: {
          refund: { entity: { id: refund.id, entity: 'refund', payment_id: refund.paymentId, amount: refund.amountPaise, status: event.slice(7) } },
          payment: { entity: { id: refund.paymentId, order_id: 'order_unrelated', amount: refund.amountPaise, status: 'refunded' } },
        },
      });
      const signature = createHmac('sha256', razorpay.webhookSecret).update(body).digest('hex');
      return http.post('/v1/webhooks/razorpay').set('content-type', 'application/json').set('x-razorpay-signature', signature).send(body).expect(200);
    }

    const notificationCount = (type: string, to: 'customer' | 'staff', orderId: string) =>
      prisma.notification.count({
        where: {
          type,
          data: { path: ['orderId'], equals: orderId },
          user: to === 'customer' ? { phone: `+91${PHONES.customer}` } : { role: { in: ['ADMIN', 'SUPER_ADMIN'] } },
        },
      });

    it('refunds part of an online payment, newest payment first', async () => {
      const placed = await placeFor([{ catalogItemId: sareeId, quantity: 1 }], 'ONLINE');
      onlineOrderId = placed.body.id;
      expect(placed.body).toMatchObject({ totalPaise: 4000, refundedPaise: 0, refunds: [] });
      await payOnline(onlineOrderId, 'pay_refund_a');
      // Two more sarees counted; the customer pays the difference online.
      await http.put(`/v1/admin/orders/${onlineOrderId}/items`).set(bearer(PHONES.admin)).send({ items: [{ catalogItemId: sareeId, quantity: 3 }] }).expect(200);
      await payOnline(onlineOrderId, 'pay_refund_b');
      const cancelled = await http
        .post(`/v1/admin/orders/${onlineOrderId}/status`)
        .set(bearer(PHONES.admin))
        .send({ status: 'CANCELLED', note: 'Workshop closed for repairs' })
        .expect(200);
      expect(cancelled.body).toMatchObject({ paidPaise: 12000, refundedPaise: 0, refundablePaise: 12000, paymentStatus: 'PAID', refunds: [] });

      razorpay.queueRefunds('pending');
      const sentBefore = razorpay.refunds.length;
      const res = await http
        .post(refunds(onlineOrderId))
        .set(bearer(PHONES.admin))
        .send({ amountPaise: 1000, method: 'RAZORPAY', note: '  Sorry, our workshop was closed.  ' })
        .expect(201);
      const sent = razorpay.refunds.slice(sentBefore);
      expect(sent).toEqual([expect.objectContaining({ paymentId: 'pay_refund_b', amountPaise: 1000 })]);
      expect(res.body).toMatchObject({ status: 'CANCELLED', refundedPaise: 1000, refundablePaise: 11000, paymentStatus: 'PAID' });
      expect(res.body.refunds).toEqual([
        expect.objectContaining({
          amountPaise: 1000,
          method: 'RAZORPAY',
          status: 'PENDING',
          note: 'Sorry, our workshop was closed.',
          processedAt: null,
          failureReason: null,
          createdBy: expect.objectContaining({ name: 'Ops' }),
        }),
      ]);
      expect(sent[0].notes).toMatchObject({ orderId: onlineOrderId, orderNumber: placed.body.orderNumber, refundId: res.body.refunds[0].id });
      await waitFor(async () => (await notificationCount('refund_started', 'customer', onlineOrderId)) === 1);

      // Razorpay confirms it; a replayed webhook changes nothing.
      await refundWebhook('refund.processed', { id: sent[0].id, paymentId: 'pay_refund_b', amountPaise: 1000 });
      await refundWebhook('refund.processed', { id: sent[0].id, paymentId: 'pay_refund_b', amountPaise: 1000 });
      const after = await http.get(`/v1/admin/orders/${onlineOrderId}`).set(bearer(PHONES.admin)).expect(200);
      expect(after.body.refundedPaise).toBe(1000);
      expect(after.body.refunds[0]).toMatchObject({ status: 'PROCESSED', processedAt: expect.any(String) });
      await waitFor(async () => (await notificationCount('refund_processed', 'customer', onlineOrderId)) > 0);
      expect(await notificationCount('refund_processed', 'customer', onlineOrderId)).toBe(1);
    });

    it('refuses more than was paid, a missing note, and customers', async () => {
      const tooMuch = await http
        .post(refunds(onlineOrderId))
        .set(bearer(PHONES.admin))
        .send({ amountPaise: 11001, method: 'RAZORPAY', note: 'Full refund' })
        .expect(409);
      expect(tooMuch.body).toMatchObject({ code: 'REFUND_EXCEEDS_PAID', details: { refundablePaise: 11000 } });
      await http.post(refunds(onlineOrderId)).set(bearer(PHONES.admin)).send({ amountPaise: 100, method: 'CASH', note: '  ' }).expect(400);
      await http.post(refunds(onlineOrderId)).set(bearer(PHONES.admin)).send({ amountPaise: 0, method: 'CASH', note: 'Nothing' }).expect(400);
      await http.post(refunds(onlineOrderId)).set(bearer(PHONES.admin)).send({ amountPaise: 100, method: 'UPI', note: 'Sent' }).expect(400);
      const customer = await http
        .post(refunds(onlineOrderId))
        .set(bearer(PHONES.customer))
        .send({ amountPaise: 100, method: 'CASH', note: 'Give it back' })
        .expect(403);
      expect(customer.body.code).toBe('FORBIDDEN_ROLE');
      expect(await prisma.refund.count({ where: { orderId: onlineOrderId } })).toBe(1);
    });

    it('splits the rest across both payments and marks the order refunded', async () => {
      razorpay.queueRefunds('processed', 'pending');
      const sentBefore = razorpay.refunds.length;
      const res = await http
        .post(refunds(onlineOrderId))
        .set(bearer(PHONES.superAdmin))
        .send({ amountPaise: 11000, method: 'RAZORPAY', note: 'Refunding the rest of your order.' })
        .expect(201);
      expect(razorpay.refunds.slice(sentBefore).map((r) => [r.paymentId, r.amountPaise])).toEqual([
        ['pay_refund_b', 7000],
        ['pay_refund_a', 4000],
      ]);
      expect(res.body).toMatchObject({ refundedPaise: 12000, refundablePaise: 0, paymentStatus: 'REFUNDED' });
      expect(res.body.refunds.map((r: { amountPaise: number; status: string }) => [r.amountPaise, r.status])).toEqual([
        [1000, 'PROCESSED'],
        [7000, 'PROCESSED'],
        [4000, 'PENDING'],
      ]);
      // One notification for the whole request.
      await waitFor(async () => (await notificationCount('refund_started', 'customer', onlineOrderId)) === 2);
      const inbox = await http.get('/v1/me/notifications').set(bearer(PHONES.customer)).expect(200);
      const latest = inbox.body.items.find((n: { type: string }) => n.type === 'refund_started');
      expect(latest).toMatchObject({ title: 'Refund of ₹110 started' });
      expect(latest.body).toContain(res.body.orderNumber);
      expect(latest.body).toMatch(/Note: Refunding the rest of your order\.$/);

      const again = await http.post(refunds(onlineOrderId)).set(bearer(PHONES.admin)).send({ amountPaise: 1, method: 'CASH', note: 'One more' }).expect(409);
      expect(again.body).toMatchObject({ code: 'NOTHING_TO_REFUND', details: { refundablePaise: 0 } });
    });

    it('counts a refund Razorpay fails as not refunded', async () => {
      const failed = razorpay.refunds.at(-1)!;
      expect(failed).toMatchObject({ paymentId: 'pay_refund_a', amountPaise: 4000 });
      await refundWebhook('refund.failed', { id: failed.id, paymentId: failed.paymentId, amountPaise: 4000 });
      await refundWebhook('refund.failed', { id: failed.id, paymentId: failed.paymentId, amountPaise: 4000 });
      const res = await http.get(`/v1/admin/orders/${onlineOrderId}`).set(bearer(PHONES.admin)).expect(200);
      expect(res.body).toMatchObject({ refundedPaise: 8000, refundablePaise: 4000, paymentStatus: 'PAID' });
      expect(res.body.refunds[2]).toMatchObject({ amountPaise: 4000, status: 'FAILED', failureReason: expect.any(String) });
      await waitFor(async () => (await notificationCount('refund_failed', 'customer', onlineOrderId)) > 0);
      await waitFor(async () => (await notificationCount('refund_failed', 'staff', onlineOrderId)) > 0);
      expect(await notificationCount('refund_failed', 'customer', onlineOrderId)).toBe(1);
    });

    it('saves nothing when Razorpay refuses, then records a bank transfer instead', async () => {
      razorpay.queueRefunds(new Error('The refund amount provided is greater than amount captured'));
      const refused = await http
        .post(refunds(onlineOrderId))
        .set(bearer(PHONES.admin))
        .send({ amountPaise: 4000, method: 'RAZORPAY', note: 'Trying again' })
        .expect(502);
      expect(refused.body).toMatchObject({ code: 'REFUND_GATEWAY_ERROR', message: 'The refund amount provided is greater than amount captured' });
      expect(await prisma.refund.count({ where: { orderId: onlineOrderId } })).toBe(3);
      expect((await prisma.order.findUniqueOrThrow({ where: { id: onlineOrderId } })).refundedPaise).toBe(8000);

      const bank = await http
        .post(refunds(onlineOrderId))
        .set(bearer(PHONES.admin))
        .send({ amountPaise: 4000, method: 'BANK_TRANSFER', note: 'Sent to your UPI ID.' })
        .expect(201);
      expect(bank.body).toMatchObject({ refundedPaise: 12000, refundablePaise: 0, paymentStatus: 'REFUNDED' });
      expect(bank.body.refunds.at(-1)).toMatchObject({ method: 'BANK_TRANSFER', status: 'PROCESSED', processedAt: expect.any(String) });
    });

    it('records cash returned by hand', async () => {
      const placed = await placeFor([{ catalogItemId: shirtId, quantity: 2 }], 'COD');
      const orderId = placed.body.id as string;
      const unpaid = await http.post(refunds(orderId)).set(bearer(PHONES.admin)).send({ amountPaise: 100, method: 'CASH', note: 'Goodwill' }).expect(409);
      expect(unpaid.body.code).toBe('NOTHING_TO_REFUND');

      await http.post(`/v1/admin/orders/${orderId}/payments/cash`).set(bearer(PHONES.admin)).send({ amountPaise: 3000 }).expect(204);
      const online = await http.post(refunds(orderId)).set(bearer(PHONES.admin)).send({ amountPaise: 1000, method: 'RAZORPAY', note: 'Back to card' }).expect(409);
      expect(online.body.code).toBe('NO_ONLINE_PAYMENT');

      const res = await http
        .post(refunds(orderId))
        .set(bearer(PHONES.admin))
        .send({ amountPaise: 3000, method: 'CASH', note: 'Returned at the door.' })
        .expect(201);
      expect(res.body).toMatchObject({ paidPaise: 3000, refundedPaise: 3000, paymentStatus: 'REFUNDED', amountDuePaise: 0 });
      expect(res.body.refunds).toEqual([
        expect.objectContaining({ amountPaise: 3000, method: 'CASH', status: 'PROCESSED', processedAt: expect.any(String) }),
      ]);
      await waitFor(async () => (await prisma.auditLog.count({ where: { action: 'order.refunded', entityId: orderId } })) === 1);
      await waitFor(async () => (await notificationCount('refund_processed', 'customer', orderId)) === 1);
      const inbox = await http.get('/v1/me/notifications').set(bearer(PHONES.customer)).expect(200);
      const sent = inbox.body.items.find((n: { type: string; data: { orderId?: string } }) => n.type === 'refund_processed' && n.data.orderId === orderId);
      expect(sent).toMatchObject({
        title: '₹30 refunded',
        body: `We've returned ₹30 for order ${placed.body.orderNumber} by cash.\nNote: Returned at the door.`,
      });
    });

    it('shows the customer each refund with its note', async () => {
      const res = await http.get(`/v1/orders/${onlineOrderId}`).set(bearer(PHONES.customer)).expect(200);
      expect(res.body).toMatchObject({ refundedPaise: 12000, paymentStatus: 'REFUNDED' });
      expect(res.body.refundablePaise).toBeUndefined();
      expect(res.body.refunds.map((r: { amountPaise: number; method: string; status: string; note: string }) => [r.amountPaise, r.method, r.status, r.note])).toEqual([
        [1000, 'RAZORPAY', 'PROCESSED', 'Sorry, our workshop was closed.'],
        [7000, 'RAZORPAY', 'PROCESSED', 'Refunding the rest of your order.'],
        [4000, 'RAZORPAY', 'FAILED', 'Refunding the rest of your order.'],
        [4000, 'BANK_TRANSFER', 'PROCESSED', 'Sent to your UPI ID.'],
      ]);
      // Staff names stay in the admin.
      expect(res.body.refunds.every((r: object) => !('createdBy' in r))).toBe(true);
      const list = await http.get('/v1/orders').query({ scope: 'past' }).set(bearer(PHONES.customer)).expect(200);
      expect(list.body.items.find((o: { id: string }) => o.id === onlineOrderId).refunds).toHaveLength(4);
    });
  });

  describe('image uploads', () => {
    it('stores a cleaned, resized WebP and serves it to other origins', async () => {
      const png = await sharp({ create: { width: 2400, height: 1200, channels: 3, background: '#0f3057' } }).png().toBuffer();
      const res = await http
        .post('/v1/admin/uploads/images')
        .set(bearer(PHONES.admin))
        .field('purpose', 'banner')
        .attach('file', png, { filename: 'offer.png', contentType: 'image/png' })
        .expect(201);
      expect(res.body).toMatchObject({ width: 1600, height: 800 });
      expect(res.body.url).toMatch(/^http:\/\/localhost:4999\/uploads\/banner\/\d{4}\/\d{2}\/[0-9a-f-]+\.webp$/);

      const path = new URL(res.body.url).pathname;
      const file = await http.get(path).expect(200);
      expect(file.headers['content-type']).toBe('image/webp');
      expect(file.headers['cross-origin-resource-policy']).toBe('cross-origin');

      // The uploaded URL is accepted where image links go.
      await http.post('/v1/admin/banners').set(bearer(PHONES.admin)).send({ imageUrl: res.body.url }).expect(201);
      await http.post('/v1/admin/banners').set(bearer(PHONES.admin)).send({ imageUrl: 'http://example.com/x.png' }).expect(400);
    });

    it('rejects non-images and non-admins', async () => {
      const fake = await http
        .post('/v1/admin/uploads/images')
        .set(bearer(PHONES.admin))
        .field('purpose', 'catalog')
        .attach('file', Buffer.from('not really an image'), { filename: 'shirt.png', contentType: 'image/png' })
        .expect(400);
      expect(fake.body.code).toBe('INVALID_IMAGE');
      await http.post('/v1/admin/uploads/images').set(bearer(PHONES.admin)).field('purpose', 'catalog').expect(400);
      await http.post('/v1/admin/uploads/images').set(bearer(PHONES.admin)).field('purpose', 'avatar').attach('file', Buffer.from('x'), 'a.png').expect(400);
      await http.post('/v1/admin/uploads/images').set(bearer(PHONES.customer)).field('purpose', 'catalog').expect(403);
    });
  });

  describe('account deletion', () => {
    it('blocks deletion while orders are in progress', async () => {
      const res = await http.delete('/v1/me').set(bearer(PHONES.customer)).expect(409);
      expect(res.body.code).toBe('ACTIVE_ORDERS');
    });

    it('erases personal data and frees the phone number', async () => {
      await session(PHONES.leaver, 'CUSTOMER').expect(200);
      await http.patch('/v1/me').set(bearer(PHONES.leaver)).send({ name: 'Temp', email: 'temp@example.com' }).expect(200);
      await http.delete('/v1/me').set(bearer(PHONES.leaver)).expect(204);
      await http.get('/v1/me').set(bearer(PHONES.leaver)).expect(401);
      const again = await session(PHONES.leaver, 'CUSTOMER').expect(200);
      expect(again.body).toMatchObject({ name: null, email: null });
      const erased = await prisma.user.count({ where: { deletedAt: { not: null }, name: null, phone: { startsWith: 'deleted:' } } });
      expect(erased).toBe(1);
    });
  });
});
