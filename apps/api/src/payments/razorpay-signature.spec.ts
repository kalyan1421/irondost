import { createHmac } from 'node:crypto';
import { verifyPaymentSignature, verifyWebhookSignature } from './razorpay-signature.js';

describe('Razorpay signatures', () => {
  const secret = 'test_secret';

  it('verifies the checkout signature over order_id|payment_id', () => {
    const sig = createHmac('sha256', secret).update('order_ABC|pay_XYZ').digest('hex');
    expect(verifyPaymentSignature('order_ABC', 'pay_XYZ', sig, secret)).toBe(true);
    expect(verifyPaymentSignature('order_ABC', 'pay_OTHER', sig, secret)).toBe(false);
    expect(verifyPaymentSignature('order_ABC', 'pay_XYZ', sig, 'wrong_secret')).toBe(false);
    expect(verifyPaymentSignature('order_ABC', 'pay_XYZ', 'short', secret)).toBe(false);
  });

  it('verifies the webhook signature over the raw body', () => {
    const body = Buffer.from('{"event":"payment.captured"}');
    const sig = createHmac('sha256', secret).update(body).digest('hex');
    expect(verifyWebhookSignature(body, sig, secret)).toBe(true);
    expect(verifyWebhookSignature(Buffer.from('{"event":"payment.failed"}'), sig, secret)).toBe(false);
  });
});
