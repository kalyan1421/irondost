// Fills a LOCAL development API with demo partners, customers and orders by calling
// the API itself (so pricing, numbering and dispatch rules all apply).
// Needs AUTH_DEV_BYPASS=true on the API and the seed's super admin.
//
//   pnpm --filter @laundry/api demo     (API must be running on API_URL)

const API = process.env.API_URL ?? 'http://localhost:4000';
const ADMIN = process.env.SEED_SUPER_ADMIN_PHONE?.replace(/^\+91/, '') ?? '9000000000';

async function call(phone, method, path, body) {
  const res = await fetch(`${API}/v1${path}`, {
    method,
    headers: { Authorization: `Bearer dev:${phone}`, 'content-type': 'application/json' },
    body: body ? JSON.stringify(body) : undefined,
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) throw new Error(`${method} ${path} → ${res.status} ${data?.code ?? ''} ${data?.message ?? ''}`);
  return data;
}

const istDate = (offsetDays) => {
  const d = new Date(Date.now() + 330 * 60_000 + offsetDays * 86_400_000);
  return d.toISOString().slice(0, 10);
};

const PARTNERS = [
  { phone: '9810000001', name: 'Ravi Kumar', vehicleNumber: 'TS09EA1234', lat: 17.4126, lng: 78.4482 },
  { phone: '9810000002', name: 'Suresh Reddy', vehicleNumber: 'TS07FB5678', lat: 17.4401, lng: 78.3489 },
  { phone: '9810000003', name: 'Imran Khan', vehicleNumber: 'TS10GC9012', lat: 17.385, lng: 78.4867 },
];

const CUSTOMERS = [
  { phone: '9900000001', name: 'Priya Sharma', area: 'Banjara Hills', street: 'Road No. 12', lat: 17.4126, lng: 78.4482 },
  { phone: '9900000002', name: 'Arjun Mehta', area: 'Gachibowli', street: 'DLF Cyber City Road', lat: 17.4401, lng: 78.3489 },
  { phone: '9900000003', name: 'Lakshmi Iyer', area: 'Jubilee Hills', street: 'Road No. 36', lat: 17.4325, lng: 78.4071 },
  { phone: '9900000004', name: 'Farhan Ali', area: 'Kondapur', street: 'Botanical Garden Road', lat: 17.4615, lng: 78.3636 },
];

async function main() {
  await call(ADMIN, 'POST', '/auth/session', { app: 'ADMIN' });
  const existing = await call(ADMIN, 'GET', '/admin/drivers');
  const catalog = await call(ADMIN, 'GET', '/catalog');
  const items = catalog.flatMap((c) => c.items);
  if (items.length < 3) throw new Error('Run the seed first (pnpm db:seed) so there is a catalogue');

  const partnerIds = [];
  for (const p of PARTNERS) {
    let d = existing.find((e) => e.phone === `+91${p.phone}`);
    if (!d) d = await call(ADMIN, 'POST', '/admin/drivers', { phone: p.phone, name: p.name, vehicleNumber: p.vehicleNumber });
    await call(p.phone, 'POST', '/auth/session', { app: 'PARTNER' });
    await call(p.phone, 'PUT', '/driver/online', { isOnline: true });
    await call(p.phone, 'PUT', '/driver/location', { latitude: p.lat, longitude: p.lng });
    partnerIds.push(d.id);
  }

  const orders = [];
  for (const [i, c] of CUSTOMERS.entries()) {
    await call(c.phone, 'POST', '/auth/session', { app: 'CUSTOMER' });
    await call(c.phone, 'PATCH', '/me', { name: c.name });
    let addresses = await call(c.phone, 'GET', '/me/addresses');
    if (addresses.length === 0) {
      await call(c.phone, 'POST', '/me/addresses', {
        houseNo: `Flat ${101 + i * 100}`,
        building: 'Sai Residency',
        street: c.street,
        area: c.area,
        city: 'Hyderabad',
        state: 'Telangana',
        pincode: '500034',
        latitude: c.lat,
        longitude: c.lng,
      });
      addresses = await call(c.phone, 'GET', '/me/addresses');
    }
    for (let n = 0; n < 2; n++) {
      const order = await call(c.phone, 'POST', '/orders', {
        items: [
          { catalogItemId: items[(i + n) % items.length].id, quantity: 3 + i },
          { catalogItemId: items[(i + n + 1) % items.length].id, quantity: 1 + n },
        ],
        pickupDate: istDate(1 + n),
        pickupSlot: ['MORNING', 'NOON', 'EVENING'][(i + n) % 3],
        deliveryDate: istDate(3 + n),
        deliverySlot: 'EVENING',
        pickupAddressId: addresses[0].id,
        paymentMethod: n === 0 ? 'COD' : 'ONLINE',
        instructions: n === 0 ? 'Please ring the bell twice' : undefined,
      });
      orders.push(order);
    }
  }

  // Move a few orders along so the board has something in every column.
  const [a, b, c, d] = orders;
  await call(ADMIN, 'POST', `/admin/orders/${a.id}/assign`, { leg: 'PICKUP', driverId: partnerIds[0] });
  await call(ADMIN, 'POST', `/admin/orders/${b.id}/assign`, { leg: 'PICKUP', driverId: partnerIds[1] });
  await call(PARTNERS[1].phone, 'POST', `/driver/orders/${b.id}/picked-up`);
  await call(ADMIN, 'POST', `/admin/orders/${b.id}/status`, { status: 'PROCESSING' });
  await call(ADMIN, 'POST', `/admin/orders/${c.id}/assign`, { leg: 'PICKUP', driverId: partnerIds[2] });
  await call(PARTNERS[2].phone, 'POST', `/driver/orders/${c.id}/picked-up`);
  await call(ADMIN, 'POST', `/admin/orders/${c.id}/status`, { status: 'PROCESSING' });
  await call(ADMIN, 'POST', `/admin/orders/${c.id}/status`, { status: 'READY_FOR_DELIVERY' });
  await call(ADMIN, 'POST', `/admin/orders/${c.id}/assign`, { leg: 'DELIVERY', driverId: partnerIds[2] });
  await call(PARTNERS[2].phone, 'POST', `/driver/orders/${c.id}/out-for-delivery`);
  await call(PARTNERS[2].phone, 'POST', `/driver/orders/${c.id}/delivered`, { collectedCash: true });
  await call(CUSTOMERS[1].phone, 'POST', `/orders/${d.id}/cancel`, { reason: 'Travelling this week' });

  console.log(`Demo data ready: ${PARTNERS.length} partners, ${CUSTOMERS.length} customers, ${orders.length} orders.`);
}

main().catch((err) => {
  console.error(err.message);
  process.exitCode = 1;
});
