import { createHmac, randomUUID } from 'node:crypto';
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
import { FirebaseService } from '../src/auth/firebase.service.js';
import { addDays, istDate, slotStart } from '../src/common/time.js';
import { TimeSlot } from '../src/generated/prisma/enums.js';
import { JobScheduler } from '../src/jobs/job-scheduler.js';
import { RazorpayGateway } from '../src/payments/razorpay.gateway.js';
import { PrismaService } from '../src/prisma/prisma.service.js';
import { FakeFirebase, FakeMessaging, FakeRazorpay, MemoryScheduler, waitFor } from './support.js';

const PHONES = {
  superAdmin: '9000000000',
  admin: '9000000001',
  driver1: '9111111111',
  driver2: '9222222222',
  customer: '9333333333',
  otherCustomer: '9444444444',
  leaver: '9555555555',
  asked: '9666666666',
};
const bearer = (phone: string) => ({ Authorization: `Bearer dev:${phone}` });

describe('Laundry API (e2e)', () => {
  let app: INestApplication;
  let prisma: PrismaService;
  const jobs = new MemoryScheduler();
  const razorpay = new FakeRazorpay();
  const firebase = new FakeFirebase();
  const fcm = new FakeMessaging();
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
      .overrideProvider(FirebaseService)
      .useValue(firebase)
      .compile();
    app = moduleRef.createNestApplication({ rawBody: true, logger: false });
    configureApp(app);
    await app.init();
    prisma = app.get(PrismaService);
    http = request(app.getHttpServer());

    await prisma.user.create({ data: { phone: `+91${PHONES.superAdmin}`, name: 'Owner', role: 'SUPER_ADMIN' } });
    // The suite books many orders into the same windows; the capacity rules have their own section below, which sets a cap.
    await prisma.businessSettings.update({ where: { id: 1 }, data: { dispatchBatchSize: 3, pickupCapacityPerSlot: null } });
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
      expect(res.body).toMatchObject({ phone: `+91${PHONES.customer}`, phoneVerified: true, role: 'CUSTOMER', isProfileComplete: false });
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
      const request = res.body.adjustments.find((a: { status: string }) => a.status === 'PENDING_CUSTOMER');
      expect(request).toBeDefined();
      const accepted = await http.post(`/v1/orders/${order1Id}/adjustments/${request.id}/approve`).set(bearer(PHONES.customer)).expect(200);
      // 5×1500 + 4000 = 11500, minus 10% = 10350
      expect(accepted.body).toMatchObject({ subtotalPaise: 11500, discountPaise: 1150, totalPaise: 10350 });
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
        'PICKUP_ASSIGNED', // proposed count, accepted bill unchanged
        'PICKUP_ASSIGNED', // customer approved the proposed bill
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

    const payInFull = async (orderId: string, paymentId: string) => {
      const checkout = await http.post(`/v1/orders/${orderId}/payments/razorpay`).set(bearer(PHONES.customer)).expect(201);
      const rpOrder = checkout.body.razorpayOrderId as string;
      const signature = createHmac('sha256', razorpay.keySecret).update(`${rpOrder}|${paymentId}`).digest('hex');
      await http
        .post('/v1/payments/razorpay/verify')
        .set(bearer(PHONES.customer))
        .send({ razorpayOrderId: rpOrder, razorpayPaymentId: paymentId, razorpaySignature: signature })
        .expect(200);
    };

    it('lets an unpaid online order become cash on delivery, but not a paid one or someone else\'s', async () => {
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
      await payInFull(paid.id, 'pay_2');
      const refused = await http.post(`/v1/orders/${paid.id}/pay-on-delivery`).set(bearer(PHONES.customer)).expect(409);
      expect(refused.body.code).toBe('ALREADY_PAID');
    });

    it('tells staff a refund is owed when a paid order is cancelled', async () => {
      const order = await placeOnline();
      await payInFull(order.id, 'pay_3');
      await http.post(`/v1/orders/${order.id}/cancel`).set(bearer(PHONES.customer)).send({ reason: 'Changed my mind' }).expect(200);

      // Notifications are written by an event handler, a moment after the response.
      let found = false;
      for (let attempt = 0; attempt < 20 && !found; attempt++) {
        const inbox = await http.get('/v1/me/notifications').set(bearer(PHONES.admin)).expect(200);
        found = inbox.body.items.some((n: { type: string; data: { orderId?: string } }) => n.type === 'refund_needed' && n.data.orderId === order.id);
        if (!found) await new Promise((resolve) => setTimeout(resolve, 50));
      }
      expect(found).toBe(true);
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

      // Staff can still take a phone order there, once they type why (the full rules are in "staff phone orders and capacity" below).
      const me = await http.get('/v1/me').set(customer).expect(200);
      const noReason = await http.post('/v1/admin/orders').set(bearer(PHONES.admin)).send({ ...order(farAddressId), customerId: me.body.id }).expect(400);
      expect(noReason.body.code).toBe('ADDRESS_NOT_SERVICEABLE');
      await http.post('/v1/admin/orders').set(bearer(PHONES.admin)).send({ ...order(farAddressId), customerId: me.body.id, outsideAreaReason: 'Regular customer, partner passes there' }).expect(201);

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

  it('replays a committed staff order and refuses a changed draft with the same key', async () => {
    const me = await http.get('/v1/me').set(bearer(PHONES.customer)).expect(200);
    const draft = { customerId: me.body.id, items: [{ catalogItemId: shirtId, quantity: 2 }],
      pickupDate: tomorrow, pickupSlot: 'MORNING', deliveryDate: dayAfter, deliverySlot: 'EVENING', pickupAddressId: addressId, paymentMethod: 'COD' };
    const send = (quantity = 2) => http.post('/v1/admin/orders').set(bearer(PHONES.admin)).set('Idempotency-Key', 'staff-response-loss-1')
      .send({ ...draft, items: [{ catalogItemId: shirtId, quantity }] });
    const first = await send().expect(201);
    const replay = await send().expect(201);
    expect(replay.body.id).toBe(first.body.id);
    expect(replay.headers['idempotent-replayed']).toBe('true');
    expect((await send(3).expect(409)).body.code).toBe('IDEMPOTENCY_KEY_REUSED');
  });

  describe('customer-approved bill changes', () => {
    const draft = () => ({ items: [{ catalogItemId: shirtId, quantity: 2 }], pickupDate: tomorrow, pickupSlot: 'MORNING',
      deliveryDate: dayAfter, deliverySlot: 'EVENING', pickupAddressId: addressId, paymentMethod: 'COD' });
    const create = () => http.post('/v1/orders').set(bearer(PHONES.customer)).send(draft()).expect(201);
    const edit = (id: string, revision: number, quantity = 3) => http.put(`/v1/admin/orders/${id}/items`).set(bearer(PHONES.admin))
      .send({ items: [{ catalogItemId: shirtId, quantity }], expectedRevision: revision, note: 'One extra shirt counted' });
    const decide = (id: string, requestId: string, decision = 'approve', phone = PHONES.customer) =>
      http.post(`/v1/orders/${id}/adjustments/${requestId}/${decision}`).set(bearer(phone));

    it('freezes rates, requests approval, checks ownership and blocks collection until decided', async () => {
      const placed = await create();
      const originalRate = await prisma.catalogItem.findUniqueOrThrow({ where: { id: shirtId } });
      await prisma.catalogItem.update({ where: { id: shirtId }, data: { pricePaise: originalRate.pricePaise + 1000 } });
      try {
        const proposed = await edit(placed.body.id, placed.body.revision).expect(200);
        const adjustment = proposed.body.adjustments[0];
        expect(proposed.body.totalPaise).toBe(placed.body.totalPaise);
        expect(proposed.body.items[0].quantity).toBe(2);
        expect(adjustment.itemsAfter[0].unitPricePaise).toBe(originalRate.pricePaise);
        expect(adjustment.newTotalPaise).toBe(originalRate.pricePaise * 3);
        await decide(placed.body.id, adjustment.id, 'approve', PHONES.otherCustomer).expect(404);
        expect((await http.post(`/v1/admin/orders/${placed.body.id}/payments/cash`).set(bearer(PHONES.admin)).send({ amountPaise: 100 }).expect(409)).body.code).toBe('APPROVAL_PENDING');
        await http.post(`/v1/orders/${placed.body.id}/payments/razorpay`).set(bearer(PHONES.customer)).expect(409);
        await edit(placed.body.id, proposed.body.revision).expect(409);
        const accepted = await decide(placed.body.id, adjustment.id).expect(200);
        expect(accepted.body.totalPaise).toBe(adjustment.newTotalPaise);
        expect(accepted.body.items[0].quantity).toBe(3);
        const replay = await decide(placed.body.id, adjustment.id).expect(200);
        expect(replay.body.revision).toBe(accepted.body.revision);
        expect((await edit(placed.body.id, placed.body.revision, 1).expect(409)).body.code).toBe('ORDER_CHANGED');
      } finally {
        await prisma.catalogItem.update({ where: { id: shirtId }, data: { pricePaise: originalRate.pricePaise } });
      }
    });

    it('decline and expiry preserve the original bill; decreases apply immediately', async () => {
      const placed = await create();
      const proposed = await edit(placed.body.id, placed.body.revision).expect(200);
      const declined = await decide(placed.body.id, proposed.body.adjustments[0].id, 'decline').expect(200);
      expect(declined.body.totalPaise).toBe(placed.body.totalPaise);
      await decide(placed.body.id, proposed.body.adjustments[0].id, 'decline').expect(200);
      await decide(placed.body.id, proposed.body.adjustments[0].id).expect(409);
      const second = await edit(placed.body.id, declined.body.revision).expect(200);
      await prisma.orderAdjustment.update({ where: { id: second.body.adjustments[0].id }, data: { expiresAt: new Date(Date.now() - 1000) } });
      await jobs.run('adjustments-expire');
      const expired = await http.get(`/v1/orders/${placed.body.id}`).set(bearer(PHONES.customer)).expect(200);
      expect(expired.body.adjustments[0].status).toBe('EXPIRED');
      expect(expired.body.totalPaise).toBe(placed.body.totalPaise);
      const decreased = await edit(placed.body.id, expired.body.revision, 1).expect(200);
      expect(decreased.body.totalPaise).toBe(placed.body.totalPaise / 2);
    });

    it('allows only one concurrent replacement of a displayed revision', async () => {
      const placed = await create();
      const responses = await Promise.all([edit(placed.body.id, placed.body.revision), edit(placed.body.id, placed.body.revision, 4)]);
      expect(responses.map((r) => r.status).sort()).toEqual([200, 409]);
      expect(await prisma.orderAdjustment.count({ where: { orderId: placed.body.id, status: 'PENDING_CUSTOMER' } })).toBe(1);
    });
  });

  describe('travel charge and the Rs 200 rule', () => {
    // Travel costs Rs 30 under Rs 200 of clothes (counted before any coupon) and is free from Rs 200. Prices: saree Rs 40, shirt Rs 15.
    const setRule = (body: { deliveryFeePaise: number; freeDeliveryAbovePaise: number | null }) =>
      http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send(body).expect(200);
    const items = (sarees: number, shirts = 0) => [
      ...(sarees ? [{ catalogItemId: sareeId, quantity: sarees }] : []),
      ...(shirts ? [{ catalogItemId: shirtId, quantity: shirts }] : []),
    ];
    const quote = async (lines: ReturnType<typeof items>, promoCode?: string) =>
      (await http.post('/v1/orders/quote').set(bearer(PHONES.customer)).send({ items: lines, promoCode }).expect(200)).body;
    // A window of their own, so these orders never fill the pickup window other sections book into (each window holds a few pickups).
    const placed: string[] = [];
    const place = async (lines: ReturnType<typeof items>) => {
      const order = (await http.post('/v1/orders').set(bearer(PHONES.customer)).send({ items: lines, pickupDate: addDays(tomorrow, 11), pickupSlot: 'NOON',
        deliveryDate: addDays(tomorrow, 12), deliverySlot: 'EVENING', pickupAddressId: addressId, paymentMethod: 'COD' }).expect(201)).body;
      placed.push(order.id);
      return order;
    };
    const orderPath = (id: string) => `/v1/admin/orders/${id}`;
    const editItems = (id: string, lines: ReturnType<typeof items>, revision: number) =>
      http.put(`${orderPath(id)}/items`).set(bearer(PHONES.admin)).send({ items: lines, expectedRevision: revision, note: 'Recounted at pickup' });
    const payCash = (id: string, amountPaise: number) => http.post(`${orderPath(id)}/payments/cash`).set(bearer(PHONES.admin)).send({ amountPaise }).expect(204);
    const cancel = (id: string, body: Record<string, unknown> = {}) => http.post(`${orderPath(id)}/status`).set(bearer(PHONES.admin)).send({ status: 'CANCELLED', ...body });
    const refundDueIds = async () => (await http.get('/v1/admin/orders').set(bearer(PHONES.admin)).query({ refundDue: 'true', pageSize: 100 }).expect(200)).body.items.map((o: { id: string }) => o.id);

    beforeAll(async () => {
      await setRule({ deliveryFeePaise: 3000, freeDeliveryAbovePaise: 20_000 });
      await http.post('/v1/admin/promotions').set(bearer(PHONES.admin)).send({ code: 'TRAVEL10', title: '10% off', discountType: 'PERCENT', discountValue: 10,
        minOrderPaise: 0, validFrom: new Date(Date.now() - 60_000).toISOString(), validTo: new Date(Date.now() + 86_400_000).toISOString() }).expect(201);
    });
    afterAll(async () => {
      await setRule({ deliveryFeePaise: 0, freeDeliveryAbovePaise: null });
      await prisma.order.updateMany({ where: { id: { in: placed }, status: { in: ['PENDING', 'PICKUP_ASSIGNED'] } }, data: { status: 'CANCELLED' } });
    });

    it('quotes the charge and how much more of clothes makes travel free', async () => {
      expect(await quote(items(1))).toMatchObject({ subtotalPaise: 4000, deliveryFeePaise: 3000, totalPaise: 7000, freeTravelShortfallPaise: 16_000, canPlaceOrder: true });
      expect(await quote(items(5))).toMatchObject({ subtotalPaise: 20_000, deliveryFeePaise: 0, totalPaise: 20_000, freeTravelShortfallPaise: null });
      expect(await quote(items(4, 1))).toMatchObject({ subtotalPaise: 17_500, deliveryFeePaise: 3000, freeTravelShortfallPaise: 2500 }); // Rs 175
    });

    it('counts the items total before the coupon', async () => {
      // Rs 210 of clothes less 10% is Rs 189 after the coupon, yet travel stays free.
      const bigger = await quote(items(3, 6), 'TRAVEL10');
      expect(bigger).toMatchObject({ subtotalPaise: 21_000, discountPaise: 2100, deliveryFeePaise: 0, totalPaise: 18_900, freeTravelShortfallPaise: null, promoError: null });
      // Rs 190 of clothes is charged, with or without the coupon.
      expect(await quote(items(1, 10))).toMatchObject({ subtotalPaise: 19_000, deliveryFeePaise: 3000, totalPaise: 22_000, freeTravelShortfallPaise: 1000 });
      expect(await quote(items(1, 10), 'TRAVEL10')).toMatchObject({ discountPaise: 1900, deliveryFeePaise: 3000, totalPaise: 20_100, freeTravelShortfallPaise: 1000 });
    });

    it('does not block a small order, and leaves the hard minimum to its own setting', async () => {
      expect(await quote(items(0, 1))).toMatchObject({ minOrderShortfallPaise: null, canPlaceOrder: true });
      await http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send({ minOrderPaise: 5000 }).expect(200);
      try {
        expect(await quote(items(0, 1))).toMatchObject({ minOrderShortfallPaise: 3500, canPlaceOrder: false });
      } finally {
        await http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send({ minOrderPaise: 0 }).expect(200);
      }
    });

    it('freezes the rule on the order, so later settings changes never alter it', async () => {
      const placed = await place(items(1));
      expect(placed).toMatchObject({ subtotalPaise: 4000, deliveryFeePaise: 3000, totalPaise: 7000, travelChargeKept: false });
      const row = await prisma.order.findUniqueOrThrow({ where: { id: placed.id } });
      expect(row).toMatchObject({ travelChargePaiseRule: 3000, travelFreeFromPaiseRule: 20_000 });

      await setRule({ deliveryFeePaise: 5000, freeDeliveryAbovePaise: 10_000 });
      try {
        const same = await http.get(`/v1/orders/${placed.id}`).set(bearer(PHONES.customer)).expect(200);
        expect(same.body).toMatchObject({ deliveryFeePaise: 3000, totalPaise: 7000 });
        // Rs 120 of clothes would be free under today's settings (free from Rs 100); the order keeps its booked rule (free from Rs 200).
        const preview = await http.post(`${orderPath(placed.id)}/items/quote`).set(bearer(PHONES.admin)).send({ items: items(3) }).expect(200);
        expect(preview.body).toMatchObject({ subtotalPaise: 12_000, deliveryFeePaise: 3000, oldDeliveryFeePaise: 3000, newTotalPaise: 15_000 });
      } finally {
        await setRule({ deliveryFeePaise: 3000, freeDeliveryAbovePaise: 20_000 });
      }
    });

    it('re-checks the charge on the counted items, both ways, and asks the customer only for a net increase', async () => {
      const placed = await place(items(5)); // Rs 200, free
      expect(placed).toMatchObject({ deliveryFeePaise: 0, totalPaise: 20_000 });

      // Counted as 4 at pickup: Rs 160 plus the Rs 30 charge is Rs 190, less than Rs 200, so it applies at once.
      const preview = await http.post(`${orderPath(placed.id)}/items/quote`).set(bearer(PHONES.admin)).send({ items: items(4), expectedRevision: placed.revision }).expect(200);
      expect(preview.body).toMatchObject({ oldDeliveryFeePaise: 0, deliveryFeePaise: 3000, oldTotalPaise: 20_000, newTotalPaise: 19_000, requiresApproval: false });
      const fewer = await editItems(placed.id, items(4), placed.revision).expect(200);
      expect(fewer.body).toMatchObject({ subtotalPaise: 16_000, deliveryFeePaise: 3000, totalPaise: 19_000 });
      expect(fewer.body.adjustments).toHaveLength(0);
      await waitFor(async () => (await prisma.notification.count({ where: { type: 'order_updated', data: { path: ['orderId'], equals: placed.id } } })) === 1);
      const notice = await prisma.notification.findFirstOrThrow({ where: { type: 'order_updated', data: { path: ['orderId'], equals: placed.id } } });
      expect(notice.body).toContain('includes a ₹30 travel charge');

      // Counted back up to 5: Rs 200 and free again is Rs 200, more than Rs 190, so the customer decides, and sees the charge go.
      const more = await editItems(placed.id, items(5), fewer.body.revision).expect(200);
      expect(more.body).toMatchObject({ deliveryFeePaise: 3000, totalPaise: 19_000 }); // not applied until approved
      const request = more.body.adjustments[0];
      expect(request).toMatchObject({ status: 'PENDING_CUSTOMER', oldTotalPaise: 19_000, newTotalPaise: 20_000, subtotalPaise: 20_000, deliveryFeePaise: 0 });
      const approved = await http.post(`/v1/orders/${placed.id}/adjustments/${request.id}/approve`).set(bearer(PHONES.customer)).expect(200);
      expect(approved.body).toMatchObject({ deliveryFeePaise: 0, totalPaise: 20_000 });
    });

    it('lets an order booked before the rule keep its stored fee', async () => {
      const placed = await place(items(1));
      await prisma.order.update({ where: { id: placed.id }, data: { travelChargePaiseRule: null, travelFreeFromPaiseRule: null } });
      const bigger = await editItems(placed.id, items(5), placed.revision).expect(200); // Rs 200 would be free under the rule
      expect(bigger.body.adjustments[0]).toMatchObject({ deliveryFeePaise: 3000, newTotalPaise: 23_000 });
      const preview = await http.post(`${orderPath(placed.id)}/items/quote`).set(bearer(PHONES.admin)).send({ items: items(0, 1) }).expect(200);
      expect(preview.body).toMatchObject({ oldDeliveryFeePaise: 3000, deliveryFeePaise: 3000 });
    });

    describe('cancelling', () => {
      const paidAndCancelled = async (body: Record<string, unknown>, paid = 7000) => {
        const placed = await place(items(1)); // Rs 40 plus the Rs 30 charge
        if (paid > 0) await payCash(placed.id, paid);
        return { placed, response: await cancel(placed.id, body) };
      };

      it('refunds everything paid by default, the travel charge included', async () => {
        const { placed, response } = await paidAndCancelled({ note: 'Changed their mind' });
        expect(response.status).toBe(200);
        expect(response.body).toMatchObject({ status: 'CANCELLED', travelChargeKept: false, paidPaise: 7000, refundablePaise: 7000 });
        expect(await refundDueIds()).toContain(placed.id);
        const customerView = await http.get(`/v1/orders/${placed.id}`).set(bearer(PHONES.customer)).expect(200);
        expect(customerView.body.travelChargeKept).toBe(false);

        await http.post(`${orderPath(placed.id)}/refunds`).set(bearer(PHONES.admin)).send({ amountPaise: 7000, method: 'CASH', note: 'Returned in cash' }).expect(201);
        const done = await http.get(orderPath(placed.id)).set(bearer(PHONES.admin)).expect(200);
        expect(done.body).toMatchObject({ paymentStatus: 'REFUNDED', refundedPaise: 7000, refundablePaise: 0 });
        expect(await refundDueIds()).not.toContain(placed.id);
      });

      it('keeps the charge when staff say the partner had already travelled', async () => {
        const { placed, response } = await paidAndCancelled({ note: 'Nobody home', keepTravelCharge: true });
        expect(response.status).toBe(200);
        expect(response.body).toMatchObject({ status: 'CANCELLED', travelChargeKept: true, deliveryFeePaise: 3000, paidPaise: 7000, refundablePaise: 4000, paymentStatus: 'PAID' });
        const history = await http.get(orderPath(placed.id)).set(bearer(PHONES.admin)).expect(200);
        expect(history.body.events.at(-1)).toMatchObject({ toStatus: 'CANCELLED', note: 'Nobody home. Travel charge kept: partner had already travelled' });
        const stored = await prisma.order.findUniqueOrThrow({ where: { id: placed.id } });
        expect(stored.travelChargeKept).toBe(true);

        // The customer's own view says why.
        const customerView = await http.get(`/v1/orders/${placed.id}`).set(bearer(PHONES.customer)).expect(200);
        expect(customerView.body).toMatchObject({ travelChargeKept: true, status: 'CANCELLED' });

        // The refund due is Rs 40, on the list and on the dashboard, and the staff alert says Rs 40.
        const due = await http.get('/v1/admin/orders').set(bearer(PHONES.admin)).query({ refundDue: 'true', pageSize: 100 }).expect(200);
        expect(due.body.items.map((o: { id: string }) => o.id)).toContain(placed.id);
        expect((await http.get('/v1/admin/dashboard').set(bearer(PHONES.admin)).expect(200)).body.refundsDue).toBe(due.body.total);
        await waitFor(async () => (await prisma.notification.count({ where: { type: 'refund_needed', data: { path: ['orderId'], equals: placed.id } } })) > 0);
        const alert = await prisma.notification.findFirstOrThrow({ where: { type: 'refund_needed', data: { path: ['orderId'], equals: placed.id } } });
        expect(alert.body).toContain('₹40');
        expect(alert.body).not.toContain('₹70');

        // A refund cannot take the charge back; the rest can go, and then the order is refunded and off the list.
        const tooMuch = await http.post(`${orderPath(placed.id)}/refunds`).set(bearer(PHONES.admin)).send({ amountPaise: 7000, method: 'CASH', note: 'All of it' }).expect(409);
        expect(tooMuch.body).toMatchObject({ code: 'REFUND_EXCEEDS_PAID', details: { refundablePaise: 4000 } });
        await http.post(`${orderPath(placed.id)}/refunds`).set(bearer(PHONES.admin)).send({ amountPaise: 4000, method: 'CASH', note: 'Clothes charge returned' }).expect(201);
        const done = await http.get(orderPath(placed.id)).set(bearer(PHONES.admin)).expect(200);
        expect(done.body).toMatchObject({ paymentStatus: 'REFUNDED', refundedPaise: 4000, refundablePaise: 0, travelChargeKept: true });
        expect(await refundDueIds()).not.toContain(placed.id);
        expect((await http.post(`${orderPath(placed.id)}/refunds`).set(bearer(PHONES.admin)).send({ amountPaise: 100, method: 'CASH', note: 'More' }).expect(409)).body.code).toBe('NOTHING_TO_REFUND');
      });

      it('owes nothing when no more than the kept charge was paid, or nothing at all', async () => {
        const small = await paidAndCancelled({ keepTravelCharge: true }, 1000);
        expect(small.response.body).toMatchObject({ travelChargeKept: true, paidPaise: 1000, refundablePaise: 0 });
        const unpaid = await paidAndCancelled({ keepTravelCharge: true }, 0);
        expect(unpaid.response.body).toMatchObject({ travelChargeKept: true, paidPaise: 0, refundablePaise: 0 });
        const due = await refundDueIds();
        expect(due).not.toContain(small.placed.id);
        expect(due).not.toContain(unpaid.placed.id);
      });

      it('only keeps a charge there is, and only on a cancellation', async () => {
        const free = await place(items(5));
        expect((await cancel(free.id, { keepTravelCharge: true }).expect(400)).body.code).toBe('NO_TRAVEL_CHARGE');
        expect((await http.get(orderPath(free.id)).set(bearer(PHONES.admin)).expect(200)).body.status).toBe('PENDING');

        const charged = await place(items(1));
        const wrong = await http.post(`${orderPath(charged.id)}/status`).set(bearer(PHONES.admin)).send({ status: 'PROCESSING', keepTravelCharge: true }).expect(400);
        expect(wrong.body.code).toBe('KEEP_ONLY_WITH_CANCEL');
      });

      it('never keeps the charge when the customer cancels', async () => {
        const placed = await place(items(1));
        await payCash(placed.id, 7000);
        const res = await http.post(`/v1/orders/${placed.id}/cancel`).set(bearer(PHONES.customer)).send({ reason: 'Changed my mind' }).expect(200);
        expect(res.body).toMatchObject({ status: 'CANCELLED', travelChargeKept: false });
        expect((await http.get(orderPath(placed.id)).set(bearer(PHONES.admin)).expect(200)).body.refundablePaise).toBe(7000);
      });
    });
  });

  describe('order-linked problem reports', () => {
    let reportId: string;
    let ownPhoto: string;
    it('accepts a cleaned customer image and refuses another customer’s photo or order', async () => {
      const image = await sharp({ create: { width: 30, height: 20, channels: 3, background: '#123456' } }).png().toBuffer();
      const uploaded = await http.post('/v1/me/uploads/images').set(bearer(PHONES.customer)).attach('file', image, 'garment.png').expect(201);
      ownPhoto = uploaded.body.url;
      expect(ownPhoto).toContain('/issues/');
      await http.post('/v1/me/uploads/images').set(bearer(PHONES.customer)).attach('file', Buffer.from('not an image'), 'fake.jpg').expect(400);
      await http.post(`/v1/orders/${order1Id}/issues`).set(bearer(PHONES.otherCustomer)).send({ category: 'MISSING_ITEM', description: 'Not mine' }).expect(404);
      const reportBody = { category: 'MISSING_ITEM', description: 'One shirt is missing', photoUrls: [ownPhoto] };
      const reportKey = 'missing-shirt-20261115';
      const created = await http.post(`/v1/orders/${order1Id}/issues`).set(bearer(PHONES.customer)).set('Idempotency-Key', reportKey)
        .send(reportBody).expect(201);
      reportId = created.body.id;
      expect(created.body).toMatchObject({ status: 'OPEN', firstResponseDueAt: null, description: 'One shirt is missing', photoUrls: [ownPhoto], messages: [] });
      const replay = await http.post(`/v1/orders/${order1Id}/issues`).set(bearer(PHONES.customer)).set('Idempotency-Key', reportKey)
        .send(reportBody).expect(201);
      expect(replay.body.id).toBe(reportId);
      expect(replay.headers['idempotent-replayed']).toBe('true');
      expect(await prisma.orderIssue.count({ where: { orderId: order1Id, requestKey: reportKey } })).toBe(1);
      await http.post(`/v1/orders/${order1Id}/issues`).set(bearer(PHONES.customer)).set('Idempotency-Key', reportKey)
        .send({ ...reportBody, description: 'A different report' }).expect(409);
      await http.get(`/v1/me/issues/${reportId}`).set(bearer(PHONES.otherCustomer)).expect(404);
      await http.post(`/v1/me/issues/${reportId}/messages`).set(bearer(PHONES.otherCustomer)).send({ body: 'Not mine' }).expect(404);
      expect((await http.get('/v1/me/issues').set(bearer(PHONES.otherCustomer)).expect(200)).body.items).toEqual([]);
      const other = await prisma.user.findUniqueOrThrow({ where: { phone: `+91${PHONES.otherCustomer}` } });
      const badUrl = ownPhoto.replace((await prisma.user.findUniqueOrThrow({ where: { phone: `+91${PHONES.customer}` } })).id, other.id);
      await http.post(`/v1/orders/${order1Id}/issues`).set(bearer(PHONES.customer)).send({ category: 'DAMAGED', description: 'Check', photoUrls: [badUrl] }).expect(400);
      await http.get('/v1/admin/issues').set(bearer(PHONES.customer)).expect(403);
    });
    it('keeps a two-way thread, requires a resolution and preserves ownership', async () => {
      const reply = await http.post(`/v1/admin/issues/${reportId}/messages`).set(bearer(PHONES.admin)).send({ body: 'We are checking the intake count.' }).expect(200);
      expect(reply.body.status).toBe('ACKNOWLEDGED');
      expect(reply.body.messages[0]).toMatchObject({ fromStaff: true, body: 'We are checking the intake count.' });
      expect(reply.body.handledById).toBeTruthy();
      const mine = await http.post(`/v1/me/issues/${reportId}/messages`).set(bearer(PHONES.customer)).send({ body: 'It is a blue shirt.' }).expect(200);
      expect(mine.body.messages).toHaveLength(2);
      expect(mine.body.handledById).toBeUndefined();
      await http.patch(`/v1/admin/issues/${reportId}`).set(bearer(PHONES.admin)).send({ status: 'RESOLVED' }).expect(400);
      const resolved = await http.patch(`/v1/admin/issues/${reportId}`).set(bearer(PHONES.admin)).send({ status: 'RESOLVED', resolutionNote: 'Shirt located and returned to the customer.' }).expect(200);
      expect(resolved.body.resolvedAt).toBeTruthy();
      await http.post(`/v1/me/issues/${reportId}/messages`).set(bearer(PHONES.customer)).send({ body: 'Closed' }).expect(409);
    });
    it('only schedules and publishes a response clock when explicitly configured', async () => {
      await http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send({ issueFirstResponseHours: 1 }).expect(200);
      const issue = await http.post(`/v1/orders/${order1Id}/issues`).set(bearer(PHONES.customer)).send({ category: 'QUALITY', description: 'Please check the finish.' }).expect(201);
      expect(issue.body.firstResponseDueAt).toBeTruthy();
      await prisma.orderIssue.update({ where: { id: issue.body.id }, data: { firstResponseDueAt: new Date(Date.now() - 1000) } });
      await jobs.run('issues-first-response');
      const overdue = await http.get('/v1/admin/issues').set(bearer(PHONES.admin)).query({ overdue: true }).expect(200);
      expect(overdue.body.items.map((i: { id: string }) => i.id)).toContain(issue.body.id);
      await http.patch('/v1/admin/settings').set(bearer(PHONES.superAdmin)).send({ issueFirstResponseHours: null }).expect(200);
    });
    it('records the agreed remedy and links a refund made on the same order', async () => {
      const report = await http.post(`/v1/orders/${order1Id}/issues`).set(bearer(PHONES.customer))
        .send({ category: 'DAMAGED', description: 'A button came off.' }).expect(201);
      const url = `/v1/admin/issues/${report.body.id}`;
      // A remedy belongs to a resolved report.
      await http.patch(url).set(bearer(PHONES.admin)).send({ status: 'ACKNOWLEDGED', compensationPaise: 5000 }).expect(400);
      // A refund from another order cannot be linked.
      const otherOrder = await prisma.order.findFirstOrThrow({ where: { NOT: { id: order1Id } } });
      const foreign = await prisma.refund.create({ data: { orderId: otherOrder.id, method: 'CASH', status: 'PROCESSED', amountPaise: 3000, note: 'Not this order' } });
      await http.patch(url).set(bearer(PHONES.admin)).send({ status: 'RESOLVED', resolutionNote: 'Button refunded.', compensationPaise: 3000, refundId: foreign.id }).expect(400);
      // The refund may not exceed the remedy.
      const own = await prisma.refund.create({ data: { orderId: order1Id, method: 'CASH', status: 'PROCESSED', amountPaise: 5000, note: 'Button repair' } });
      await http.patch(url).set(bearer(PHONES.admin)).send({ status: 'RESOLVED', resolutionNote: 'Button refunded.', compensationPaise: 4000, refundId: own.id }).expect(400);
      const resolved = await http.patch(url).set(bearer(PHONES.admin))
        .send({ status: 'RESOLVED', resolutionNote: 'Button refunded.', compensationPaise: 5000, refundId: own.id }).expect(200);
      expect(resolved.body).toMatchObject({ compensationPaise: 5000, refundId: own.id });
      // The customer sees the amount, not the staff-side link.
      const mine = await http.get(`/v1/me/issues/${report.body.id}`).set(bearer(PHONES.customer)).expect(200);
      expect(mine.body.compensationPaise).toBe(5000);
      expect(mine.body.refundId).toBeUndefined();
      // Reopening clears the remedy with the resolution.
      const reopened = await http.patch(url).set(bearer(PHONES.admin)).send({ status: 'ACKNOWLEDGED' }).expect(200);
      expect(reopened.body).toMatchObject({ compensationPaise: null, refundId: null });
      // These refunds were inserted directly; remove them so the refund tests below start from the same books.
      await prisma.refund.deleteMany({ where: { id: { in: [foreign.id, own.id] } } });
    });
    it('allows a billing report after an order is cancelled', async () => {
      const placed = await http.post('/v1/orders').set(bearer(PHONES.customer)).send({
        items: [{ catalogItemId: shirtId, quantity: 1 }], pickupDate: tomorrow, pickupSlot: 'NOON',
        deliveryDate: dayAfter, deliverySlot: 'EVENING', pickupAddressId: addressId, paymentMethod: 'COD',
      }).expect(201);
      await http.post(`/v1/admin/orders/${placed.body.id}/status`).set(bearer(PHONES.admin))
        .send({ status: 'CANCELLED', note: 'Customer requested cancellation' }).expect(200);
      const report = await http.post(`/v1/orders/${placed.body.id}/issues`).set(bearer(PHONES.customer))
        .send({ category: 'BILLING', description: 'Please check the cancellation balance.' }).expect(201);
      expect(report.body).toMatchObject({ orderId: placed.body.id, category: 'BILLING', status: 'OPEN' });
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
      const proposed = await http.put(`/v1/admin/orders/${onlineOrderId}/items`).set(bearer(PHONES.admin)).send({ items: [{ catalogItemId: sareeId, quantity: 3 }] }).expect(200);
      await http.post(`/v1/orders/${onlineOrderId}/adjustments/${proposed.body.adjustments[0].id}/approve`).set(bearer(PHONES.customer)).expect(200);
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

  describe('rescheduling a pickup', () => {
    // Windows well ahead of today, each delivery at least the turnaround after its pickup.
    const A = { pickupDate: addDays(tomorrow, 2), pickupSlot: 'NOON', deliveryDate: addDays(tomorrow, 3), deliverySlot: 'MORNING' };
    const B = { pickupDate: addDays(tomorrow, 3), pickupSlot: 'MORNING', deliveryDate: addDays(tomorrow, 4), deliverySlot: 'EVENING' };
    const C = { pickupDate: addDays(tomorrow, 4), pickupSlot: 'EVENING', deliveryDate: addDays(tomorrow, 6), deliverySlot: 'NOON' };
    const windowOf = (w: { pickupDate: string; pickupSlot: string }) => `${w.pickupDate}|${w.pickupSlot}`;
    const BOOKED = windowOf({ pickupDate: tomorrow, pickupSlot: 'MORNING' });
    const items = () => [{ catalogItemId: shirtId, quantity: 2 }];

    const book = async () =>
      (
        await http
          .post('/v1/orders')
          .set(bearer(PHONES.customer))
          .send({ items: items(), pickupDate: tomorrow, pickupSlot: 'MORNING', deliveryDate: dayAfter, deliverySlot: 'EVENING', pickupAddressId: addressId, paymentMethod: 'COD' })
          .expect(201)
      ).body as { id: string; orderNumber: string; totalPaise: number; subtotalPaise: number };
    const move = (id: string, to: object, key?: string, phone = PHONES.customer) => {
      const req = http.post(`/v1/orders/${id}/reschedule`).set(bearer(phone));
      if (key) req.set('Idempotency-Key', key);
      return req.send(to);
    };
    const mine = async (id: string) => (await http.get(`/v1/orders/${id}`).set(bearer(PHONES.customer)).expect(200)).body;
    const staffView = async (id: string) => (await http.get(`/v1/admin/orders/${id}`).set(bearer(PHONES.admin)).expect(200)).body;
    const queuedFor = (id: string, window?: string) => jobs.queued.filter((j) => j.queue === 'dispatch-round' && (j.data as { orderId: string; window?: string }).orderId === id && (window === undefined || (j.data as { window?: string }).window === window));
    const assign = (id: string, driverId: string) =>
      http.post(`/v1/admin/orders/${id}/assign`).set(bearer(PHONES.admin)).send({ leg: 'PICKUP', driverId }).expect(200);
    const cleanUp = (...ids: string[]) =>
      Promise.all(ids.map((id) => http.post(`/v1/admin/orders/${id}/status`).set(bearer(PHONES.admin)).send({ status: 'CANCELLED', note: 'test over' }).expect(200)));

    it('moves the times, keeps the prices, and tells staff', async () => {
      const placed = await book();
      await waitFor(() => queuedFor(placed.id, BOOKED).length === 1);

      const res = await move(placed.id, A, 'resched-first-0001').expect(200);
      expect(res.body).toMatchObject({
        status: 'PENDING',
        pickupDate: A.pickupDate,
        pickupSlot: 'NOON',
        pickupSlotLabel: '11:00–16:00',
        deliveryDate: A.deliveryDate,
        deliverySlot: 'MORNING',
        rescheduleCount: 1,
        reschedulesRemaining: 1,
        canReschedule: true,
        totalPaise: placed.totalPaise,
        subtotalPaise: placed.subtotalPaise,
        paymentStatus: 'UNPAID',
      });
      expect(res.headers['idempotent-replayed']).toBeUndefined();
      // The response is the order as the customer reads it later, history included.
      expect(await mine(placed.id)).toMatchObject({ pickupDate: A.pickupDate, rescheduleCount: 1 });

      const staff = await staffView(placed.id);
      const last = staff.events.at(-1);
      expect(last).toMatchObject({ fromStatus: 'PENDING', toStatus: 'PENDING', actorRole: 'CUSTOMER' });
      expect(last.note).toMatch(/^Rescheduled by customer: pickup \w{3} \d{1,2} \w{3} 7–11 AM to \w{3} \d{1,2} \w{3} 11 AM–4 PM; delivery /);
      expect(staff).toMatchObject({ canReschedule: false, rescheduleCount: 1 }); // the customer's control, not staff's

      await waitFor(async () => (await prisma.auditLog.count({ where: { action: 'order.rescheduled', entityId: placed.id } })) === 1);
      await waitFor(async () => (await prisma.notification.count({ where: { type: 'order_rescheduled', data: { path: ['orderId'], equals: placed.id } } })) >= 1);
      const alert = await prisma.notification.findFirstOrThrow({ where: { type: 'order_rescheduled', data: { path: ['orderId'], equals: placed.id } }, include: { user: true } });
      expect(['ADMIN', 'SUPER_ADMIN']).toContain(alert.user.role);
      expect(alert.title).toBe('Pickup time changed');
      await cleanUp(placed.id);
    });

    it('queues dispatch for the new window, and the old window\'s jobs offer nothing', async () => {
      const placed = await placeAndDispatch(items());
      const oldOffer = await offerFor(PHONES.driver1, placed.id);

      await move(placed.id, A).expect(200);
      // Offers made for the old time are void: no partner can accept one and land on the new time.
      const stale = await http.post(`/v1/driver/offers/${oldOffer}/accept`).set(bearer(PHONES.driver1)).expect(409);
      expect(stale.body.code).toBe('OFFER_CLOSED');
      expect((await http.get('/v1/driver/offers').set(bearer(PHONES.driver2)).expect(200)).body.some((o: { orderId: string }) => o.orderId === placed.id)).toBe(false);

      // A fresh job for the new window, due the lead time before it starts (not at once: it is days away).
      await waitFor(() => queuedFor(placed.id, windowOf(A)).length === 1);
      const settings = await prisma.businessSettings.findUniqueOrThrow({ where: { id: 1 } });
      expect(queuedFor(placed.id, windowOf(A))[0].startAfter).toEqual(new Date(slotStart(A.pickupDate, TimeSlot.NOON).getTime() - settings.dispatchLeadMinutes * 60_000));

      // The round-1 expiry job and anything else made for the old window do nothing...
      await jobs.run('dispatch-expire', (d) => d.orderId === placed.id);
      expect((await http.get('/v1/driver/offers').set(bearer(PHONES.driver2)).expect(200)).body.some((o: { orderId: string }) => o.orderId === placed.id)).toBe(false);
      expect(await prisma.dispatchOffer.count({ where: { orderId: placed.id, round: 2 } })).toBe(0);

      // ...and the new window's job offers the order, to the same drivers (what they were offered before does not count).
      await jobs.run('dispatch-round', (d) => d.orderId === placed.id && d.window === windowOf(A));
      const offers = await http.get('/v1/driver/offers').set(bearer(PHONES.driver2)).expect(200);
      expect(offers.body.find((o: { orderId: string }) => o.orderId === placed.id)).toMatchObject({ leg: 'PICKUP', date: A.pickupDate, slot: 'NOON', slotLabel: '11:00–16:00' });
      expect((await staffView(placed.id)).dispatchFailedAt).toBeNull();
      await cleanUp(placed.id);
    });

    it('releases the partner who accepted, puts the order back to PENDING, and offers the new window', async () => {
      // A partner takes it from an offer, as they do: both partners were offered it a moment ago.
      const placed = await placeAndDispatch(items());
      const offer = await offerFor(PHONES.driver1, placed.id);
      await http.post(`/v1/driver/offers/${offer}/accept`).set(bearer(PHONES.driver1)).expect(200);
      expect((await http.get('/v1/driver/tasks').set(bearer(PHONES.driver1)).expect(200)).body.map((o: { id: string }) => o.id)).toContain(placed.id);
      await prisma.order.update({ where: { id: placed.id }, data: { dispatchFailedAt: new Date() } });
      jobs.clear();

      const res = await move(placed.id, B, 'resched-assigned-001').expect(200);
      expect(res.body).toMatchObject({ status: 'PENDING', pickupDriver: null, pickupDate: B.pickupDate, pickupSlot: 'MORNING', rescheduleCount: 1, dispatchFailedAt: null });
      const staff = await staffView(placed.id);
      expect(staff.events.at(-1)).toMatchObject({ fromStatus: 'PICKUP_ASSIGNED', toStatus: 'PENDING', actorRole: 'CUSTOMER' });
      expect(staff.pickupDriver).toBeNull();

      // The partner no longer has it, and is told why.
      expect((await http.get('/v1/driver/tasks').set(bearer(PHONES.driver1)).expect(200)).body.map((o: { id: string }) => o.id)).not.toContain(placed.id);
      await http.get(`/v1/driver/orders/${placed.id}`).set(bearer(PHONES.driver1)).expect(404);
      await waitFor(async () => (await prisma.notification.count({ where: { userId: driver1Id, type: 'task_removed', data: { path: ['orderId'], equals: placed.id } } })) === 1);
      const told = await prisma.notification.findFirstOrThrow({ where: { userId: driver1Id, type: 'task_removed', data: { path: ['orderId'], equals: placed.id } } });
      expect(told).toMatchObject({ title: 'Pickup time changed' });
      expect(told.body).toContain(placed.orderNumber);
      const alert = await prisma.notification.findFirstOrThrow({ where: { type: 'order_rescheduled', data: { path: ['orderId'], equals: placed.id } } });
      expect(alert.body).toContain('The assigned partner was released');

      // Dispatch reads the new dates: one job for the new window only (the order was not unassigned "now").
      await waitFor(() => queuedFor(placed.id).length === 1);
      expect(queuedFor(placed.id)[0].data).toMatchObject({ window: windowOf(B), leg: 'PICKUP' });
      await jobs.run('dispatch-round', (d) => d.orderId === placed.id);
      const offered = await http.get('/v1/driver/offers').set(bearer(PHONES.driver2)).expect(200);
      expect(offered.body.find((o: { orderId: string }) => o.orderId === placed.id)).toMatchObject({ date: B.pickupDate, slot: 'MORNING' });
      // Being offered it a moment ago for the old time does not rule a partner out for the new one, the released partner included.
      expect(await prisma.dispatchOffer.count({ where: { orderId: placed.id, round: 2, driverId: { in: [driver1Id, driver2Id] } } })).toBe(2);
      await cleanUp(placed.id);
    });

    it('can be assigned again after it moved', async () => {
      const placed = await book();
      await assign(placed.id, driver1Id);
      await move(placed.id, C).expect(200);
      await assign(placed.id, driver2Id);
      const taken = await mine(placed.id);
      expect(taken).toMatchObject({ status: 'PICKUP_ASSIGNED', pickupDriver: { id: driver2Id }, pickupDate: C.pickupDate, rescheduleCount: 1 });
      await cleanUp(placed.id);
    });

    it('keeps the partner when only the delivery time moves', async () => {
      const placed = await book();
      await assign(placed.id, driver1Id);
      jobs.clear();
      const res = await move(placed.id, { pickupDate: tomorrow, pickupSlot: 'MORNING', deliveryDate: addDays(dayAfter, 1), deliverySlot: 'NOON' }).expect(200);
      expect(res.body).toMatchObject({ status: 'PICKUP_ASSIGNED', pickupDriver: { id: driver1Id }, deliveryDate: addDays(dayAfter, 1), deliverySlot: 'NOON', rescheduleCount: 1 });
      expect((await staffView(placed.id)).events.at(-1).note).toMatch(/^Rescheduled by customer: delivery /);
      await new Promise((r) => setTimeout(r, 100));
      expect(queuedFor(placed.id)).toHaveLength(0);
      await cleanUp(placed.id);
    });

    it('allows two changes and then refuses, leaving the order as it was', async () => {
      const placed = await book();
      expect((await move(placed.id, A).expect(200)).body).toMatchObject({ rescheduleCount: 1, reschedulesRemaining: 1, canReschedule: true });
      expect((await move(placed.id, B).expect(200)).body).toMatchObject({ rescheduleCount: 2, reschedulesRemaining: 0, canReschedule: false });
      const refused = await move(placed.id, C).expect(409);
      expect(refused.body.code).toBe('RESCHEDULE_LIMIT');
      expect(await mine(placed.id)).toMatchObject({ pickupDate: B.pickupDate, pickupSlot: 'MORNING', rescheduleCount: 2, canReschedule: false });
      await cleanUp(placed.id);
    });

    it('only allows two when two changes arrive at once', async () => {
      const placed = await book();
      await move(placed.id, A).expect(200);
      const results = await Promise.all([move(placed.id, B), move(placed.id, C)]);
      expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
      expect(results.find((r) => r.status === 409)!.body.code).toBe('RESCHEDULE_LIMIT');
      expect((await mine(placed.id)).rescheduleCount).toBe(2);
      await cleanUp(placed.id);
    });

    it('is closed once the clothes are picked up, and for finished orders', async () => {
      const pickedUp = await book();
      await assign(pickedUp.id, driver1Id);
      await http.post(`/v1/driver/orders/${pickedUp.id}/picked-up`).set(bearer(PHONES.driver1)).expect(200);
      const late = await move(pickedUp.id, A).expect(409);
      expect(late.body.code).toBe('RESCHEDULE_NOT_ALLOWED');
      expect(await mine(pickedUp.id)).toMatchObject({ status: 'PICKED_UP', pickupDate: tomorrow, rescheduleCount: 0, canReschedule: false });

      const cancelled = await book();
      await http.post(`/v1/orders/${cancelled.id}/cancel`).set(bearer(PHONES.customer)).send({}).expect(200);
      expect((await move(cancelled.id, A).expect(409)).body.code).toBe('RESCHEDULE_NOT_ALLOWED');
      await cleanUp(pickedUp.id);
    });

    it('applies the booking rules to the new times, and counts nothing when it refuses', async () => {
      const placed = await book();
      const past = await move(placed.id, { ...A, pickupDate: addDays(tomorrow, -3) }).expect(400);
      expect(past.body.code).toBe('PICKUP_SLOT_CLOSED');
      const far = await move(placed.id, { ...A, pickupDate: addDays(tomorrow, 60), deliveryDate: addDays(tomorrow, 61) }).expect(400);
      expect(far.body.code).toBe('PICKUP_TOO_FAR_AHEAD');
      // The delivery must follow the new pickup by the turnaround: it is checked even when the customer keeps it.
      const rushed = await move(placed.id, { ...A, deliveryDate: A.pickupDate, deliverySlot: 'EVENING' }).expect(400);
      expect(rushed.body.code).toBe('DELIVERY_TOO_SOON');
      const same = await move(placed.id, { pickupDate: tomorrow, pickupSlot: 'MORNING', deliveryDate: dayAfter, deliverySlot: 'EVENING' }).expect(400);
      expect(same.body.code).toBe('RESCHEDULE_UNCHANGED');
      await move(placed.id, { pickupDate: 'tomorrow', pickupSlot: 'MORNING', deliveryDate: dayAfter, deliverySlot: 'EVENING' }).expect(400);
      await move(placed.id, { pickupDate: tomorrow, pickupSlot: 'LATE', deliveryDate: dayAfter, deliverySlot: 'EVENING' }).expect(400);
      expect(await mine(placed.id)).toMatchObject({ pickupDate: tomorrow, deliveryDate: dayAfter, rescheduleCount: 0, canReschedule: true, reschedulesRemaining: 2 });
      await cleanUp(placed.id);
    });

    it('counts a retry with the same key once, and refuses the key for a different change', async () => {
      const placed = await book();
      const first = await move(placed.id, A, 'resched-retry-key-1').expect(200);
      const history = (await staffView(placed.id)).events.length;

      const retry = await move(placed.id, A, 'resched-retry-key-1').expect(200);
      expect(retry.headers['idempotent-replayed']).toBe('true');
      expect(retry.body).toMatchObject({ id: first.body.id, rescheduleCount: 1, pickupDate: A.pickupDate });
      expect((await staffView(placed.id)).events).toHaveLength(history);
      expect(await prisma.auditLog.count({ where: { action: 'order.rescheduled', entityId: placed.id } })).toBe(1);

      const reused = await move(placed.id, B, 'resched-retry-key-1').expect(409);
      expect(reused.body.code).toBe('IDEMPOTENCY_KEY_REUSED');
      expect((await move(placed.id, A, 'bad key!').expect(400)).body.code).toBe('INVALID_IDEMPOTENCY_KEY');

      // A new key is a new change.
      expect((await move(placed.id, B, 'resched-retry-key-2').expect(200)).body).toMatchObject({ rescheduleCount: 2, pickupDate: B.pickupDate });
      expect((await mine(placed.id)).rescheduleCount).toBe(2);
      await cleanUp(placed.id);
    });

    it('keeps the count between 0 and 10, and a key with its fingerprint, in the database itself', async () => {
      const placed = await book();
      for (const data of [{ rescheduleCount: 11 }, { rescheduleCount: -1 }, { rescheduleKey: 'a-key-with-no-fingerprint' }, { rescheduleHash: 'a-fingerprint-with-no-key' }]) {
        await expect(prisma.order.update({ where: { id: placed.id }, data })).rejects.toThrow();
      }
      await prisma.order.update({ where: { id: placed.id }, data: { rescheduleCount: 10, rescheduleKey: 'both-or-neither', rescheduleHash: 'both-or-neither' } });
      await cleanUp(placed.id);
    });

    it('is a 404 for another customer\'s order, and closed to staff', async () => {
      const placed = await book();
      const other = await move(placed.id, A, undefined, PHONES.otherCustomer).expect(404);
      expect(other.body.code).toBe('NOT_FOUND');
      await move('00000000-0000-4000-8000-000000000000', A).expect(404);
      await move(placed.id, A, undefined, PHONES.admin).expect(403);
      await http.post(`/v1/orders/${placed.id}/reschedule`).send(A).expect(401);
      expect(await mine(placed.id)).toMatchObject({ pickupDate: tomorrow, rescheduleCount: 0 });
      await cleanUp(placed.id);
    });
  });

  describe('service area rules, capacity and the waiting list', () => {
    // Customers are created directly: the session endpoint is rate limited and this suite has used its share.
    const HUB = { serviceCenterLatitude: 17.4126, serviceCenterLongitude: 78.4482, serviceRadiusKm: 6 };
    const LISTED = ['500033', '500034'];
    const admin = bearer(PHONES.admin);
    const superAdmin = bearer(PHONES.superAdmin);
    /** A map position `km` north of the centre, so its distance is known without trusting a second formula. */
    const km = (n: number) => ({ latitude: 17.4126 + n / 111.195, longitude: 78.4482 });

    let seq = 0;
    const customers: string[] = [];
    async function customer(name: string, extra: { contactPhone?: string } = {}): Promise<{ id: string; auth: { Authorization: string }; phone: string }> {
      seq += 1;
      const digits = `98010${String(seq).padStart(5, '0')}`;
      const user = await prisma.user.create({ data: { firebaseUid: `dev-91${digits}`, phone: `+91${digits}`, name, role: 'CUSTOMER', ...extra } });
      customers.push(user.id);
      return { id: user.id, auth: bearer(digits), phone: `+91${digits}` };
    }
    async function addressFor(who: { auth: { Authorization: string } }, place: { pincode: string; area?: string; latitude?: number; longitude?: number }) {
      const res = await http
        .post('/v1/me/addresses')
        .set(who.auth)
        .send({ houseNo: '12', street: 'Main Road', area: place.area, city: 'Hyderabad', state: 'Telangana', ...place })
        .expect(201);
      return res.body as { id: string; serviceable: boolean; notServiceableReason: string | null };
    }
    const setArea = (data: object) => http.patch('/v1/admin/settings').set(superAdmin).send(data).expect(200);
    const draft = (addressId: string, w: { pickupDate: string; pickupSlot: string }, extra: object = {}) => ({
      items: [{ catalogItemId: shirtId, quantity: 3 }],
      pickupDate: w.pickupDate,
      pickupSlot: w.pickupSlot,
      deliveryDate: addDays(w.pickupDate, 2),
      deliverySlot: 'NOON',
      pickupAddressId: addressId,
      paymentMethod: 'COD',
      ...extra,
    });
    const orderRow = (id: string) => prisma.order.findUniqueOrThrow({ where: { id } });
    const auditOf = async (action: string, entityId: string) => {
      await waitFor(async () => (await prisma.auditLog.count({ where: { action, entityId } })) > 0);
      return prisma.auditLog.findFirstOrThrow({ where: { action, entityId } });
    };

    afterAll(async () => {
      // Leave the shared settings and orders as the later sections expect them. Through the API, which also refreshes the
      // settings the server keeps for a few seconds.
      await setArea({ serviceCenterLatitude: null, serviceCenterLongitude: null, serviceRadiusKm: null, servicePincodes: [], pickupCapacityPerSlot: null });
      await prisma.order.updateMany({ where: { customerId: { in: customers } }, data: { status: 'CANCELLED' } });
    });

    describe('staff phone orders', () => {
      const W = () => ({ pickupDate: addDays(tomorrow, 5), pickupSlot: 'MORNING' });
      let who: Awaited<ReturnType<typeof customer>>;
      let pinned: { id: string }; // inside, with a map pin
      let pinOnly: { id: string }; // no pin, served PIN code
      let blind: { id: string }; // no pin, PIN code not on the list
      let far: { id: string }; // outside by distance
      const place = (addressId: string, extra: object = {}) =>
        http.post('/v1/admin/orders').set(admin).send({ customerId: who.id, ...draft(addressId, W()), ...extra });

      beforeAll(async () => {
        who = await customer('Phone Caller');
        await setArea({ ...HUB, servicePincodes: LISTED });
        pinned = await addressFor(who, { pincode: '500033', area: 'Jubilee Hills', ...km(4) });
        pinOnly = await addressFor(who, { pincode: '500034', area: 'Banjara Hills' });
        blind = await addressFor(who, { pincode: '500099', area: 'Elsewhere' });
        far = await addressFor(who, { pincode: '500033', area: 'Gachibowli', ...km(11) });
      });

      it('takes an address with a map pin inside the area, or a served PIN code with no pin, and stores no reason', async () => {
        for (const address of [pinned, pinOnly]) {
          const res = await place(address.id).expect(201);
          const row = await orderRow(res.body.id);
          expect(row.areaOverrideReason).toBeNull();
          expect(row.capacityOverrideReason).toBeNull();
          expect(res.body).toMatchObject({ areaOverrideReason: null, capacityOverrideReason: null });
        }
      });

      it('needs a map pin or a served PIN code: neither is ADDRESS_LOCATION_REQUIRED, and a reason does not help', async () => {
        await setArea({ servicePincodes: [] });
        const noList = await place(pinOnly.id).expect(400);
        expect(noList.body).toMatchObject({ code: 'ADDRESS_LOCATION_REQUIRED', details: { addressId: pinOnly.id } });
        const withReason = await place(pinOnly.id, { outsideAreaReason: 'A perfectly good reason' }).expect(400);
        expect(withReason.body.code).toBe('ADDRESS_LOCATION_REQUIRED');
        // The same address passes once its PIN code is on the list.
        await setArea({ servicePincodes: LISTED });
        await place(pinOnly.id).expect(201);
        // With no area set at all, a map pin is still required.
        await setArea({ serviceCenterLatitude: null, serviceCenterLongitude: null, serviceRadiusKm: null, servicePincodes: [] });
        expect((await place(pinOnly.id).expect(400)).body.code).toBe('ADDRESS_LOCATION_REQUIRED');
        await place(pinned.id).expect(201);
        await setArea({ ...HUB, servicePincodes: LISTED });
      });

      it('refuses an address outside the area until staff type a reason, then stores it on the order and in the audit log', async () => {
        for (const address of [far, blind]) {
          const refused = await place(address.id).expect(400);
          expect(refused.body).toMatchObject({ code: 'ADDRESS_NOT_SERVICEABLE', details: { addressId: address.id, canOverride: true } });
        }
        expect((await place(far.id).expect(400)).body.details).toMatchObject({ reason: 'OUTSIDE_RADIUS', distanceKm: 11 });
        expect((await place(blind.id).expect(400)).body.details).toMatchObject({ reason: 'PINCODE_NOT_SERVED' });

        // Too short (or only spaces) is a validation error: nothing is placed.
        await place(far.id, { outsideAreaReason: 'abc' }).expect(400);
        await place(far.id, { outsideAreaReason: '     ' }).expect(400);
        const before = await prisma.order.count({ where: { customerId: who.id } });

        const res = await place(far.id, { outsideAreaReason: '  Regular customer, our partner passes there daily  ' }).expect(201);
        expect(await prisma.order.count({ where: { customerId: who.id } })).toBe(before + 1);
        expect(res.body.areaOverrideReason).toBe('Regular customer, our partner passes there daily');
        expect((await orderRow(res.body.id)).areaOverrideReason).toBe('Regular customer, our partner passes there daily');
        const log = await auditOf('order.placed_for_customer', res.body.id);
        expect(log.data).toMatchObject({ outsideAreaReason: 'Regular customer, our partner passes there daily' });
        expect(log.data).not.toHaveProperty('capacityOverrideReason');

        // Staff see it on the order; the customer does not.
        expect((await http.get(`/v1/admin/orders/${res.body.id}`).set(admin).expect(200)).body.areaOverrideReason).toBe('Regular customer, our partner passes there daily');
        const asCustomer = (await http.get(`/v1/orders/${res.body.id}`).set(who.auth).expect(200)).body;
        expect(asCustomer).not.toHaveProperty('areaOverrideReason');
        expect(asCustomer).not.toHaveProperty('capacityOverrideReason');
      });

      it('keeps no reason when the address turns out to be inside', async () => {
        const res = await place(pinned.id, { outsideAreaReason: 'Not needed for this one' }).expect(201);
        expect(res.body.areaOverrideReason).toBeNull();
        expect((await orderRow(res.body.id)).areaOverrideReason).toBeNull();
      });

      it('checks the delivery address too', async () => {
        const res = await place(pinned.id, { deliveryAddressId: far.id }).expect(400);
        expect(res.body).toMatchObject({ code: 'ADDRESS_NOT_SERVICEABLE', details: { addressId: far.id } });
        await place(pinned.id, { deliveryAddressId: far.id, outsideAreaReason: 'Delivering to the office there' }).expect(201);
      });

      it('leaves customers as they were: outside is refused, and they cannot send either override', async () => {
        const refused = await http.post('/v1/orders').set(who.auth).send(draft(far.id, W())).expect(400);
        expect(refused.body).toMatchObject({ code: 'ADDRESS_NOT_SERVICEABLE', details: { addressId: far.id, reason: 'OUTSIDE_RADIUS' } });
        expect(refused.body.details).not.toHaveProperty('canOverride');
        await http.post('/v1/orders').set(who.auth).send(draft(far.id, W(), { outsideAreaReason: 'Please let me' })).expect(400);
        await http.post('/v1/orders').set(who.auth).send(draft(pinned.id, W(), { capacityOverrideReason: 'Please let me' })).expect(400);
        // An address with no map pin and a PIN code off the list is still just "not served" for a customer.
        expect((await http.post('/v1/orders').set(who.auth).send(draft(blind.id, W())).expect(400)).body.code).toBe('ADDRESS_NOT_SERVICEABLE');
      });

      it('keeps a reason of at least 5 characters in the database itself', async () => {
        const res = await place(pinned.id).expect(201);
        for (const data of [{ areaOverrideReason: 'abc' }, { areaOverrideReason: '   ab   ' }, { capacityOverrideReason: 'four' }]) {
          await expect(prisma.order.update({ where: { id: res.body.id }, data })).rejects.toThrow();
        }
        await prisma.order.update({ where: { id: res.body.id }, data: { areaOverrideReason: 'five!', capacityOverrideReason: 'also fine' } });
      });
    });

    describe('checking an address from settings', () => {
      const check = (body: object, auth = admin) => http.post('/v1/admin/settings/check-address').set(auth).send(body);
      beforeAll(async () => {
        await setArea({ ...HUB, servicePincodes: LISTED });
      });

      it('says served, with the distance, for a map position inside the radius', async () => {
        const res = await check({ ...km(4.5) }).expect(200);
        expect(res.body).toEqual({ served: true, reason: null, distanceKm: 4.5, verified: true });
      });

      it('says why not, with the distance, outside the radius or off the PIN list', async () => {
        expect((await check({ ...km(7.2) }).expect(200)).body).toEqual({ served: false, reason: 'OUTSIDE_RADIUS', distanceKm: 7.2, verified: true });
        // Inside the radius but on a PIN code we do not serve: refused, and the distance is still shown.
        expect((await check({ ...km(3), pincode: '500099' }).expect(200)).body).toEqual({ served: false, reason: 'PINCODE_NOT_SERVED', distanceKm: 3, verified: true });
        expect((await check({ ...km(3), pincode: '500033' }).expect(200)).body).toEqual({ served: true, reason: null, distanceKm: 3, verified: true });
      });

      it('answers for a PIN code alone, and says when nothing could be checked', async () => {
        expect((await check({ pincode: '500034' }).expect(200)).body).toEqual({ served: true, reason: null, distanceKm: null, verified: true });
        expect((await check({ pincode: '500099' }).expect(200)).body).toMatchObject({ served: false, reason: 'PINCODE_NOT_SERVED', distanceKm: null });
        await setArea({ servicePincodes: [] });
        expect((await check({ pincode: '500034' }).expect(200)).body).toEqual({ served: true, reason: null, distanceKm: null, verified: false });
        await setArea({ servicePincodes: LISTED });
      });

      it('uses the settings as they are saved now', async () => {
        expect((await check({ ...km(7.2) }).expect(200)).body.served).toBe(false);
        await setArea({ serviceRadiusKm: 8 });
        expect((await check({ ...km(7.2) }).expect(200)).body).toMatchObject({ served: true, distanceKm: 7.2 });
        await setArea({ serviceRadiusKm: 6 });
        expect((await check({ ...km(7.2) }).expect(200)).body.served).toBe(false);
      });

      it('wants a position or a PIN code, a full position, and real values', async () => {
        expect((await check({}).expect(400)).body.code).toBe('INVALID_LOCATION');
        expect((await check({ latitude: 17.4 }).expect(400)).body.code).toBe('INVALID_LOCATION');
        await check({ pincode: '12345' }).expect(400);
        await check({ latitude: 95, longitude: 78 }).expect(400);
        await check({ pincode: '500033', extra: 1 }).expect(400);
      });

      it('is for staff only, and any staff member (not just the owner)', async () => {
        await check({ pincode: '500033' }, who().auth).expect(403);
        await http.post('/v1/admin/settings/check-address').send({ pincode: '500033' }).expect(401);
        await check({ pincode: '500033' }, superAdmin).expect(200);
      });

      function who() {
        return { auth: bearer(PHONES.otherCustomer) };
      }
    });

    describe('the waiting list', () => {
      let cohort: Record<string, { who: Awaited<ReturnType<typeof customer>>; address: { id: string; serviceable: boolean } }>;
      const register = (auth: { Authorization: string }, addressId: string) => http.post('/v1/me/area-interest').set(auth).send({ addressId });
      const overview = (query: object = {}) => http.get('/v1/admin/area-interest').set(admin).query(query);

      beforeAll(async () => {
        await setArea({ ...HUB, servicePincodes: LISTED });
        const spec: [string, { pincode: string; area: string; latitude?: number; longitude?: number }][] = [
          ['a', { pincode: '500032', area: 'Gachibowli', ...km(11) }],
          ['b', { pincode: '500032', area: 'Gachibowli', ...km(10.4) }],
          ['c', { pincode: '500032', area: 'Gachibowli', ...km(8.4) }],
          ['d', { pincode: '500036', area: 'Malakpet', ...km(6.5) }],
          ['e', { pincode: '500028', area: 'Mehdipatnam', ...km(3) }],
          ['f', { pincode: '500099', area: 'Somewhere' }],
        ];
        cohort = {};
        for (const [key, place] of spec) {
          const who = await customer(`Waiting ${key.toUpperCase()}`);
          cohort[key] = { who, address: await addressFor(who, place) };
        }
      });

      it('records a request for an address outside the area, from the saved address and the signed-in number', async () => {
        const { who, address } = cohort.a;
        // 11 km out and on a PIN code off the list: either rule alone would refuse it.
        expect(address.serviceable).toBe(false);
        const res = await register(who.auth, address.id).expect(200);
        expect(res.body).toMatchObject({ pincode: '500032', locality: 'Gachibowli' });
        expect(Object.keys(res.body).sort()).toEqual(['createdAt', 'id', 'locality', 'pincode']);
        const row = await prisma.areaInterest.findUniqueOrThrow({ where: { id: res.body.id } });
        expect(row).toMatchObject({ userId: who.id, addressId: address.id, pincode: '500032', locality: 'Gachibowli', distanceKm: 11, notifiedAt: null });
        expect(row.latitude).toBeCloseTo(km(11).latitude, 6);
        expect(row.longitude).toBeCloseTo(km(11).longitude, 6);
      });

      it('is idempotent: the same address, another address on the same PIN code, and many taps at once are one request', async () => {
        const { who, address } = cohort.a;
        const first = await prisma.areaInterest.findFirstOrThrow({ where: { userId: who.id } });
        const again = await register(who.auth, address.id).expect(200);
        expect(again.body.id).toBe(first.id);
        const sameCode = await addressFor(who, { pincode: '500032', area: 'Gachibowli Phase 2', ...km(11.5) });
        expect((await register(who.auth, sameCode.id).expect(200)).body.id).toBe(first.id);
        const taps = await Promise.all([1, 2, 3, 4, 5].map(() => register(who.auth, address.id)));
        expect(taps.map((t) => t.status)).toEqual([200, 200, 200, 200, 200]);
        expect(new Set(taps.map((t) => t.body.id))).toEqual(new Set([first.id]));
        expect(await prisma.areaInterest.count({ where: { userId: who.id } })).toBe(1);
        // Another PIN code is another request.
        const other = await addressFor(who, { pincode: '500081', area: 'Madhapur', ...km(14) });
        expect((await register(who.auth, other.id).expect(200)).body.id).not.toBe(first.id);
        expect(await prisma.areaInterest.count({ where: { userId: who.id } })).toBe(2);
        await prisma.areaInterest.deleteMany({ where: { userId: who.id, pincode: '500081' } });
      });

      it('never takes a place from the client, and only for the customer\'s own saved address', async () => {
        const { who } = cohort.b;
        const mine = cohort.b.address.id;
        await http.post('/v1/me/area-interest').set(who.auth).send({ addressId: mine, latitude: 17.4126, longitude: 78.4482, pincode: '500033' }).expect(400);
        const res = await register(who.auth, mine).expect(200);
        expect(await prisma.areaInterest.findUniqueOrThrow({ where: { id: res.body.id } })).toMatchObject({ pincode: '500032', distanceKm: 10.4 });

        expect((await register(who.auth, cohort.c.address.id).expect(404)).body.code).toBe('NOT_FOUND');
        await register(who.auth, '00000000-0000-4000-8000-000000000000').expect(404);
        await http.post('/v1/me/area-interest').set(who.auth).send({ addressId: 'not-a-uuid' }).expect(400);
        await http.post('/v1/me/area-interest').set(who.auth).send({}).expect(400);
      });

      it('refuses an address that is served, a signed-out caller, staff, and a customer with no number', async () => {
        const insider = await customer('Inside Ira');
        const inside = await addressFor(insider, { pincode: '500033', area: 'Jubilee Hills', ...km(4) });
        expect((await register(insider.auth, inside.id).expect(400)).body.code).toBe('ADDRESS_SERVICEABLE');
        expect(await prisma.areaInterest.count({ where: { userId: insider.id } })).toBe(0);

        await http.post('/v1/me/area-interest').send({ addressId: cohort.a.address.id }).expect(401);
        await register(admin, cohort.a.address.id).expect(403);

        // Signed in with Google and no number on the account: staff would have nobody to call.
        const google = { Authorization: 'Bearer dev-google:nonumber@example.com' };
        const noNumber = await prisma.user.create({ data: { firebaseUid: 'dev-google-nonumber@example.com', phone: null, email: 'nonumber@example.com', name: 'No Number', role: 'CUSTOMER' } });
        customers.push(noNumber.id);
        const theirs = await addressFor({ auth: google }, { pincode: '500032', area: 'Gachibowli', ...km(11) });
        expect((await register(google, theirs.id).expect(400)).body.code).toBe('PHONE_REQUIRED');
        // A number typed at checkout is enough: that is the number staff would call.
        await prisma.user.update({ where: { id: noNumber.id }, data: { contactPhone: '+919123456789' } });
        await register(google, theirs.id).expect(200);
        await prisma.areaInterest.deleteMany({ where: { userId: noNumber.id } });
      });

      it('lets a customer who has been told ask again', async () => {
        const { who, address } = cohort.e;
        const first = (await register(who.auth, address.id).expect(200)).body.id as string;
        await http.post(`/v1/admin/area-interest/${first}/told`).set(admin).expect(200);
        const second = (await register(who.auth, address.id).expect(200)).body.id as string;
        expect(second).not.toBe(first);
        await http.post(`/v1/admin/area-interest/${second}/told`).set(admin).expect(200);
        await register(who.auth, address.id).expect(200);
        // Left open for the counts below; the told ones stay in the list as history.
        expect(await prisma.areaInterest.count({ where: { userId: who.id } })).toBe(3);
        await prisma.areaInterest.deleteMany({ where: { userId: who.id } });
      });

      it('counts open requests by PIN code, locality and distance band, most first', async () => {
        for (const key of ['a', 'b', 'c', 'd', 'e', 'f']) await register(cohort[key].who.auth, cohort[key].address.id).expect(200);
        const res = await overview().expect(200);
        expect(res.body.openTotal).toBe(6);
        expect(res.body.bands).toEqual([
          { band: 'UNDER_6', count: 1 },
          { band: 'KM_6_8', count: 1 },
          { band: 'KM_8_10', count: 1 },
          { band: 'KM_10_PLUS', count: 2 },
          { band: 'UNKNOWN', count: 1 },
        ]);
        expect(res.body.areas).toHaveLength(5);
        expect(res.body.areas[0]).toMatchObject({ pincode: '500032', locality: 'Gachibowli', band: 'KM_10_PLUS', count: 2, nearestKm: 10.4 });
        const rest = res.body.areas.slice(1).map((a: { pincode: string; locality: string; band: string; count: number; nearestKm: number | null }) => [a.pincode, a.locality, a.band, a.count, a.nearestKm]);
        expect(rest).toEqual(expect.arrayContaining([
          ['500032', 'Gachibowli', 'KM_8_10', 1, 8.4],
          ['500036', 'Malakpet', 'KM_6_8', 1, 6.5],
          ['500028', 'Mehdipatnam', 'UNDER_6', 1, 3],
          ['500099', 'Somewhere', 'UNKNOWN', 1, null],
        ]));
        for (const a of res.body.areas) expect(Number.isNaN(Date.parse(a.newestAt))).toBe(false);
      });

      it('puts each band edge in the band the list is read in', async () => {
        const edges: [number | null, string][] = [[5.9, 'UNDER_6'], [6, 'KM_6_8'], [7.9, 'KM_6_8'], [8, 'KM_8_10'], [9.9, 'KM_8_10'], [10, 'KM_10_PLUS'], [null, 'UNKNOWN']];
        const user = await customer('Edge Eddie');
        const rows: { id: string }[] = [];
        for (const [i, [distance]] of edges.entries()) {
          rows.push(await prisma.areaInterest.create({ data: { userId: user.id, pincode: `5990${i}0`, locality: `Edge ${i}`, distanceKm: distance } }));
        }
        const res = await overview({ pageSize: 100 }).expect(200);
        for (const [i, [, band]] of edges.entries()) {
          expect(res.body.areas.find((a: { locality: string }) => a.locality === `Edge ${i}`)).toMatchObject({ band, count: 1 });
          expect(res.body.items.find((it: { id: string }) => it.id === rows[i].id)).toMatchObject({ band });
        }
        await prisma.areaInterest.deleteMany({ where: { userId: user.id } });
      });

      it('lists requests newest first with the customer\'s name and number, a page at a time', async () => {
        const first = await overview({ pageSize: 4 }).expect(200);
        expect(first.body).toMatchObject({ page: 1, pageSize: 4, total: 6 });
        expect(first.body.items.map((i: { customerName: string }) => i.customerName)).toEqual(['Waiting F', 'Waiting E', 'Waiting D', 'Waiting C']);
        expect(first.body.items[0]).toMatchObject({
          customerId: cohort.f.who.id,
          customerPhone: cohort.f.who.phone,
          pincode: '500099',
          locality: 'Somewhere',
          distanceKm: null,
          band: 'UNKNOWN',
          notifiedAt: null,
        });
        const second = await overview({ pageSize: 4, page: 2 }).expect(200);
        expect(second.body.items.map((i: { customerName: string }) => i.customerName)).toEqual(['Waiting B', 'Waiting A']);
        // The counts are the whole waiting list, not the page.
        expect(second.body.openTotal).toBe(6);
        await overview({ pageSize: 0 }).expect(400);
        await overview({ status: 'SOON' }).expect(400);
      });

      it('shows the customer\'s name and number to staff only', async () => {
        await http.get('/v1/admin/area-interest').set(cohort.a.who.auth).expect(403);
        await http.get('/v1/admin/area-interest').expect(401);
        await http.post(`/v1/admin/area-interest/${(await prisma.areaInterest.findFirstOrThrow()).id}/told`).set(cohort.a.who.auth).expect(403);
        const mine = await register(cohort.a.who.auth, cohort.a.address.id).expect(200);
        expect(JSON.stringify(mine.body)).not.toContain(cohort.a.who.phone);
      });

      it('marks one as told once, leaving the open counts, and says so in the audit log', async () => {
        const target = await prisma.areaInterest.findFirstOrThrow({ where: { userId: cohort.d.who.id } });
        const told = await http.post(`/v1/admin/area-interest/${target.id}/told`).set(admin).expect(200);
        expect(told.body).toMatchObject({ id: target.id, customerName: 'Waiting D', band: 'KM_6_8' });
        expect(told.body.notifiedAt).not.toBeNull();
        const log = await auditOf('area_interest.told', target.id);
        expect(log.data).toMatchObject({ customerId: cohort.d.who.id, pincode: '500036', locality: 'Malakpet' });
        expect(JSON.stringify(log.data)).not.toContain(cohort.d.who.phone);

        // Telling again changes nothing and logs nothing more.
        const again = await http.post(`/v1/admin/area-interest/${target.id}/told`).set(admin).expect(200);
        expect(again.body.notifiedAt).toBe(told.body.notifiedAt);
        expect(await prisma.auditLog.count({ where: { action: 'area_interest.told', entityId: target.id } })).toBe(1);

        const open = await overview().expect(200);
        expect(open.body.openTotal).toBe(5);
        expect(open.body.areas.some((a: { locality: string }) => a.locality === 'Malakpet')).toBe(false);
        expect(open.body.total).toBe(5);
        expect(open.body.items.some((i: { id: string }) => i.id === target.id)).toBe(false);
        const toldList = await overview({ status: 'TOLD' }).expect(200);
        expect(toldList.body.items.map((i: { id: string }) => i.id)).toEqual([target.id]);
        expect((await overview({ status: 'ALL' }).expect(200)).body.total).toBe(6);

        await http.post('/v1/admin/area-interest/00000000-0000-4000-8000-000000000000/told').set(admin).expect(404);
        await http.post('/v1/admin/area-interest/nope/told').set(admin).expect(400);
      });

      it('holds one open request per customer and PIN code in the database itself, and a position is both numbers or neither', async () => {
        const { who } = cohort.b;
        await expect(prisma.areaInterest.create({ data: { userId: who.id, pincode: '500032', locality: 'Gachibowli' } })).rejects.toThrow();
        await expect(prisma.areaInterest.create({ data: { userId: who.id, pincode: '500777', locality: 'X', latitude: 17.4 } })).rejects.toThrow();
        await expect(prisma.areaInterest.create({ data: { userId: who.id, pincode: '500778', locality: 'X', distanceKm: -1 } })).rejects.toThrow();
        // Once told, the same customer and PIN code can be open again.
        const done = await prisma.areaInterest.create({ data: { userId: who.id, pincode: '500779', locality: 'X', notifiedAt: new Date() } });
        await prisma.areaInterest.create({ data: { userId: who.id, pincode: '500779', locality: 'X' } });
        expect(done.notifiedAt).not.toBeNull();
        await prisma.areaInterest.deleteMany({ where: { userId: who.id, pincode: '500779' } });
      });

      it('is erased with the customer\'s account', async () => {
        const leaving = await customer('Leaving Lena');
        const address = await addressFor(leaving, { pincode: '500032', area: 'Gachibowli', ...km(11) });
        await register(leaving.auth, address.id).expect(200);
        expect(await prisma.areaInterest.count({ where: { userId: leaving.id } })).toBe(1);
        await http.delete('/v1/me').set(leaving.auth).expect(204);
        expect(await prisma.areaInterest.count({ where: { userId: leaving.id } })).toBe(0);
        const list = await overview({ pageSize: 100, status: 'ALL' }).expect(200);
        expect(list.body.items.some((i: { customerId: string }) => i.customerId === leaving.id)).toBe(false);
        // The account-deletion section counts erased accounts: leave no extra one behind.
        await prisma.user.delete({ where: { id: leaving.id } });
      });

      afterAll(async () => {
        await prisma.areaInterest.deleteMany({});
        await setArea({ serviceCenterLatitude: null, serviceCenterLongitude: null, serviceRadiusKm: null, servicePincodes: [] });
      });
    });

    describe('pickup capacity', () => {
      // Each test uses its own windows, far enough ahead not to meet the orders of the sections above.
      const win = (days: number, slot = 'MORNING') => ({ pickupDate: addDays(tomorrow, days), pickupSlot: slot });
      let who: Awaited<ReturnType<typeof customer>>;
      let home: { id: string };
      const used = (w: { pickupDate: string; pickupSlot: string }) =>
        prisma.order.count({ where: { pickupDate: new Date(`${w.pickupDate}T00:00:00.000Z`), pickupSlot: w.pickupSlot as never, status: { in: ['PENDING', 'PICKUP_ASSIGNED'] } } });
      const book = (w: { pickupDate: string; pickupSlot: string }, extra: object = {}, auth = who.auth, addressId = home.id) =>
        http.post('/v1/orders').set(auth).send(draft(addressId, w, extra));
      const phoneOrder = (w: { pickupDate: string; pickupSlot: string }, extra: object = {}) =>
        http.post('/v1/admin/orders').set(admin).send({ customerId: who.id, ...draft(home.id, w, extra) });
      const slots = async () => (await http.get('/v1/schedule/pickup-slots').query({ days: 31 }).expect(200)).body as { date: string; slot: string; available: boolean; reason: string | null }[];
      const slotOf = (all: Awaited<ReturnType<typeof slots>>, w: { pickupDate: string; pickupSlot: string }) => all.find((s) => s.date === w.pickupDate && s.slot === w.pickupSlot)!;

      beforeAll(async () => {
        who = await customer('Capacity Cara');
        home = await addressFor(who, { pincode: '500033', area: 'Jubilee Hills', ...km(4) });
        await setArea({ pickupCapacityPerSlot: 2 });
      });

      it('is a setting: 8 to start, empty for no cap, and never zero', async () => {
        expect((await prisma.$queryRaw<{ column_default: string }[]>`SELECT column_default FROM information_schema.columns WHERE table_name = 'business_settings' AND column_name = 'pickup_capacity_per_slot'`)[0].column_default).toBe('8');
        expect((await http.get('/v1/admin/settings').set(admin).expect(200)).body.pickupCapacityPerSlot).toBe(2);
        expect((await setArea({ pickupCapacityPerSlot: null })).body.pickupCapacityPerSlot).toBeNull();
        expect((await setArea({ pickupCapacityPerSlot: 5 })).body.pickupCapacityPerSlot).toBe(5);
        for (const bad of [0, -1, 1.5, '8', 1001]) await http.patch('/v1/admin/settings').set(superAdmin).send({ pickupCapacityPerSlot: bad }).expect(400);
        await http.patch('/v1/admin/settings').set(admin).send({ pickupCapacityPerSlot: 3 }).expect(403);
        await expect(prisma.businessSettings.update({ where: { id: 1 }, data: { pickupCapacityPerSlot: 0 } })).rejects.toThrow();
        await setArea({ pickupCapacityPerSlot: 2 });
      });

      it('counts a window\'s waiting orders, refuses the next booking with SLOT_FULL, and shows the window as FULL', async () => {
        const w = win(12);
        await book(w).expect(201);
        expect(slotOf(await slots(), w)).toMatchObject({ available: true, reason: null });
        await book(w).expect(201);

        const full = slotOf(await slots(), w);
        expect(full).toMatchObject({ available: false, reason: 'FULL' });
        // Other windows are untouched, including the same slot on other days and other slots on this day.
        const all = await slots();
        expect(slotOf(all, win(12, 'NOON'))).toMatchObject({ available: true, reason: null });
        expect(slotOf(all, win(13))).toMatchObject({ available: true, reason: null });

        const refused = await book(w).expect(409);
        expect(refused.body).toMatchObject({ code: 'SLOT_FULL', details: { date: w.pickupDate, slot: 'MORNING' } });
        expect(await used(w)).toBe(2);
        // The order number was not used up by the refusal.
        const a = await book(win(12, 'NOON')).expect(201);
        const b = await book(win(12, 'NOON')).expect(201);
        expect(Number(b.body.orderNumber.replace(/\D/g, ''))).toBe(Number(a.body.orderNumber.replace(/\D/g, '')) + 1);
      });

      it('keeps the old fields for old apps and gives new apps the reason', async () => {
        const all = await slots();
        for (const s of all) {
          expect(typeof s.available).toBe('boolean');
          expect([null, 'FULL']).toContain(s.reason);
          if (s.reason === 'FULL') expect(s.available).toBe(false);
        }
        // Closed windows are closed, not full; delivery windows never are.
        expect(all[0].reason).toBeNull();
        const delivery = (await http.get('/v1/schedule/delivery-slots').query({ pickupDate: addDays(tomorrow, 12), pickupSlot: 'MORNING', days: 7 }).expect(200)).body as { reason: string | null }[];
        expect(delivery.every((s) => s.reason === null)).toBe(true);
        // Anyone can look, signed in or not.
        await http.get('/v1/schedule/pickup-slots').expect(200);
      });

      it('frees a place when an order is cancelled or picked up, and counts one a partner has accepted', async () => {
        const w = win(14);
        const first = await book(w).expect(201);
        const second = await book(w).expect(201);
        await book(w).expect(409);

        await prisma.order.update({ where: { id: first.body.id }, data: { status: 'PICKUP_ASSIGNED' } });
        await book(w).expect(409);
        await prisma.order.update({ where: { id: first.body.id }, data: { status: 'CANCELLED' } });
        expect(slotOf(await slots(), w)).toMatchObject({ available: true, reason: null });
        const third = await book(w).expect(201);
        await book(w).expect(409);

        await prisma.order.update({ where: { id: second.body.id }, data: { status: 'PICKED_UP' } });
        expect(slotOf(await slots(), w).available).toBe(true);
        await book(w).expect(201);
        await book(w).expect(409);
        expect(third.body.status).toBe('PENDING');
      });

      it('has no limit when the setting is empty', async () => {
        await setArea({ pickupCapacityPerSlot: null });
        const w = win(15);
        for (let i = 0; i < 4; i++) await book(w).expect(201);
        expect(slotOf(await slots(), w)).toMatchObject({ available: true, reason: null });
        await setArea({ pickupCapacityPerSlot: 2 });
        // Over the new cap already: full, and the orders already booked stay.
        expect(slotOf(await slots(), w)).toMatchObject({ available: false, reason: 'FULL' });
        expect(await used(w)).toBe(4);
      });

      it('gives the last place to one of many bookings made at the same moment', async () => {
        await setArea({ pickupCapacityPerSlot: 3 });
        const w = win(16);
        await book(w).expect(201);
        await book(w).expect(201);
        const rivals = await Promise.all(Array.from({ length: 6 }, () => book(w)));
        const outcomes = rivals.map((r) => r.status).sort();
        expect(outcomes).toEqual([201, 409, 409, 409, 409, 409]);
        for (const r of rivals.filter((x) => x.status === 409)) expect(r.body.code).toBe('SLOT_FULL');
        expect(await used(w)).toBe(3);

        // Different windows do not wait for each other: one place each, all at once.
        await setArea({ pickupCapacityPerSlot: 1 });
        const apart = await Promise.all([win(17), win(17, 'NOON'), win(17, 'EVENING'), win(18)].map((x) => book(x)));
        expect(apart.map((r) => r.status)).toEqual([201, 201, 201, 201]);
        await setArea({ pickupCapacityPerSlot: 2 });
      });

      it('treats a retry of the booking that took the last place as that booking, not as a second one', async () => {
        await setArea({ pickupCapacityPerSlot: 1 });
        const w = win(19);
        const key1 = { 'Idempotency-Key': 'capacity-last-place-1' };
        const both = await Promise.all([book(w).set(key1), book(w).set(key1)]);
        expect(both.map((r) => r.status)).toEqual([201, 201]);
        expect(both[0].body.id).toBe(both[1].body.id);
        expect(await used(w)).toBe(1);
        // Someone else asking for that place is refused.
        await book(w).expect(409);
        // A retry later, after the window filled, still returns the order.
        expect((await book(w).set(key1).expect(201)).headers['idempotent-replayed']).toBe('true');
        await setArea({ pickupCapacityPerSlot: 2 });
      });

      describe('rescheduling', () => {
        const move = (id: string, to: { pickupDate: string; pickupSlot: string }, auth = who.auth) =>
          http.post(`/v1/orders/${id}/reschedule`).set(auth).send({ ...to, deliveryDate: addDays(to.pickupDate, 2), deliverySlot: 'NOON' });
        const mine = async (id: string) => (await http.get(`/v1/orders/${id}`).set(who.auth).expect(200)).body;

        it('refuses a move into a full window with SLOT_FULL, changing and counting nothing', async () => {
          const full = win(21);
          await book(full).expect(201);
          await book(full).expect(201);
          const order = (await book(win(22)).expect(201)).body;

          const refused = await move(order.id, full).expect(409);
          expect(refused.body).toMatchObject({ code: 'SLOT_FULL', details: { date: full.pickupDate, slot: 'MORNING' } });
          expect(await mine(order.id)).toMatchObject({ pickupDate: win(22).pickupDate, rescheduleCount: 0, reschedulesRemaining: 2, status: 'PENDING' });
          expect(await used(full)).toBe(2);
          expect(await prisma.auditLog.count({ where: { action: 'order.rescheduled', entityId: order.id } })).toBe(0);

          // The moment a place opens, the same move works.
          await prisma.order.updateMany({ where: { pickupDate: new Date(`${full.pickupDate}T00:00:00.000Z`), pickupSlot: 'MORNING', customerId: who.id }, data: { status: 'CANCELLED' } });
          await move(order.id, full).expect(200);
          expect(await mine(order.id)).toMatchObject({ pickupDate: full.pickupDate, rescheduleCount: 1 });
        });

        it('does not count the order against itself: keeping the pickup window and moving only the delivery works in a full window', async () => {
          const w = win(23);
          const one = (await book(w).expect(201)).body;
          await book(w).expect(201);
          expect(slotOf(await slots(), w).reason).toBe('FULL');
          const res = await http
            .post(`/v1/orders/${one.id}/reschedule`)
            .set(who.auth)
            .send({ pickupDate: w.pickupDate, pickupSlot: 'MORNING', deliveryDate: addDays(w.pickupDate, 3), deliverySlot: 'EVENING' })
            .expect(200);
          expect(res.body).toMatchObject({ pickupDate: w.pickupDate, deliveryDate: addDays(w.pickupDate, 3), rescheduleCount: 1 });
          expect(await used(w)).toBe(2);
        });

        it('lets a partner-accepted order move into a window with room, releasing its old place', async () => {
          const from = win(24);
          const to = win(25);
          const order = (await book(from).expect(201)).body;
          await book(from).expect(201);
          await prisma.order.update({ where: { id: order.id }, data: { status: 'PICKUP_ASSIGNED' } });
          await move(order.id, to).expect(200);
          expect(await used(from)).toBe(1);
          expect(await used(to)).toBe(1);
          // The place it left is free for someone else.
          await book(from).expect(201);
          await book(from).expect(409);
        });

        it('gives the last place to one of two moves made at the same moment', async () => {
          await setArea({ pickupCapacityPerSlot: 3 });
          const target = win(26);
          await book(target).expect(201);
          await book(target).expect(201);
          const x = (await book(win(27)).expect(201)).body;
          const y = (await book(win(28)).expect(201)).body;
          const results = await Promise.all([move(x.id, target), move(y.id, target)]);
          expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
          expect(results.find((r) => r.status === 409)!.body.code).toBe('SLOT_FULL');
          expect(await used(target)).toBe(3);
          // The one that lost kept its place and its change.
          const loser = results[0].status === 409 ? x : y;
          expect(await mine(loser.id)).toMatchObject({ rescheduleCount: 0 });
          await setArea({ pickupCapacityPerSlot: 2 });
        });

        it('lets a move and a booking compete fairly for the last place', async () => {
          await setArea({ pickupCapacityPerSlot: 2 });
          const target = win(29);
          await book(target).expect(201);
          const mover = (await book(win(20)).expect(201)).body;
          const [moved, booked] = await Promise.all([move(mover.id, target), book(target)]);
          // One got the place; the other was told SLOT_FULL.
          expect([moved.status === 200, booked.status === 201].filter(Boolean)).toHaveLength(1);
          expect([moved.status, booked.status].filter((code) => code === 409)).toHaveLength(1);
          expect(await used(target)).toBe(2);
        });
      });

      describe('staff overrides', () => {
        let full: { pickupDate: string; pickupSlot: string };
        beforeAll(async () => {
          full = win(8, 'EVENING');
          await setArea({ pickupCapacityPerSlot: 2 });
          await book(full).expect(201);
          await book(full).expect(201);
        });

        it('refuses a phone order into a full window until staff type a reason, then stores it on the order and in the audit log', async () => {
          expect((await phoneOrder(full).expect(409)).body.code).toBe('SLOT_FULL');
          await phoneOrder(full, { capacityOverrideReason: 'abc' }).expect(400);
          await phoneOrder(full, { capacityOverrideReason: '      ' }).expect(400);
          expect(await used(full)).toBe(2);

          const res = await phoneOrder(full, { capacityOverrideReason: '  Customer is away on the other days  ' }).expect(201);
          expect(res.body.capacityOverrideReason).toBe('Customer is away on the other days');
          expect((await orderRow(res.body.id)).capacityOverrideReason).toBe('Customer is away on the other days');
          expect((await orderRow(res.body.id)).areaOverrideReason).toBeNull();
          const log = await auditOf('order.placed_for_customer', res.body.id);
          expect(log.data).toMatchObject({ capacityOverrideReason: 'Customer is away on the other days' });
          expect(log.data).not.toHaveProperty('outsideAreaReason');
          expect(await used(full)).toBe(3);
          // It is over the cap now: still full for everyone else.
          expect(slotOf(await slots(), full)).toMatchObject({ available: false, reason: 'FULL' });
          expect((await book(full).expect(409)).body.code).toBe('SLOT_FULL');
        });

        it('keeps no reason when the window has room, and a customer cannot send one', async () => {
          const room = win(9, 'EVENING');
          const res = await phoneOrder(room, { capacityOverrideReason: 'Not needed here at all' }).expect(201);
          expect(res.body.capacityOverrideReason).toBeNull();
          expect((await orderRow(res.body.id)).capacityOverrideReason).toBeNull();
          await book(full, { capacityOverrideReason: 'Please let me in' }).expect(400);
          expect(await used(full)).toBe(3);
        });

        it('can use both overrides on one order', async () => {
          await setArea({ ...HUB, servicePincodes: LISTED });
          const farAddress = await addressFor(who, { pincode: '500033', area: 'Gachibowli', ...km(11) });
          const res = await http
            .post('/v1/admin/orders')
            .set(admin)
            .send({ customerId: who.id, ...draft(farAddress.id, full), outsideAreaReason: 'Regular customer there', capacityOverrideReason: 'Customer is away on other days' })
            .expect(201);
          expect(res.body).toMatchObject({ areaOverrideReason: 'Regular customer there', capacityOverrideReason: 'Customer is away on other days' });
          const log = await auditOf('order.placed_for_customer', res.body.id);
          expect(log.data).toMatchObject({ outsideAreaReason: 'Regular customer there', capacityOverrideReason: 'Customer is away on other days' });
          await setArea({ serviceCenterLatitude: null, serviceCenterLongitude: null, serviceRadiusKm: null, servicePincodes: [] });
        });

        it('replays a committed phone order without asking for the reason again', async () => {
          const room = win(10, 'MORNING');
          await book(room).expect(201);
          await book(room).expect(201);
          const send = () => phoneOrder(room, { capacityOverrideReason: 'Customer is away on other days' }).set('Idempotency-Key', 'staff-capacity-override-1');
          const first = await send().expect(201);
          const replay = await send().expect(201);
          expect(replay.body.id).toBe(first.body.id);
          expect(replay.headers['idempotent-replayed']).toBe('true');
          expect(await used(room)).toBe(3);
        });
      });
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

    describe('on a customer\'s request (website: delete-account)', () => {
      it('lets an administrator delete a customer who cannot open the app, and records who did it', async () => {
        // Created by staff, as for a phone order: the session endpoint is rate limited and this suite has used its share.
        const me = await http
          .post('/v1/admin/customers')
          .set(bearer(PHONES.admin))
          .send({ phone: PHONES.asked, name: 'Requested', email: 'asked@example.com' })
          .expect(201);

        await http.delete(`/v1/admin/customers/${me.body.id}`).set(bearer(PHONES.admin)).expect(204);
        const gone = await prisma.user.findUniqueOrThrow({ where: { id: me.body.id } });
        expect(gone).toMatchObject({ name: null, email: null, isActive: false });
        expect(gone.phone).toBe(`deleted:${me.body.id}`);
        const log = await prisma.auditLog.findFirstOrThrow({ where: { action: 'account.deleted', entityId: me.body.id } });
        const admin = await prisma.user.findFirstOrThrow({ where: { phone: '+919000000001' } });
        expect(log.actorId).toBe(admin.id);

        // Already gone: not found, not a second deletion.
        await http.delete(`/v1/admin/customers/${me.body.id}`).set(bearer(PHONES.admin)).expect(404);
      });

      it('refuses while the customer has orders in progress, and to anyone but staff', async () => {
        const me = await http.get('/v1/me').set(bearer(PHONES.customer)).expect(200);
        const res = await http.delete(`/v1/admin/customers/${me.body.id}`).set(bearer(PHONES.admin)).expect(409);
        expect(res.body.code).toBe('ACTIVE_ORDERS');
        await http.delete(`/v1/admin/customers/${me.body.id}`).set(bearer(PHONES.customer)).expect(403);
        await http.delete(`/v1/admin/customers/${me.body.id}`).expect(401);
      });
    });
  });

  describe('undelivered alerts', () => {
    type Delivery = Awaited<ReturnType<typeof prisma.pushDelivery.findMany>>[number];
    const DAY_MS = 24 * 60 * 60 * 1000;
    const sarees = () => [{ catalogItemId: sareeId, quantity: 1 }];
    const base = '/v1/admin/notification-deliveries';
    const list = (phone: string, query: Record<string, string | number> = {}) => http.get(base).set(bearer(phone)).query({ pageSize: 100, ...query });
    const retry = (id: string, phone = PHONES.admin) => http.post(`${base}/${id}/retry`).set(bearer(phone));
    const followedUp = (id: string, phone = PHONES.admin) => http.post(`${base}/${id}/handled`).set(bearer(phone));
    const userIdOf = async (phone: string) => (await prisma.user.findFirstOrThrow({ where: { phone: `+91${phone}` } })).id;
    const dashboardCount = async () => (await http.get('/v1/admin/dashboard').set(bearer(PHONES.admin)).expect(200)).body.undeliveredAlerts as number;
    const ids = (res: { body: { items: { id: string }[] } }) => res.body.items.map((i) => i.id);
    const fresh = async (userId: string, extra: Record<string, unknown> = {}) =>
      prisma.pushDelivery.create({
        data: { userId, app: 'CUSTOMER', type: 'order_status', title: 'Out for delivery', status: 'FAILED', deviceCount: 1, failedCount: 1, errorCode: 'unknown', ...extra },
      });

    let customerId: string;
    let opsId: string;
    let ownerId: string;
    let orderA: { id: string; orderNumber: string };
    let orderB: { id: string; orderNumber: string };
    let orderC: { id: string; orderNumber: string };
    /** Who got which alert, per order: the customer's "order placed" and the two admins' "new order". */
    const rows: Record<'a' | 'b' | 'c', { customer?: Delivery; ops?: Delivery; owner?: Delivery }> = { a: {}, b: {}, c: {} };

    /** Places an order and waits for its three alerts to be written down (one customer, two admins). */
    async function placeAndRecord(order: 'a' | 'b' | 'c') {
      const placed = await placeAndDispatch(sarees());
      await waitFor(async () => (await prisma.pushDelivery.count({ where: { orderId: placed.id } })) >= 3);
      const all = await prisma.pushDelivery.findMany({ where: { orderId: placed.id } });
      rows[order] = {
        customer: all.find((d) => d.userId === customerId),
        ops: all.find((d) => d.userId === opsId),
        owner: all.find((d) => d.userId === ownerId),
      };
      return placed as { id: string; orderNumber: string };
    }

    beforeAll(async () => {
      [customerId, opsId, ownerId] = await Promise.all([userIdOf(PHONES.customer), userIdOf(PHONES.admin), userIdOf(PHONES.superAdmin)]);
    });

    afterAll(() => {
      firebase.messaging = null;
      fcm.reset();
    });

    it('records nothing while push is not set up, so local development shows no false failures', async () => {
      const order = await placeAndDispatch(sarees());
      await waitFor(async () => (await prisma.notification.count({ where: { type: 'new_order', data: { path: ['orderId'], equals: order.id } } })) === 2);
      await new Promise((r) => setTimeout(r, 150));
      expect(await prisma.pushDelivery.count()).toBe(0);
      expect(fcm.sent).toHaveLength(0);
      expect(await dashboardCount()).toBe(0);
    });

    it('records a delivery per person: sent, partly sent and no device', async () => {
      firebase.messaging = fcm;
      await prisma.device.create({ data: { userId: customerId, fcmToken: 'tok-customer-1', platform: 'ANDROID', app: 'CUSTOMER' } });
      await prisma.device.createMany({
        data: [
          { userId: opsId, fcmToken: 'tok-ops-good', platform: 'ANDROID', app: 'ADMIN' },
          { userId: opsId, fcmToken: 'tok-ops-bad', platform: 'IOS', app: 'ADMIN' },
          // A phone registered for another app does not count as a device for admin alerts.
          { userId: ownerId, fcmToken: 'tok-owner-customer-app', platform: 'ANDROID', app: 'CUSTOMER' },
        ],
      });
      fcm.refusals.set('tok-ops-bad', 'messaging/internal-error');

      orderA = await placeAndRecord('a');
      const { customer, ops, owner } = rows.a;
      expect(customer).toMatchObject({ status: 'SENT', app: 'CUSTOMER', type: 'order_placed', title: 'Order placed', deviceCount: 1, failedCount: 0, errorCode: null, handledAt: null, orderId: orderA.id });
      expect(ops).toMatchObject({ status: 'PARTIAL', app: 'ADMIN', type: 'new_order', deviceCount: 2, failedCount: 1, errorCode: 'messaging/internal-error' });
      expect(owner).toMatchObject({ status: 'NO_DEVICE', app: 'ADMIN', deviceCount: 0, failedCount: 0, errorCode: null });

      // Each delivery points at the inbox row it was for.
      const inbox = await prisma.notification.findUniqueOrThrow({ where: { id: customer!.notificationId! } });
      expect(inbox).toMatchObject({ userId: customerId, type: 'order_placed', title: 'Order placed' });

      // Sending itself is unchanged: customers get their own alert, admins get theirs on both phones, only on the right app.
      const toCustomer = fcm.sent.find((s) => s.tokens.includes('tok-customer-1'));
      expect(toCustomer).toMatchObject({ tokens: ['tok-customer-1'], title: 'Order placed', data: { type: 'order_placed', orderId: orderA.id } });
      const toAdmins = fcm.sent.find((s) => s.tokens.includes('tok-ops-good'));
      expect(toAdmins?.tokens.sort()).toEqual(['tok-ops-bad', 'tok-ops-good']);
      expect(fcm.sent.some((s) => s.tokens.includes('tok-owner-customer-app'))).toBe(false);
      // A device that refused for a passing reason is kept; offers to partners are never recorded.
      expect(await prisma.device.count({ where: { fcmToken: 'tok-ops-bad' } })).toBe(1);
      expect(await prisma.pushDelivery.count({ where: { app: 'PARTNER' } })).toBe(0);
    });

    it('records a failure when every phone refuses, and still removes phones Firebase says are gone', async () => {
      fcm.refusals.set('tok-customer-1', 'messaging/registration-token-not-registered');
      orderB = await placeAndRecord('b');
      expect(rows.b.customer).toMatchObject({ status: 'FAILED', deviceCount: 1, failedCount: 1, errorCode: 'messaging/registration-token-not-registered' });
      expect(rows.b.ops?.status).toBe('PARTIAL');
      expect(rows.b.owner?.status).toBe('NO_DEVICE');
      expect(await prisma.device.count({ where: { fcmToken: 'tok-customer-1' } })).toBe(0);
    });

    it('records a failure when the whole send call fails, and keeps the phone', async () => {
      await prisma.device.create({ data: { userId: customerId, fcmToken: 'tok-customer-2', platform: 'ANDROID', app: 'CUSTOMER' } });
      fcm.throwNext('messaging/server-unavailable');
      orderC = await placeAndRecord('c');
      expect(rows.c.customer).toMatchObject({ status: 'FAILED', deviceCount: 1, failedCount: 1, errorCode: 'messaging/server-unavailable' });
      expect(await prisma.device.count({ where: { fcmToken: 'tok-customer-2' } })).toBe(1);
      // The inbox row is there whatever happened to the push.
      expect(await prisma.notification.count({ where: { id: rows.c.customer!.notificationId! } })).toBe(1);
    });

    it('lists only alerts that did not fully arrive, with who, what, why and which order', async () => {
      const res = await list(PHONES.admin).expect(200);
      const open = ids(res);
      expect(open).toEqual(expect.arrayContaining([rows.a.ops!.id, rows.a.owner!.id, rows.b.customer!.id, rows.b.ops!.id, rows.b.owner!.id, rows.c.customer!.id]));
      expect(open).not.toContain(rows.a.customer!.id);
      expect(res.body.items.every((i: { status: string }) => i.status !== 'SENT')).toBe(true);
      const times = res.body.items.map((i: { createdAt: string }) => Date.parse(i.createdAt));
      expect(times).toEqual([...times].sort((x, y) => y - x));

      const failed = res.body.items.find((i: { id: string }) => i.id === rows.b.customer!.id);
      expect(failed).toMatchObject({
        status: 'FAILED',
        app: 'CUSTOMER',
        type: 'order_placed',
        title: 'Order placed',
        deviceCount: 1,
        failedCount: 1,
        errorCode: 'messaging/registration-token-not-registered',
        reason: 'Their phone no longer accepts alerts (app removed or notifications turned off)',
        recipient: { id: customerId, name: 'Priya', phone: '+919333333333' },
        orderId: orderB.id,
        orderNumber: orderB.orderNumber,
        handledAt: null,
        handledByName: null,
        canRetry: true,
        retryBlockedReason: null,
      });
      const none = res.body.items.find((i: { id: string }) => i.id === rows.b.owner!.id);
      expect(none).toMatchObject({ status: 'NO_DEVICE', reason: 'Has not allowed notifications on the app yet', recipient: { id: ownerId, name: 'Owner' } });
      const thrown = res.body.items.find((i: { id: string }) => i.id === rows.c.customer!.id);
      expect(thrown.reason).toMatch(/briefly unavailable/);
    });

    it('filters by outcome, app, order number and date, and pages', async () => {
      const noDevice = await list(PHONES.admin, { status: 'NO_DEVICE' }).expect(200);
      expect(noDevice.body.items.every((i: { status: string }) => i.status === 'NO_DEVICE')).toBe(true);
      expect(ids(noDevice)).toContain(rows.a.owner!.id);
      expect(ids(noDevice)).not.toContain(rows.b.customer!.id);

      const sent = await list(PHONES.admin, { status: 'SENT' }).expect(200);
      expect(ids(sent)).toContain(rows.a.customer!.id);
      expect(sent.body.items.every((i: { status: string }) => i.status === 'SENT')).toBe(true);

      const customerApp = await list(PHONES.admin, { app: 'CUSTOMER' }).expect(200);
      expect(customerApp.body.items.every((i: { app: string }) => i.app === 'CUSTOMER')).toBe(true);
      expect(ids(customerApp)).toEqual(expect.arrayContaining([rows.b.customer!.id, rows.c.customer!.id]));
      expect(ids(customerApp)).not.toContain(rows.b.ops!.id);

      const byOrder = await list(PHONES.admin, { orderNumber: ` ${orderB.orderNumber.toLowerCase()} ` }).expect(200);
      expect(ids(byOrder).sort()).toEqual([rows.b.customer!.id, rows.b.ops!.id, rows.b.owner!.id].sort());

      const today = istDate(new Date());
      expect((await list(PHONES.admin, { from: addDays(today, 1) }).expect(200)).body.total).toBe(0);
      expect((await list(PHONES.admin, { to: addDays(today, -1) }).expect(200)).body.total).toBe(0);
      expect(ids(await list(PHONES.admin, { from: today, to: today }).expect(200))).toContain(rows.b.customer!.id);

      const all = await list(PHONES.admin).expect(200);
      const page2 = await list(PHONES.admin, { pageSize: 2, page: 2 }).expect(200);
      expect(page2.body).toMatchObject({ page: 2, pageSize: 2, total: all.body.total });
      expect(ids(page2)).toEqual(ids(all).slice(2, 4));

      await list(PHONES.admin, { status: 'BOGUS' }).expect(400);
      await list(PHONES.admin, { from: 'yesterday' }).expect(400);
    });

    it('retries an alert, records it as a new delivery and marks the old one followed up', async () => {
      const before = fcm.sent.length;
      const res = await retry(rows.b.customer!.id).expect(200);
      expect(res.body).toMatchObject({ status: 'SENT', reason: 'Delivered', orderNumber: orderB.orderNumber, recipient: { id: customerId }, canRetry: false, handledAt: null });
      expect(res.body.id).not.toBe(rows.b.customer!.id);
      // The same alert goes to the phone they have now.
      expect(fcm.sent).toHaveLength(before + 1);
      expect(fcm.sent.at(-1)).toMatchObject({
        tokens: ['tok-customer-2'],
        title: 'Order placed',
        data: { type: 'order_placed', orderId: orderB.id, orderNumber: orderB.orderNumber },
      });
      const original = await prisma.pushDelivery.findUniqueOrThrow({ where: { id: rows.b.customer!.id } });
      expect(original).toMatchObject({ status: 'FAILED', handledById: opsId });
      expect(original.handledAt).not.toBeNull();
      const retried = await prisma.pushDelivery.findUniqueOrThrow({ where: { id: res.body.id } });
      expect(retried.notificationId).toBe(original.notificationId);

      expect(ids(await list(PHONES.admin).expect(200))).not.toContain(rows.b.customer!.id);
      await waitFor(async () => (await prisma.auditLog.count({ where: { action: 'notification_delivery.retried', entityId: rows.b.customer!.id, actorId: opsId } })) === 1);

      // Already delivered: neither the old attempt nor the new one can be sent again, and nothing more goes out.
      expect((await retry(rows.b.customer!.id).expect(409)).body.code).toBe('ALREADY_DELIVERED');
      expect((await retry(res.body.id).expect(409)).body.code).toBe('ALREADY_DELIVERED');
      expect((await retry(rows.a.customer!.id).expect(409)).body.code).toBe('ALREADY_DELIVERED');
      expect(fcm.sent).toHaveLength(before + 1);
    });

    it('keeps one open row per alert when a retry fails again, and stops after a few tries', async () => {
      let latest = rows.a.ops!.id;
      for (let i = 0; i < 3; i += 1) {
        const res = await retry(latest).expect(200);
        expect(res.body).toMatchObject({ status: 'PARTIAL', failedCount: 1, errorCode: 'messaging/internal-error', canRetry: i < 2 });
        latest = res.body.id;
      }
      const last = await list(PHONES.admin, { orderNumber: orderA.orderNumber }).expect(200);
      const opsRows = last.body.items.filter((i: { recipient: { id: string } }) => i.recipient.id === opsId);
      expect(opsRows.map((i: { id: string }) => i.id)).toEqual([latest]);
      expect(opsRows[0].retryBlockedReason).toMatch(/most times allowed/);

      const everything = await list(PHONES.admin, { orderNumber: orderA.orderNumber, followUp: 'ALL' }).expect(200);
      expect(everything.body.items.filter((i: { recipient: { id: string } }) => i.recipient.id === opsId)).toHaveLength(4);
      const done = await list(PHONES.admin, { orderNumber: orderA.orderNumber, followUp: 'DONE' }).expect(200);
      expect(ids(done)).toContain(rows.a.ops!.id);
      expect(done.body.items.find((i: { id: string }) => i.id === rows.a.ops!.id)?.handledByName).toBe('Ops');

      expect((await retry(latest).expect(409)).body.code).toBe('RETRY_LIMIT');
      expect((await retry(rows.a.ops!.id).expect(409)).body.code).toBe('ALREADY_RETRIED');
    });

    it('sends only once when the button is pressed twice at the same moment', async () => {
      const sentTo = () => fcm.sent.filter((s) => s.tokens.includes('tok-customer-2') && s.data?.orderId === orderC.id).length;
      expect(sentTo()).toBe(0);
      const results = await Promise.all([retry(rows.c.customer!.id), retry(rows.c.customer!.id)]);
      expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
      expect(results.find((r) => r.status === 409)!.body.code).toMatch(/^(RETRY_IN_PROGRESS|ALREADY_RETRIED)$/);
      expect(sentTo()).toBe(1);
      expect(await prisma.pushDelivery.count({ where: { notificationId: rows.c.customer!.notificationId } })).toBe(2);
    });

    it('refuses to retry when the notification is gone or push is not set up, and retries a person who has since allowed alerts', async () => {
      // The notification was deleted: nothing to resend, and the list says so.
      await prisma.notification.delete({ where: { id: rows.b.owner!.notificationId! } });
      const gone = await list(PHONES.admin, { orderNumber: orderB.orderNumber, followUp: 'ALL' }).expect(200);
      expect(gone.body.items.find((i: { id: string }) => i.id === rows.b.owner!.id)).toMatchObject({ canRetry: false, retryBlockedReason: expect.stringMatching(/deleted/) });
      expect((await retry(rows.b.owner!.id).expect(409)).body.code).toBe('NOTIFICATION_GONE');
      expect(await prisma.pushDelivery.findUniqueOrThrow({ where: { id: rows.b.owner!.id } })).toMatchObject({ notificationId: null, status: 'NO_DEVICE' });

      firebase.messaging = null;
      const off = await retry(rows.a.owner!.id).expect(503);
      expect(off.body.code).toBe('PUSH_NOT_CONFIGURED');
      firebase.messaging = fcm;
      expect(await prisma.pushDelivery.count({ where: { notificationId: rows.a.owner!.notificationId } })).toBe(1);

      // Still no phone: it is recorded again as no device.
      const still = await retry(rows.a.owner!.id).expect(200);
      expect(still.body).toMatchObject({ status: 'NO_DEVICE', reason: 'Has not allowed notifications on the app yet', canRetry: true });

      // They allow notifications later: the retry gets through.
      await prisma.device.create({ data: { userId: ownerId, fcmToken: 'tok-owner-admin', platform: 'ANDROID', app: 'ADMIN' } });
      const ok = await retry(rows.c.owner!.id).expect(200);
      expect(ok.body).toMatchObject({ status: 'SENT', deviceCount: 1, failedCount: 0 });
      expect(fcm.sent.at(-1)).toMatchObject({ tokens: ['tok-owner-admin'], title: 'New order', data: { orderId: orderC.id } });
    });

    it('marks an alert as followed up once, and only for alerts that did not arrive', async () => {
      const target = rows.b.ops!;
      const res = await followedUp(target.id).expect(200);
      expect(res.body).toMatchObject({ id: target.id, status: 'PARTIAL', handledByName: 'Ops' });
      expect(res.body.handledAt).not.toBeNull();

      // A second person pressing it changes nothing.
      const again = await followedUp(target.id, PHONES.superAdmin).expect(200);
      expect(again.body).toMatchObject({ handledAt: res.body.handledAt, handledByName: 'Ops' });
      await waitFor(async () => (await prisma.auditLog.count({ where: { action: 'notification_delivery.handled', entityId: target.id } })) === 1);

      expect(ids(await list(PHONES.admin).expect(200))).not.toContain(target.id);
      expect(ids(await list(PHONES.admin, { followUp: 'DONE' }).expect(200))).toContain(target.id);
      expect(ids(await list(PHONES.admin, { followUp: 'ALL' }).expect(200))).toContain(target.id);

      expect((await followedUp(rows.a.customer!.id).expect(409)).body.code).toBe('ALREADY_DELIVERED');
      await followedUp('00000000-0000-4000-8000-000000000000').expect(404);
      await followedUp('not-a-uuid').expect(400);
    });

    it('is for admins and super admins only', async () => {
      const target = rows.c.ops!;
      for (const phone of [PHONES.customer, PHONES.driver1]) {
        expect((await list(phone).expect(403)).body.code).toBe('FORBIDDEN_ROLE');
        await followedUp(target.id, phone).expect(403);
      }
      await retry(target.id, PHONES.customer).expect(403);
      await http.get(base).expect(401);
      await http.post(`${base}/${target.id}/handled`).expect(401);
      await list(PHONES.superAdmin).expect(200);
      await list(PHONES.admin).expect(200);
      // Nothing was changed by the refused calls.
      expect(await prisma.pushDelivery.findUniqueOrThrow({ where: { id: target.id } })).toMatchObject({ handledAt: null });
      expect(await prisma.pushDelivery.count({ where: { notificationId: target.notificationId } })).toBe(1);
    });

    it('counts unhandled alerts from the last 14 days on the dashboard', async () => {
      const unhandled = await prisma.pushDelivery.count({
        where: { status: { not: 'SENT' }, handledAt: null, createdAt: { gte: new Date(Date.now() - 14 * DAY_MS) } },
      });
      const count = await dashboardCount();
      expect(count).toBeGreaterThan(0);
      expect(count).toBe(unhandled);

      // Older than 14 days: still listed for follow-up, but not counted.
      const old = await fresh(customerId, { createdAt: new Date(Date.now() - 20 * DAY_MS) });
      expect(await dashboardCount()).toBe(count);
      expect(ids(await list(PHONES.admin).expect(200))).toContain(old.id);
      expect(ids(await list(PHONES.admin, { from: addDays(istDate(new Date()), -14) }).expect(200))).not.toContain(old.id);

      const recent = await fresh(customerId);
      expect(await dashboardCount()).toBe(count + 1);
      await followedUp(recent.id).expect(200);
      expect(await dashboardCount()).toBe(count);
      // A delivered alert is never counted.
      await prisma.pushDelivery.create({ data: { userId: customerId, app: 'CUSTOMER', type: 'order_status', title: 'Delivered', status: 'SENT', deviceCount: 1, failedCount: 0 } });
      expect(await dashboardCount()).toBe(count);
    });

    it('keeps status and counts consistent in the database', async () => {
      const bad = (status: 'SENT' | 'PARTIAL' | 'FAILED' | 'NO_DEVICE', deviceCount: number, failedCount: number) =>
        prisma.pushDelivery.create({ data: { userId: customerId, app: 'CUSTOMER', type: 't', title: 't', status, deviceCount, failedCount } });
      await expect(bad('SENT', 0, 0)).rejects.toThrow();
      await expect(bad('SENT', 2, 1)).rejects.toThrow();
      await expect(bad('PARTIAL', 2, 2)).rejects.toThrow();
      await expect(bad('PARTIAL', 2, 0)).rejects.toThrow();
      await expect(bad('FAILED', 2, 1)).rejects.toThrow();
      await expect(bad('NO_DEVICE', 1, 0)).rejects.toThrow();
      await expect(bad('FAILED', 1, 2)).rejects.toThrow();
      await expect(bad('NO_DEVICE', 0, 0)).resolves.toBeDefined();
    });

    it('is erased with the customer\'s account', async () => {
      const gone = await http.post('/v1/admin/customers').set(bearer(PHONES.admin)).send({ phone: '9888888888', name: 'Short stay' }).expect(201);
      const note = await prisma.notification.create({ data: { userId: gone.body.id, type: 'order_status', title: 'Delivered', body: 'Thanks' } });
      await fresh(gone.body.id, { notificationId: note.id, status: 'NO_DEVICE', deviceCount: 0, failedCount: 0, errorCode: null });
      await http.delete(`/v1/admin/customers/${gone.body.id}`).set(bearer(PHONES.admin)).expect(204);
      expect(await prisma.pushDelivery.count({ where: { userId: gone.body.id } })).toBe(0);
    });
  });

  describe('Google customers', () => {
    // Created directly: the session endpoint is rate limited and this suite has used its share. The sign-in paths
    // (creating the account, linking a verified number, refusing staff apps) are covered by the AuthService unit tests.
    const google = { Authorization: 'Bearer dev-google:gina@example.com' };
    const orderBody = () => ({
      items: [{ catalogItemId: shirtId, quantity: 2 }],
      pickupDate: tomorrow,
      pickupSlot: 'MORNING',
      deliveryDate: dayAfter,
      deliverySlot: 'EVENING',
      pickupAddressId: googleAddressId,
      paymentMethod: 'COD',
    });
    let googleAddressId: string;
    let googleCustomerId: string;

    it('can browse and quote with no number, but not order, and admins can still see them', async () => {
      const user = await prisma.user.create({
        data: { firebaseUid: 'dev-google-gina@example.com', phone: null, email: 'gina@example.com', name: 'Gina', role: 'CUSTOMER' },
      });
      googleCustomerId = user.id;
      const me = await http.get('/v1/me').set(google).expect(200);
      expect(me.body).toMatchObject({ phone: null, email: 'gina@example.com', isProfileComplete: true });

      const address = await http
        .post('/v1/me/addresses')
        .set(google)
        .send({ houseNo: '9', street: 'Road 5', area: 'Jubilee Hills', city: 'Hyderabad', state: 'Telangana', pincode: '500033', latitude: 17.4126, longitude: 78.4482 })
        .expect(201);
      googleAddressId = address.body.id;
      await http.post('/v1/orders/quote').set(google).send({ items: orderBody().items }).expect(200);

      const refused = await http.post('/v1/orders').set(google).send(orderBody()).expect(400);
      expect(refused.body.code).toBe('PHONE_REQUIRED');
      expect(await prisma.order.count({ where: { customerId: googleCustomerId } })).toBe(0);

      const listed = await http.get('/v1/admin/customers').set(bearer(PHONES.admin)).query({ search: 'gina' }).expect(200);
      expect(listed.body.items[0]).toMatchObject({ email: 'gina@example.com', phone: null });
      await http.get(`/v1/admin/customers/${googleCustomerId}`).set(bearer(PHONES.admin)).expect(200);
    });

    it('takes the order once they type a number, with no SMS code, and gives the partner that number', async () => {
      const bad = await http.patch('/v1/me').set(google).send({ phone: '12345' }).expect(400);
      expect(bad.body.code).toBe('INVALID_PHONE');

      const saved = await http.patch('/v1/me').set(google).send({ phone: '97777 77777' }).expect(200);
      expect(saved.body).toMatchObject({ phone: '+919777777777', phoneVerified: false });
      // Kept apart from the unique sign-in number, so a mistyped number cannot take over someone else's account.
      expect(await prisma.user.findUnique({ where: { phone: '+919777777777' } })).toBeNull();
      expect((await http.get('/v1/me').set(google).expect(200)).body.phone).toBe('+919777777777');

      const placed = await http.post('/v1/orders').set(google).send(orderBody()).expect(201);
      expect(placed.body.pickupAddress.contactPhone).toBe('+919777777777');
      const detail = await http.get(`/v1/admin/orders/${placed.body.id}`).set(bearer(PHONES.admin)).expect(200);
      expect(detail.body.customer).toMatchObject({ id: googleCustomerId, phone: '+919777777777' });

      const found = await http.get('/v1/admin/customers').set(bearer(PHONES.admin)).query({ search: '9777777777' }).expect(200);
      expect(found.body.items.map((c: { id: string }) => c.id)).toEqual([googleCustomerId]);
    });

    it('lets two customers share a contact number, and keeps a code-verified number as it is', async () => {
      await prisma.user.create({
        data: { firebaseUid: 'dev-google-hari@example.com', phone: null, email: 'hari@example.com', name: 'Hari', role: 'CUSTOMER' },
      });
      const shared = await http
        .patch('/v1/me')
        .set({ Authorization: 'Bearer dev-google:hari@example.com' })
        .send({ phone: '9777777777' })
        .expect(200);
      expect(shared.body.phone).toBe('+919777777777');

      const swap = await http.patch('/v1/me').set(bearer(PHONES.customer)).send({ phone: '9777777777' }).expect(400);
      expect(swap.body.code).toBe('PHONE_VERIFIED');
      const verified = await prisma.user.findUniqueOrThrow({ where: { phone: `+91${PHONES.customer}` } });
      expect(verified.contactPhone).toBeNull();
    });
  });

  describe('staff-run delivery, refunds due and the audit log', () => {
    const orderPath = (id: string) => `/v1/admin/orders/${id}`;
    const status = (id: string, body: Record<string, unknown>) => http.post(`${orderPath(id)}/status`).set(bearer(PHONES.admin)).send(body);
    const assign = (id: string, leg: 'PICKUP' | 'DELIVERY') =>
      http.post(`${orderPath(id)}/assign`).set(bearer(PHONES.admin)).send({ leg, driverId: driver1Id }).expect(200);

    /** What staff do when nobody uses the partner app: every step from the admin. */
    async function walkToOutForDelivery(id: string) {
      await assign(id, 'PICKUP');
      for (const next of ['PICKED_UP', 'PROCESSING', 'READY_FOR_DELIVERY']) await status(id, { status: next }).expect(200);
      await assign(id, 'DELIVERY');
      await status(id, { status: 'OUT_FOR_DELIVERY' }).expect(200);
    }

    const sarees = () => [{ catalogItemId: sareeId, quantity: 1 }];

    it('records the cash with the delivery when staff say it was collected', async () => {
      const order = await placeAndDispatch(sarees());
      await walkToOutForDelivery(order.id);

      const wrongStatus = await status(order.id, { status: 'READY_FOR_DELIVERY', collectedCash: true }).expect(400);
      expect(wrongStatus.body.code).toBe('CASH_ONLY_WITH_DELIVERY');

      const done = await status(order.id, { status: 'DELIVERED', collectedCash: true }).expect(200);
      expect(done.body).toMatchObject({ status: 'DELIVERED', paymentStatus: 'PAID', paidPaise: 4000, amountDuePaise: 0 });

      const payments = await prisma.payment.findMany({ where: { orderId: order.id } });
      expect(payments).toEqual([expect.objectContaining({ provider: 'CASH', status: 'CAPTURED', amountPaise: 4000 })]);
      const staff = await prisma.user.findFirstOrThrow({ where: { phone: `+91${PHONES.admin}` } });
      expect(payments[0].collectedById).toBe(staff.id);
      await waitFor(async () => (await prisma.notification.count({ where: { type: 'payment_received', data: { path: ['orderId'], equals: order.id } } })) === 1);
    });

    it('still lets staff deliver first and take the payment afterwards', async () => {
      const order = await placeAndDispatch(sarees());
      await walkToOutForDelivery(order.id);
      const done = await status(order.id, { status: 'DELIVERED' }).expect(200);
      expect(done.body).toMatchObject({ status: 'DELIVERED', paymentStatus: 'UNPAID', amountDuePaise: 4000 });
      expect(await prisma.payment.count({ where: { orderId: order.id } })).toBe(0);
    });

    it('lists orders that owe the customer money, and counts them on the dashboard', async () => {
      const paid = await placeAndDispatch(sarees());
      await http.post(`${orderPath(paid.id)}/payments/cash`).set(bearer(PHONES.admin)).send({ amountPaise: 4000 }).expect(204);
      await status(paid.id, { status: 'CANCELLED', note: 'Customer called' }).expect(200);
      const unpaid = await placeAndDispatch(sarees());
      await status(unpaid.id, { status: 'CANCELLED' }).expect(200);

      const due = await http.get('/v1/admin/orders').set(bearer(PHONES.admin)).query({ refundDue: 'true' }).expect(200);
      const ids = due.body.items.map((o: { id: string }) => o.id);
      expect(ids).toContain(paid.id);
      expect(ids).not.toContain(unpaid.id);
      const dash = await http.get('/v1/admin/dashboard').set(bearer(PHONES.admin)).expect(200);
      expect(dash.body.refundsDue).toBe(due.body.total);
      await waitFor(async () => (await prisma.notification.count({ where: { type: 'refund_needed', data: { path: ['orderId'], equals: paid.id } } })) > 0);
    });

    it('tells the customer the new total when staff change the items, and staff when money must go back', async () => {
      const order = await placeAndDispatch([{ catalogItemId: sareeId, quantity: 2 }]); // 8000
      await http.post(`${orderPath(order.id)}/payments/cash`).set(bearer(PHONES.admin)).send({ amountPaise: 8000 }).expect(204);
      await http.put(`${orderPath(order.id)}/items`).set(bearer(PHONES.admin)).send({ items: sarees() }).expect(200); // 4000

      await waitFor(async () => (await prisma.notification.count({ where: { type: 'order_updated', data: { path: ['orderId'], equals: order.id } } })) === 1);
      const note = await prisma.notification.findFirstOrThrow({ where: { type: 'order_updated', data: { path: ['orderId'], equals: order.id } } });
      expect(note.body).toContain('new total is ₹40');
      expect(note.body).toContain('return the extra ₹40');
      await waitFor(async () => (await prisma.notification.count({ where: { type: 'refund_needed', data: { path: ['orderId'], equals: order.id } } })) > 0);
      const due = await http.get('/v1/admin/orders').set(bearer(PHONES.admin)).query({ refundDue: 'true' }).expect(200);
      expect(due.body.items.map((o: { id: string }) => o.id)).toContain(order.id);
    });

    it('shows super admins who changed what, newest first, and nobody else', async () => {
      const order = await placeAndDispatch(sarees());
      await status(order.id, { status: 'CANCELLED', note: 'Audit me' }).expect(200);
      await waitFor(async () => {
        const res = await http.get('/v1/admin/audit').set(bearer(PHONES.superAdmin)).query({ entity: 'order', entityId: order.id });
        return res.body.total >= 1;
      });
      const log = await http.get('/v1/admin/audit').set(bearer(PHONES.superAdmin)).query({ entity: 'order', entityId: order.id }).expect(200);
      expect(log.body.items[0]).toMatchObject({ action: 'order.status_changed', entity: 'order', entityId: order.id, actorName: 'Ops', data: { to: 'CANCELLED', note: 'Audit me' } });
      const denied = await http.get('/v1/admin/audit').set(bearer(PHONES.admin)).expect(403);
      expect(denied.body.code).toBe('FORBIDDEN_ROLE');
    });
  });

  describe('payments and refunds ledger', () => {
    const LEAK = 'whsec_must_never_reach_the_admin';
    const ledger = '/v1/admin/ledger';
    /** Seeded records are all in March 2020, so no other test's payments fall in this range. */
    const march = { from: '2020-03-01', to: '2020-03-31' };
    const at = (iso: string) => new Date(iso);
    const labelOf = new Map<string, string>();
    let customerIds: string[] = [];

    const list = (query: Record<string, string | number> = {}, phone = PHONES.admin) =>
      http.get(ledger).set(bearer(phone)).query(query);
    /** What a list or export shows, as the labels used below, newest first. */
    const labels = (res: { body: { items: { id: string }[] } }) => res.body.items.map((i) => labelOf.get(i.id));
    const inMarch = (query: Record<string, string | number> = {}) => list({ ...march, ...query });
    const orderRow = (customerId: string, orderNumber: string) => ({
      orderNumber,
      customerId,
      pickupDate: new Date(`${tomorrow}T00:00:00.000Z`),
      pickupSlot: 'MORNING' as const,
      deliveryDate: new Date(`${dayAfter}T00:00:00.000Z`),
      deliverySlot: 'EVENING' as const,
      pickupAddress: {},
      deliveryAddress: {},
      subtotalPaise: 20000,
      totalPaise: 20000,
      paymentMethod: 'ONLINE' as const,
    });

    beforeAll(async () => {
      const staff = await prisma.user.findFirstOrThrow({ where: { phone: `+91${PHONES.admin}` } });
      const lata = await prisma.user.create({ data: { phone: '+919700000001', name: 'Ledger Lata', role: 'CUSTOMER' } });
      // Never verified a number: only the contact number typed at checkout. Their name is built to be a formula and a CSV trap.
      const contactOnly = await prisma.user.create({
        data: { phone: null, contactPhone: '+919700000002', name: '@Contact "Only", Esq', role: 'CUSTOMER' },
      });
      customerIds = [lata.id, contactOnly.id];
      const a1 = await prisma.order.create({ data: orderRow(lata.id, 'LGR0001') });
      const a2 = await prisma.order.create({ data: orderRow(lata.id, 'LGR0002') });
      const b1 = await prisma.order.create({ data: orderRow(contactOnly.id, 'LGR0003') });

      const payment = async (label: string, data: Parameters<typeof prisma.payment.create>[0]['data']) =>
        labelOf.set((await prisma.payment.create({ data })).id, label);
      await payment('p1', { orderId: a1.id, provider: 'RAZORPAY', status: 'CAPTURED', amountPaise: 12000, razorpayOrderId: 'order_ledger_1', razorpayPaymentId: 'pay_ledger_1', raw: { event: 'payment.captured', secret: LEAK }, createdAt: at('2020-03-10T04:25:00Z'), capturedAt: at('2020-03-10T04:30:00Z') });
      await payment('p2', { orderId: a1.id, provider: 'CASH', status: 'CAPTURED', amountPaise: 5000, collectedById: staff.id, createdAt: at('2020-03-10T10:00:00Z'), capturedAt: at('2020-03-10T10:00:00Z') });
      await payment('p3', { orderId: a2.id, provider: 'RAZORPAY', status: 'FAILED', amountPaise: 3000, razorpayOrderId: 'order_ledger_3', razorpayPaymentId: 'pay_ledger_3', createdAt: at('2020-03-11T05:00:00Z') });
      await payment('p4', { orderId: a2.id, provider: 'RAZORPAY', status: 'CREATED', amountPaise: 7000, razorpayOrderId: 'order_ledger_4', createdAt: at('2020-03-12T05:00:00Z') });
      // 23:59:59.999 IST on the 14th, and the first instant of the 15th.
      await payment('p5', { orderId: b1.id, provider: 'CASH', status: 'CAPTURED', amountPaise: 9000, createdAt: at('2020-03-14T18:29:59.999Z'), capturedAt: at('2020-03-14T18:29:59.999Z') });
      await payment('p6', { orderId: b1.id, provider: 'CASH', status: 'CAPTURED', amountPaise: 800, createdAt: at('2020-03-14T18:30:00.000Z'), capturedAt: at('2020-03-14T18:30:00.000Z') });
      const p1 = await prisma.payment.findFirstOrThrow({ where: { razorpayPaymentId: 'pay_ledger_1' } });

      const refund = async (label: string, data: Parameters<typeof prisma.refund.create>[0]['data']) =>
        labelOf.set((await prisma.refund.create({ data })).id, label);
      await refund('r1', { orderId: a1.id, paymentId: p1.id, method: 'RAZORPAY', status: 'PROCESSED', amountPaise: 4000, razorpayRefundId: 'rfnd_ledger_1', note: 'Shirt damaged', createdAt: at('2020-03-12T05:00:00Z'), processedAt: at('2020-03-12T06:00:00Z') });
      await refund('r2', { orderId: a1.id, paymentId: p1.id, method: 'RAZORPAY', status: 'PENDING', amountPaise: 2500, razorpayRefundId: 'rfnd_ledger_2', note: 'Waiting on the bank', createdAt: at('2020-03-13T05:00:00Z') });
      await refund('r3', { orderId: b1.id, method: 'BANK_TRANSFER', status: 'FAILED', amountPaise: 1500, failureReason: 'Account closed', note: 'Refund to bank', createdAt: at('2020-03-14T05:00:00Z') });
      await refund('r4', { orderId: b1.id, method: 'CASH', status: 'PROCESSED', amountPaise: 1000, note: '=1+1 returned at the door', createdAt: at('2020-03-14T08:00:00Z'), processedAt: at('2020-03-14T09:00:00Z') });
    });

    afterAll(async () => {
      const ofLedgerOrders = { order: { orderNumber: { startsWith: 'LGR' } } };
      await prisma.refund.deleteMany({ where: ofLedgerOrders });
      await prisma.payment.deleteMany({ where: ofLedgerOrders });
      await prisma.order.deleteMany({ where: { orderNumber: { startsWith: 'LGR' } } });
      await prisma.user.deleteMany({ where: { id: { in: customerIds } } });
    });

    it('is for staff only', async () => {
      for (const path of [ledger, `${ledger}/export`]) {
        const res = await http.get(path).set(bearer(PHONES.customer)).expect(403);
        expect(res.body.code).toBe('FORBIDDEN_ROLE');
        await http.get(path).expect(401);
        await http.get(path).set(bearer(PHONES.admin)).expect(200);
        await http.get(path).set(bearer(PHONES.superAdmin)).expect(200);
      }
    });

    it('lists payments and refunds together, newest first, with their order and customer', async () => {
      const res = await inMarch().expect(200);
      expect(labels(res)).toEqual(['p6', 'p5', 'r4', 'r3', 'r2', 'r1', 'p4', 'p3', 'p2', 'p1']);
      expect(res.body).toMatchObject({ page: 1, pageSize: 20, total: 10 });
      const byLabel = (label: string) => res.body.items.find((i: { id: string }) => labelOf.get(i.id) === label);

      expect(byLabel('p1')).toMatchObject({
        kind: 'PAYMENT', status: 'CAPTURED', method: 'RAZORPAY', amountPaise: 12000, orderNumber: 'LGR0001',
        customerName: 'Ledger Lata', customerPhone: '+919700000001', reference: 'pay_ledger_1', note: null,
        failureReason: null, occurredAt: '2020-03-10T04:30:00.000Z',
      });
      expect(byLabel('p1').orderId).toBe((await prisma.order.findUniqueOrThrow({ where: { orderNumber: 'LGR0001' } })).id);
      expect(byLabel('p2')).toMatchObject({ method: 'CASH', reference: null, note: 'Collected by Ops' });
      // A checkout that was started and never finished has its order id and the time it was started.
      expect(byLabel('p4')).toMatchObject({ status: 'CREATED', reference: 'order_ledger_4', occurredAt: '2020-03-12T05:00:00.000Z' });
      // A refund shows when it went through, not when it was asked for.
      expect(byLabel('r1')).toMatchObject({
        kind: 'REFUND', status: 'PROCESSED', method: 'RAZORPAY', amountPaise: 4000, reference: 'rfnd_ledger_1',
        note: 'Shirt damaged', occurredAt: '2020-03-12T06:00:00.000Z',
      });
      expect(byLabel('r3')).toMatchObject({ status: 'FAILED', method: 'BANK_TRANSFER', failureReason: 'Account closed', reference: null });
      // No sign-in number: the contact number is shown.
      expect(byLabel('r4')).toMatchObject({ customerName: '@Contact "Only", Esq', customerPhone: '+919700000002' });
    });

    it('never shows what the gateway sent', async () => {
      const res = await inMarch({ pageSize: 100 }).expect(200);
      expect(JSON.stringify(res.body)).not.toContain(LEAK);
      for (const entry of res.body.items) {
        expect(Object.keys(entry).sort()).toEqual([
          'amountPaise', 'customerId', 'customerName', 'customerPhone', 'failureReason', 'id', 'kind', 'method', 'note',
          'occurredAt', 'orderId', 'orderNumber', 'reference', 'status',
        ]);
      }
    });

    it('totals the whole filtered set, not the page', async () => {
      const all = await inMarch().expect(200);
      expect(all.body.totals).toEqual({
        captured: { count: 4, amountPaise: 26800 },
        refunded: { count: 2, amountPaise: 5000 },
        refundPending: { count: 1, amountPaise: 2500 },
        failed: { count: 2, amountPaise: 4500 },
      });
      const second = await inMarch({ pageSize: 4, page: 2 }).expect(200);
      expect(labels(second)).toEqual(['r2', 'r1', 'p4', 'p3']);
      expect(second.body).toMatchObject({ page: 2, pageSize: 4, total: 10 });
      expect(second.body.totals).toEqual(all.body.totals);
      expect(labels(await inMarch({ pageSize: 4, page: 3 }))).toEqual(['p2', 'p1']);
      expect(labels(await inMarch({ pageSize: 4, page: 4 }))).toEqual([]);

      const refunds = await inMarch({ kind: 'REFUND' }).expect(200);
      expect(refunds.body.total).toBe(4);
      expect(refunds.body.totals).toEqual({
        captured: { count: 0, amountPaise: 0 },
        refunded: { count: 2, amountPaise: 5000 },
        refundPending: { count: 1, amountPaise: 2500 },
        failed: { count: 1, amountPaise: 1500 },
      });
    });

    it('asks for sensible pages and values', async () => {
      await inMarch({ pageSize: 101 }).expect(400);
      await inMarch({ page: 0 }).expect(400);
      await inMarch({ kind: 'TRANSFER' }).expect(400);
      await inMarch({ status: 'bogus' }).expect(400);
      await inMarch({ method: 'UPI' }).expect(400);
      await list({ from: '2020-3-1' }).expect(400);
    });

    it('filters by kind, status and method', async () => {
      expect(labels(await inMarch({ kind: 'PAYMENT' }))).toEqual(['p6', 'p5', 'p4', 'p3', 'p2', 'p1']);
      expect(labels(await inMarch({ kind: 'REFUND' }))).toEqual(['r4', 'r3', 'r2', 'r1']);
      expect(labels(await inMarch({ status: 'CAPTURED' }))).toEqual(['p6', 'p5', 'p2', 'p1']);
      expect(labels(await inMarch({ status: 'PROCESSED' }))).toEqual(['r4', 'r1']);
      expect(labels(await inMarch({ status: 'PENDING' }))).toEqual(['r2']);
      expect(labels(await inMarch({ status: 'FAILED' }))).toEqual(['r3', 'p3']);
      expect(labels(await inMarch({ status: 'CREATED' }))).toEqual(['p4']);
      expect(labels(await inMarch({ method: 'CASH' }))).toEqual(['p6', 'p5', 'r4', 'p2']);
      expect(labels(await inMarch({ method: 'RAZORPAY' }))).toEqual(['r2', 'r1', 'p4', 'p3', 'p1']);
      expect(labels(await inMarch({ method: 'BANK_TRANSFER' }))).toEqual(['r3']);
      expect(labels(await inMarch({ kind: 'REFUND', method: 'CASH', status: 'PROCESSED' }))).toEqual(['r4']);
      // A payment is never pending and a refund is never captured.
      const none = await inMarch({ kind: 'PAYMENT', status: 'PENDING' }).expect(200);
      expect(none.body).toMatchObject({ items: [], total: 0 });
      expect(none.body.totals.refundPending).toEqual({ count: 0, amountPaise: 0 });
    });

    it('finds what needs attention with status=problem: pending and failed, not an unfinished checkout', async () => {
      const res = await inMarch({ status: 'problem' }).expect(200);
      expect(labels(res)).toEqual(['r3', 'r2', 'p3']);
      expect(res.body.total).toBe(3);
      expect(res.body.totals).toEqual({
        captured: { count: 0, amountPaise: 0 },
        refunded: { count: 0, amountPaise: 0 },
        refundPending: { count: 1, amountPaise: 2500 },
        failed: { count: 2, amountPaise: 4500 },
      });
      expect(labels(await inMarch({ status: 'problem', kind: 'REFUND' }))).toEqual(['r3', 'r2']);
      expect(labels(await inMarch({ status: 'problem', method: 'RAZORPAY' }))).toEqual(['r2', 'p3']);
    });

    it('filters by IST date, whole days, both ends included', async () => {
      // 23:59:59.999 IST on the 14th is in; the first instant of the 15th is not.
      expect(labels(await list({ from: '2020-03-14', to: '2020-03-14' }))).toEqual(['p5', 'r4', 'r3']);
      expect(labels(await list({ from: '2020-03-15', to: '2020-03-15' }))).toEqual(['p6']);
      expect(labels(await list({ from: '2020-03-10', to: '2020-03-10' }))).toEqual(['p2', 'p1']);
      expect(labels(await list({ from: '2020-03-13', to: '2020-03-14' }))).toEqual(['p5', 'r4', 'r3', 'r2']);
      expect(labels(await list({ from: '2020-03-15', to: '2020-03-31' }))).toEqual(['p6']);
      expect(labels(await list({ to: '2020-03-10', from: '2020-01-01' }))).toEqual(['p2', 'p1']);
      expect((await list({ from: '2020-04-01', to: '2020-04-30' }).expect(200)).body.total).toBe(0);
      const backwards = await list({ from: '2020-03-15', to: '2020-03-14' }).expect(400);
      expect(backwards.body.code).toBe('INVALID_DATE_RANGE');
      const unreal = await list({ from: '2020-02-30' }).expect(400);
      expect(unreal.body.code).toBe('INVALID_DATE');
    });

    it('searches by order number, or by the customer\'s phone or contact phone', async () => {
      expect(labels(await inMarch({ search: 'LGR0002' }))).toEqual(['p4', 'p3']);
      expect(labels(await inMarch({ search: ' lgr0001 ' }))).toEqual(['r2', 'r1', 'p2', 'p1']);
      // Sign-in number, in any way a person writes it.
      for (const typed of ['9700000001', '+91 97000 00001', '09700000001']) {
        expect(labels(await inMarch({ search: typed }))).toEqual(['r2', 'r1', 'p4', 'p3', 'p2', 'p1']);
      }
      // The number typed at checkout, when there is no sign-in number.
      expect(labels(await inMarch({ search: '9700000002' }))).toEqual(['p6', 'p5', 'r4', 'r3']);
      // Part of a number, as typed so far.
      expect((await inMarch({ search: '970000' }).expect(200)).body.total).toBe(10);
      expect((await inMarch({ search: '0000002' }).expect(200)).body.total).toBe(4);
      // Letters, % and _ are only ever literal text.
      expect((await inMarch({ search: '%' }).expect(200)).body.total).toBe(0);
      expect((await inMarch({ search: 'LGR000_' }).expect(200)).body.total).toBe(0);
      expect((await inMarch({ search: "x'; DROP TABLE payments; --" }).expect(200)).body.total).toBe(0);
      // Search, filters and totals work together.
      const combined = await inMarch({ search: '9700000001', status: 'problem' }).expect(200);
      expect(labels(combined)).toEqual(['r2', 'p3']);
      expect(combined.body.totals.failed).toEqual({ count: 1, amountPaise: 3000 });
    });

    describe('CSV export', () => {
      const rows = (text: string) => text.replace('﻿', '').split('\r\n').slice(0, -1);
      const HEADER = 'Time (IST),Type,Status,Method,Amount (INR),Order,Customer,Phone,Reference,Note';
      const exportOf = (query: Record<string, string | number> = {}, phone = PHONES.admin) =>
        http.get(`${ledger}/export`).set(bearer(phone)).query(query);

      it('downloads the filtered list as a spreadsheet-safe file', async () => {
        const res = await exportOf(march).expect(200);
        expect(res.headers['content-type']).toBe('text/csv; charset=utf-8');
        expect(res.headers['content-disposition']).toMatch(/^attachment; filename="payments-ledger-\d{4}-\d{2}-\d{2}\.csv"$/);
        expect(res.headers['cache-control']).toBe('no-store');
        expect(res.headers['x-export-rows']).toBe('10');
        expect(res.headers['x-export-truncated']).toBe('false');
        expect(res.text.charCodeAt(0)).toBe(0xfeff);

        const lines = rows(res.text);
        expect(lines).toHaveLength(11);
        expect(lines[0]).toBe(HEADER);
        // Newest first; IST wall-clock time; rupees; a customer's name that is a formula is defused and quoted.
        expect(lines[1]).toBe('2020-03-15 00:00:00,PAYMENT,CAPTURED,CASH,8.00,LGR0003,"\'@Contact ""Only"", Esq",97000 00002,,');
        expect(lines[3]).toBe('2020-03-14 14:30:00,REFUND,PROCESSED,CASH,10.00,LGR0003,"\'@Contact ""Only"", Esq",97000 00002,,\'=1+1 returned at the door');
        expect(lines[4]).toBe('2020-03-14 10:30:00,REFUND,FAILED,BANK_TRANSFER,15.00,LGR0003,"\'@Contact ""Only"", Esq",97000 00002,,Refund to bank | Failed: Account closed');
        expect(lines[10]).toBe('2020-03-10 10:00:00,PAYMENT,CAPTURED,RAZORPAY,120.00,LGR0001,Ledger Lata,97000 00001,pay_ledger_1,');
        expect(res.text).not.toContain(LEAK);
        // No cell in the file starts with a character a spreadsheet would run.
        for (const line of lines.slice(1)) expect(line).not.toMatch(/(^|,)[=+\-@]/);
      });

      it('applies the list\'s filters', async () => {
        const problems = await exportOf({ ...march, status: 'problem' }).expect(200);
        expect(rows(problems.text).slice(1).map((l) => l.split(',')[2])).toEqual(['FAILED', 'PENDING', 'FAILED']);
        const mine = await exportOf({ ...march, search: '9700000001', kind: 'REFUND' }).expect(200);
        expect(rows(mine.text)).toHaveLength(3);
        const empty = await exportOf({ from: '2020-04-01', to: '2020-04-02' }).expect(200);
        expect(rows(empty.text)).toEqual([HEADER]);
        await exportOf({ from: '2020-03-15', to: '2020-03-14' }).expect(400);
        await exportOf({ status: 'bogus' }).expect(400);
      });

      it('holds at most 10,000 entries and says when it left some out', async () => {
        const customer = await prisma.user.findFirstOrThrow({ where: { phone: '+919700000001' } });
        const capOrder = await prisma.order.create({ data: orderRow(customer.id, 'LGRCAP1') });
        // One entry a minute from 2019-01-01 00:00 UTC (05:30 IST).
        const seed = (count: number, from: string) => prisma.$executeRaw`
          INSERT INTO payments (id, order_id, provider, status, amount_paise, captured_at, created_at, updated_at)
          SELECT gen_random_uuid(), ${capOrder.id}::uuid, 'CASH'::"PaymentProvider", 'CAPTURED'::"PaymentRecordStatus", 100, ts, ts, ts
          FROM generate_series(${from}::timestamp, ${from}::timestamp + (${count}::int - 1) * interval '1 minute', interval '1 minute') AS ts`;

        await seed(10_000, '2019-01-01 00:00:00');
        const exact = await exportOf({ search: 'LGRCAP1' }).expect(200);
        expect(exact.headers['x-export-rows']).toBe('10000');
        expect(exact.headers['x-export-truncated']).toBe('false');
        expect(rows(exact.text)).toHaveLength(10_001);

        await seed(1, '2019-02-01 00:00:00');
        const over = await exportOf({ search: 'LGRCAP1' }).expect(200);
        expect(over.headers['x-export-rows']).toBe('10000');
        expect(over.headers['x-export-truncated']).toBe('true');
        const lines = rows(over.text);
        expect(lines).toHaveLength(10_001);
        // The newest entries are kept; the single oldest one is what was left out.
        expect(lines[1]).toMatch(/^2019-02-01 05:30:00,/);
        expect(over.text).toContain('2019-01-01 05:31:00,');
        expect(over.text).not.toContain('2019-01-01 05:30:00,');

        // The list still counts all of them, so the admin can warn before downloading.
        const page = await list({ search: 'LGRCAP1', pageSize: 1 }).expect(200);
        expect(page.body.total).toBe(10_001);
        expect(page.body.totals.captured).toEqual({ count: 10_001, amountPaise: 1_000_100 });
      }, 60_000);
    });
  });

  describe('care notes and photos', () => {
    // Each test books into a window of its own, far from the ones other tests fill (a window takes a limited number of pickups).
    let windowDay = 4;
    beforeEach(() => {
      windowDay += 1;
    });
    const STORAGE = 'http://localhost:4999/uploads';
    const customer = bearer(PHONES.customer);
    let customerId: string;
    let otherId: string;
    let driverOrderId: string;
    let driverPhotos: string[];

    const draft = (extra: Record<string, unknown> = {}) => ({
      items: [{ catalogItemId: shirtId, quantity: 1 }],
      pickupDate: addDays(tomorrow, windowDay), pickupSlot: 'NOON', deliveryDate: addDays(tomorrow, windowDay + 2), deliverySlot: 'EVENING',
      pickupAddressId: addressId, paymentMethod: 'COD', ...extra,
    });
    const place = (extra: Record<string, unknown> = {}, key?: string) => {
      const req = http.post('/v1/orders').set(customer);
      return (key ? req.set('Idempotency-Key', key) : req).send(draft(extra));
    };
    // The upload route allows 6 requests a minute, so most photos are recorded directly and only a few go through it.
    let uploadedAt = Date.now();
    const photo = async (userId = customerId): Promise<string> => {
      const key = `care/${userId}/${randomUUID()}.webp`;
      await prisma.orderCarePhoto.create({ data: { userId, key, createdAt: new Date((uploadedAt += 10)) } });
      return `${STORAGE}/${key}`;
    };

    beforeAll(async () => {
      customerId = (await http.get('/v1/me').set(customer).expect(200)).body.id;
      // Signed in by the "hides other customers’ orders" test.
      otherId = (await http.get('/v1/me').set(bearer(PHONES.otherCustomer)).expect(200)).body.id;
    });

    it('takes a care note without photos, trimmed, and keeps it apart from the pickup note', async () => {
      const res = await place({ careNote: '  Stain on the collar of the white shirt  ', instructions: 'Gate code 4410' }).expect(201);
      expect(res.body).toMatchObject({ careNote: 'Stain on the collar of the white shirt', carePhotoUrls: [], instructions: 'Gate code 4410' });
      const stored = await prisma.order.findUniqueOrThrow({ where: { id: res.body.id } });
      expect(stored).toMatchObject({ careNote: 'Stain on the collar of the white shirt', instructions: 'Gate code 4410' });
      expect((await place({ careNote: '   ' }).expect(201)).body).toMatchObject({ careNote: null, carePhotoUrls: [] });
      expect((await place().expect(201)).body).toMatchObject({ careNote: null, carePhotoUrls: [] });
      const long = await place({ careNote: 'a'.repeat(501) }).expect(400);
      expect(long.body.message).toEqual(expect.arrayContaining([expect.stringContaining('careNote')]));
      expect((await place({ careNote: 'a'.repeat(500) }).expect(201)).body.careNote).toHaveLength(500);
    });

    it('accepts a cleaned photo from a customer, refuses files that are not images, and leaves report photos alone', async () => {
      const reportPhotos = await prisma.issuePhoto.count();
      const image = await sharp({ create: { width: 30, height: 20, channels: 3, background: '#654321' } }).png().toBuffer();
      const res = await http.post('/v1/me/uploads/care-photos').set(customer).attach('file', image, 'stain.png').expect(201);
      expect(res.body.url).toContain(`/care/${customerId}/`);
      expect(res.body.url).toMatch(/\.webp$/);
      expect(res.body).toMatchObject({ width: 30, height: 20 });
      const row = await prisma.orderCarePhoto.findFirstOrThrow({ where: { key: res.body.url.split('/uploads/')[1] } });
      expect(row).toMatchObject({ userId: customerId, orderId: null });
      expect(await prisma.issuePhoto.count()).toBe(reportPhotos);

      const fake = await http.post('/v1/me/uploads/care-photos').set(customer).attach('file', Buffer.from('not an image'), 'fake.jpg').expect(400);
      expect(fake.body.code).toBe('INVALID_IMAGE');
      await http.post('/v1/me/uploads/care-photos').attach('file', image, 'stain.png').expect(401);
      await http.post('/v1/me/uploads/care-photos').set(bearer(PHONES.admin)).attach('file', image, 'stain.png').expect(403);
    });

    it('stops at 20 care photos a day for each customer', async () => {
      // Another customer, whose photos nothing else here depends on.
      await prisma.orderCarePhoto.createMany({ data: Array.from({ length: 20 }, (_, i) => ({ userId: otherId, key: `care/${otherId}/cap-${i}.webp` })) });
      const image = await sharp({ create: { width: 10, height: 10, channels: 3, background: '#112233' } }).png().toBuffer();
      const capped = await http.post('/v1/me/uploads/care-photos').set(bearer(PHONES.otherCustomer)).attach('file', image, 'one-more.png').expect(429);
      expect(capped.body.code).toBe('PHOTO_LIMIT');
      expect(await prisma.orderCarePhoto.count({ where: { userId: otherId } })).toBe(20);
      // The first customer is not held back by it.
      await http.post('/v1/me/uploads/care-photos').set(customer).attach('file', image, 'mine.png').expect(201);
      await prisma.orderCarePhoto.deleteMany({ where: { userId: otherId } });
    });

    it('attaches up to 3 of the customer’s own photos to the order, oldest first', async () => {
      const [a, b, c] = [await photo(), await photo(), await photo()];
      const res = await place({ careNote: 'Silk saree: stain on the pallu', carePhotoUrls: [a, b, c] }).expect(201);
      expect(res.body.carePhotoUrls).toEqual([a, b, c]);
      const rows = await prisma.orderCarePhoto.findMany({ where: { orderId: res.body.id } });
      expect(rows).toHaveLength(3);
      expect(rows.every((r) => r.userId === customerId)).toBe(true);
      const mine = await http.get(`/v1/orders/${res.body.id}`).set(customer).expect(200);
      expect(mine.body).toMatchObject({ careNote: 'Silk saree: stain on the pallu', carePhotoUrls: [a, b, c] });
      const listed = await http.get('/v1/orders').set(customer).expect(200);
      expect(listed.body.items.find((o: { id: string }) => o.id === res.body.id).carePhotoUrls).toEqual([a, b, c]);
    });

    it('refuses another customer’s photo, a photo already used, a report photo, a made-up address and more than 3', async () => {
      const before = await prisma.order.count();
      const used = await prisma.orderCarePhoto.findFirstOrThrow({ where: { userId: customerId, orderId: { not: null } } });
      const theirs = await photo(otherId);
      const mine = await photo();
      const refusals = [
        theirs,
        mine.replace(customerId, otherId),
        `${STORAGE}/issues/${customerId}/${randomUUID()}.webp`,
        `${STORAGE}/${used.key}`,
        `${STORAGE}/care/${customerId}/${randomUUID()}.webp`,
        `https://example.com/${mine.split('/uploads/')[1]}`,
      ];
      for (const url of refusals) {
        const res = await place({ careNote: 'x', carePhotoUrls: [url] }).expect(400);
        expect(res.body.code).toBe('INVALID_PHOTO');
      }
      const invalid = expect.arrayContaining([expect.stringContaining('carePhotoUrls')]);
      expect((await place({ carePhotoUrls: [mine, mine] }).expect(400)).body.message).toEqual(invalid);
      const four = [mine, await photo(), await photo(), await photo()];
      expect((await place({ carePhotoUrls: four }).expect(400)).body.message).toEqual(invalid);
      // Nothing was placed, and the customer's photo is still free to use.
      expect(await prisma.order.count()).toBe(before);
      expect((await place({ carePhotoUrls: [mine] }).expect(201)).body.carePhotoUrls).toEqual([mine]);
      // One photo goes to one order: the same URL on a second order is refused.
      expect((await place({ carePhotoUrls: [mine] }).expect(400)).body.code).toBe('INVALID_PHOTO');
    });

    it('does not place two orders when the app retries, and does not replay a retry with a changed note or photos', async () => {
      const [a, b] = [await photo(), await photo()];
      const key = 'care-retry-20261117';
      const first = await place({ careNote: 'Colours may run', carePhotoUrls: [a] }, key).expect(201);
      const replay = await place({ careNote: 'Colours may run', carePhotoUrls: [a] }, key).expect(201);
      expect(replay.body.id).toBe(first.body.id);
      expect(replay.headers['idempotent-replayed']).toBe('true');
      expect(replay.body).toMatchObject({ careNote: 'Colours may run', carePhotoUrls: [a] });
      expect(await prisma.order.count({ where: { customerId, idempotencyKey: key } })).toBe(1);
      expect(await prisma.orderCarePhoto.count({ where: { orderId: first.body.id } })).toBe(1);
      // Spaces around the note are not a different request.
      expect((await place({ careNote: ' Colours may run ', carePhotoUrls: [a] }, key).expect(201)).body.id).toBe(first.body.id);
      const changes = [
        { careNote: 'Wash separately', carePhotoUrls: [a] },
        { careNote: 'Colours may run', carePhotoUrls: [a, b] },
        { careNote: 'Colours may run' },
        { carePhotoUrls: [a] },
        {},
      ];
      for (const changed of changes) {
        const res = await place(changed, key).expect(409);
        expect(res.body.code).toBe('IDEMPOTENCY_KEY_REUSED');
      }
      // Without a care note the request is the one that was sent before care notes existed.
      const plain = await place({}, 'care-retry-plain-1').expect(201);
      expect((await place({}, 'care-retry-plain-1').expect(201)).body.id).toBe(plain.body.id);
      expect((await place({ careNote: '' }, 'care-retry-plain-1').expect(201)).body.id).toBe(plain.body.id);
      expect((await place({ careNote: 'Starch' }, 'care-retry-plain-1').expect(409)).body.code).toBe('IDEMPOTENCY_KEY_REUSED');
    });

    it('shows the note and the photos to the customer, to staff and to the assigned partner only', async () => {
      driverPhotos = [await photo(), await photo()];
      const placed = await place({ careNote: 'Embroidered kurta: handle with care', carePhotoUrls: driverPhotos }).expect(201);
      driverOrderId = placed.body.id;
      const expected = { careNote: 'Embroidered kurta: handle with care', carePhotoUrls: driverPhotos };

      expect((await http.get(`/v1/admin/orders/${driverOrderId}`).set(bearer(PHONES.admin)).expect(200)).body).toMatchObject(expected);
      const adminList = await http.get('/v1/admin/orders').set(bearer(PHONES.admin)).query({ search: placed.body.orderNumber }).expect(200);
      expect(adminList.body.items[0]).toMatchObject(expected);

      // Nobody else sees it: another customer, and a partner who does not hold the order.
      await http.get(`/v1/orders/${driverOrderId}`).set(bearer(PHONES.otherCustomer)).expect(404);
      await http.get(`/v1/driver/orders/${driverOrderId}`).set(bearer(PHONES.driver1)).expect(404);

      await http.post(`/v1/admin/orders/${driverOrderId}/assign`).set(bearer(PHONES.admin)).send({ leg: 'PICKUP', driverId: driver1Id }).expect(200);
      expect((await http.get(`/v1/driver/orders/${driverOrderId}`).set(bearer(PHONES.driver1)).expect(200)).body).toMatchObject(expected);
      const tasks = await http.get('/v1/driver/tasks').set(bearer(PHONES.driver1)).expect(200);
      expect(tasks.body.find((o: { id: string }) => o.id === driverOrderId)).toMatchObject(expected);
      await http.get(`/v1/driver/orders/${driverOrderId}`).set(bearer(PHONES.driver2)).expect(404);
    });

    it('keeps the note and photos when the order is cancelled', async () => {
      const moved = await http.post(`/v1/admin/orders/${driverOrderId}/status`).set(bearer(PHONES.admin)).send({ status: 'CANCELLED', note: 'Test finished' }).expect(200);
      expect(moved.body).toMatchObject({ careNote: 'Embroidered kurta: handle with care', carePhotoUrls: driverPhotos });
      expect((await http.get(`/v1/orders/${driverOrderId}`).set(customer).expect(200)).body.carePhotoUrls).toEqual(driverPhotos);
    });

    it('takes a care note on a phone order, but no photos', async () => {
      const staff = bearer(PHONES.admin);
      const phone = { ...draft({ careNote: '  Delicate silk, please iron on low heat ' }), customerId };
      const res = await http.post('/v1/admin/orders').set(staff).send(phone).expect(201);
      expect(res.body).toMatchObject({ careNote: 'Delicate silk, please iron on low heat', carePhotoUrls: [], source: 'ADMIN' });
      await http.post('/v1/admin/orders').set(staff).send({ ...phone, carePhotoUrls: [await photo()] }).expect(400);
      // The same draft retried with a changed note is not replayed.
      const key = 'staff-care-retry-1';
      const first = await http.post('/v1/admin/orders').set(staff).set('Idempotency-Key', key).send(phone).expect(201);
      expect((await http.post('/v1/admin/orders').set(staff).set('Idempotency-Key', key).send(phone).expect(201)).body.id).toBe(first.body.id);
      const changed = await http.post('/v1/admin/orders').set(staff).set('Idempotency-Key', key).send({ ...phone, careNote: 'Something else' }).expect(409);
      expect(changed.body.code).toBe('IDEMPOTENCY_KEY_REUSED');
    });
  });
});
