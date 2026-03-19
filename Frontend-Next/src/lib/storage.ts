type StoredEnvelope<T> = {
  version: 1;
  expiresAt: number | null;
  value: T;
};

type ReadOptions<T> = {
  validate?: (value: unknown) => value is T;
};

type WriteOptions = {
  ttlMs?: number;
};

function getStorage() {
  if (typeof window === "undefined") {
    return null;
  }

  return window.sessionStorage;
}

export function getStoredValue<T>(key: string, options?: ReadOptions<T>): T | null {
  const storage = getStorage();
  if (!storage) {
    return null;
  }

  const raw = storage.getItem(key);
  if (!raw) {
    return null;
  }

  try {
    const parsed = JSON.parse(raw) as StoredEnvelope<unknown>;
    const hasEnvelope = typeof parsed === "object" && parsed !== null && "value" in parsed && "expiresAt" in parsed;

    if (!hasEnvelope) {
      storage.removeItem(key);
      return null;
    }

    if (typeof parsed.expiresAt === "number" && parsed.expiresAt <= Date.now()) {
      storage.removeItem(key);
      return null;
    }

    if (options?.validate && !options.validate(parsed.value)) {
      storage.removeItem(key);
      return null;
    }

    return parsed.value as T;
  } catch {
    storage.removeItem(key);
    return null;
  }
}

export function setStoredValue<T>(key: string, value: T, options?: WriteOptions) {
  const storage = getStorage();
  if (!storage) {
    return;
  }

  const envelope: StoredEnvelope<T> = {
    version: 1,
    expiresAt: typeof options?.ttlMs === "number" ? Date.now() + options.ttlMs : null,
    value,
  };

  storage.setItem(key, JSON.stringify(envelope));
}

export function removeStoredValue(key: string) {
  const storage = getStorage();
  if (!storage) {
    return;
  }

  storage.removeItem(key);
}