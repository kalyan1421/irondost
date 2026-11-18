import type { Env } from './env.js';

/**
 * Things that are legal to start with but wrong for real customers. Logged at startup, never fatal: a deploy that
 * stops because a key is still a test key would take the whole app down.
 */
export function productionWarnings(env: Pick<Env, 'NODE_ENV' | 'RAZORPAY_KEY_ID' | 'RAZORPAY_KEY_SECRET' | 'RAZORPAY_WEBHOOK_SECRET' | 'FIREBASE_SERVICE_ACCOUNT_BASE64' | 'TRUST_PROXY_HOPS'>): string[] {
  if (env.NODE_ENV !== 'production') return [];
  const warnings: string[] = [];
  if (!env.RAZORPAY_KEY_ID || !env.RAZORPAY_KEY_SECRET) {
    warnings.push('Razorpay keys are not set: online payment is unavailable, only cash orders will work.');
  } else if (env.RAZORPAY_KEY_ID.startsWith('rzp_test_')) {
    warnings.push('Razorpay is using a TEST key (rzp_test_): customers will not be charged real money. Put the live key in before launch.');
  }
  if (!env.RAZORPAY_WEBHOOK_SECRET) {
    warnings.push('RAZORPAY_WEBHOOK_SECRET is not set: refunds stay pending forever and a customer who pays then closes the app is not caught.');
  }
  if (!env.FIREBASE_SERVICE_ACCOUNT_BASE64) {
    warnings.push('FIREBASE_SERVICE_ACCOUNT_BASE64 is not set: sign-in tokens cannot be verified.');
  }
  if (env.TRUST_PROXY_HOPS === 0) {
    warnings.push('TRUST_PROXY_HOPS is 0: behind a load balancer every caller shares one rate limit. Set it to 1 on Render.');
  }
  return warnings;
}
