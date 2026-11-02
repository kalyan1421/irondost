import { parseEnv } from './env.js';

describe('DATABASE_POOL_MAX', () => {
  const base = { DATABASE_URL: 'postgresql://x' };

  it('defaults to 10 and reads a number from the environment', () => {
    expect(parseEnv(base).DATABASE_POOL_MAX).toBe(10);
    expect(parseEnv({ ...base, DATABASE_POOL_MAX: '5' }).DATABASE_POOL_MAX).toBe(5);
  });

  it('rejects a pool that cannot hold a connection', () => {
    expect(() => parseEnv({ ...base, DATABASE_POOL_MAX: '0' })).toThrow(/DATABASE_POOL_MAX/);
  });
});

describe('TRUST_PROXY_HOPS', () => {
  const base = { DATABASE_URL: 'postgresql://x' };

  it('trusts no proxy unless told to, and reads the number of hops', () => {
    expect(parseEnv(base).TRUST_PROXY_HOPS).toBe(0);
    expect(parseEnv({ ...base, TRUST_PROXY_HOPS: '1' }).TRUST_PROXY_HOPS).toBe(1);
  });

  it('rejects a negative or silly number of hops', () => {
    expect(() => parseEnv({ ...base, TRUST_PROXY_HOPS: '-1' })).toThrow(/TRUST_PROXY_HOPS/);
    expect(() => parseEnv({ ...base, TRUST_PROXY_HOPS: '50' })).toThrow(/TRUST_PROXY_HOPS/);
  });
});
