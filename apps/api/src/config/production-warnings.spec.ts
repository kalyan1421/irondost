import { productionWarnings } from './production-warnings.js';

const ok = {
  NODE_ENV: 'production' as const,
  RAZORPAY_KEY_ID: 'rzp_live_abc',
  RAZORPAY_KEY_SECRET: 'secret',
  RAZORPAY_WEBHOOK_SECRET: 'whsec',
  FIREBASE_SERVICE_ACCOUNT_BASE64: 'e30=',
  TRUST_PROXY_HOPS: 1,
};

describe('productionWarnings', () => {
  it('is quiet when everything is set for production', () => {
    expect(productionWarnings(ok)).toEqual([]);
  });

  it('is always quiet outside production', () => {
    expect(productionWarnings({ ...ok, NODE_ENV: 'development', RAZORPAY_KEY_ID: '', TRUST_PROXY_HOPS: 0 })).toEqual([]);
  });

  it('flags a Razorpay test key', () => {
    const w = productionWarnings({ ...ok, RAZORPAY_KEY_ID: 'rzp_test_abc' });
    expect(w).toHaveLength(1);
    expect(w[0]).toContain('TEST key');
  });

  it('flags missing Razorpay keys, webhook secret, Firebase credentials and proxy hops', () => {
    const w = productionWarnings({
      ...ok,
      RAZORPAY_KEY_ID: '',
      RAZORPAY_WEBHOOK_SECRET: '',
      FIREBASE_SERVICE_ACCOUNT_BASE64: '',
      TRUST_PROXY_HOPS: 0,
    });
    expect(w.map((x) => x.split(':')[0])).toEqual([
      'Razorpay keys are not set',
      'RAZORPAY_WEBHOOK_SECRET is not set',
      'FIREBASE_SERVICE_ACCOUNT_BASE64 is not set',
      'TRUST_PROXY_HOPS is 0',
    ]);
  });
});
