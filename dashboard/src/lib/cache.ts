export class TTLCache<V> {
  private store = new Map<string, { value: V; expiresAt: number }>();
  private defaultTtlMs: number;

  constructor(defaultTtlMs: number = 5000) {
    this.defaultTtlMs = defaultTtlMs;
  }

  get(key: string): V | undefined {
    const entry = this.store.get(key);
    if (!entry) return undefined;
    if (Date.now() > entry.expiresAt) {
      this.store.delete(key);
      return undefined;
    }
    return entry.value;
  }

  set(key: string, value: V, ttlMs?: number): void {
    this.store.set(key, { value, expiresAt: Date.now() + (ttlMs ?? this.defaultTtlMs) });
  }

  getOrSet(key: string, factory: () => V | Promise<V>, ttlMs?: number): V | Promise<V> {
    const cached = this.get(key);
    if (cached !== undefined) return cached;
    const value = factory();
    if (value instanceof Promise) {
      return value.then((v) => {
        this.set(key, v, ttlMs);
        return v;
      });
    }
    this.set(key, value, ttlMs);
    return value;
  }

  clear(): void {
    this.store.clear();
  }

  size(): number {
    return this.store.size;
  }
}

let cacheInstance: TTLCache<unknown> | null = null;

export function getCache(): TTLCache<unknown> {
  if (!cacheInstance) {
    const ttl = Number(process.env.CACHE_TTL_MS ?? 5000);
    cacheInstance = new TTLCache<unknown>(ttl);
  }
  return cacheInstance;
}