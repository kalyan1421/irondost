import { createHmac, timingSafeEqual } from 'node:crypto';

function safeEqualHex(expectedHex: string, receivedHex: string): boolean {
  const a = Buffer.from(expectedHex, 'utf8');
  const b = Buffer.from(receivedHex, 'utf8');
  return a.length === b.length && timingSafeEqual(a, b);
}

/** Checkout callback signature: HMAC-SHA256(`order_id|payment_id`, key_secret). */
export function verifyPaymentSignature(
  razorpayOrderId: string,
  razorpayPaymentId: string,
  signature: string,
  keySecret: string,
): boolean {
  const expected = createHmac('sha256', keySecret).update(`${razorpayOrderId}|${razorpayPaymentId}`).digest('hex');
  return safeEqualHex(expected, signature);
}

/** Webhook signature: HMAC-SHA256(raw request body, webhook secret). */
export function verifyWebhookSignature(rawBody: Buffer, signature: string, webhookSecret: string): boolean {
  const expected = createHmac('sha256', webhookSecret).update(rawBody).digest('hex');
  return safeEqualHex(expected, signature);
}
