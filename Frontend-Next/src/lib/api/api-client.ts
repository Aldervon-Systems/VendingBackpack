"use client";

type RequestBody = BodyInit | Record<string, unknown> | Array<unknown> | null | undefined;

type RequestOptions = Omit<RequestInit, "body"> & {
  body?: RequestBody;
};

let accessToken: string | null = null;

function getRuntimeApiBase() {
  const envBase = process.env.NEXT_PUBLIC_API_BASE_URL?.trim();
  if (envBase) {
    return envBase.replace(/\/$/, "");
  }

  return "/api";
}

function normalizePath(path: string) {
  return path.startsWith("/") ? path : `/${path}`;
}

function isBodyInit(value: RequestBody): value is BodyInit {
  return typeof value === "string" || value instanceof Blob || value instanceof FormData || value instanceof URLSearchParams;
}

function serializeBody(body: RequestBody) {
  if (body == null) {
    return undefined;
  }

  if (isBodyInit(body)) {
    return body;
  }

  return JSON.stringify(body);
}

function tryParsePayload(raw: string) {
  if (!raw) {
    return null;
  }

  try {
    return JSON.parse(raw) as unknown;
  } catch {
    return raw;
  }
}

function extractDetail(payload: unknown, fallback: string) {
  if (typeof payload === "string" && payload.trim()) {
    return payload;
  }

  if (typeof payload === "object" && payload !== null) {
    const candidate = payload as Record<string, unknown>;
    if (typeof candidate.detail === "string" && candidate.detail.trim()) {
      return candidate.detail;
    }

    if (typeof candidate.error === "string" && candidate.error.trim()) {
      return candidate.error;
    }
  }

  return fallback;
}

export function setAccessToken(token: string | null) {
  accessToken = token;
}

export function clearAccessToken() {
  accessToken = null;
}

export function getAccessToken() {
  return accessToken;
}

export async function apiRequest<T>(path: string, options?: RequestOptions): Promise<T> {
  const headers = new Headers(options?.headers);
  const normalizedPath = normalizePath(path);
  const body = serializeBody(options?.body);

  if (body !== undefined && !headers.has("Content-Type") && !(body instanceof FormData)) {
    headers.set("Content-Type", "application/json");
  }

  if (accessToken && !headers.has("Authorization")) {
    headers.set("Authorization", `Bearer ${accessToken}`);
  }

  const response = await fetch(`${getRuntimeApiBase()}${normalizedPath}`, {
    ...options,
    headers,
    body,
  });

  const raw = await response.text();
  const payload = tryParsePayload(raw);

  if (!response.ok) {
    throw new Error(extractDetail(payload, `Request failed with status ${response.status}`));
  }

  return payload as T;
}
