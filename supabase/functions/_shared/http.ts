// Nine Forge P0 — HTTP helper with timeout + exponential-backoff retry (R5).
// Adapters in P1 call fetchJson()/fetchText() from here; direct fetch is
// discouraged so retry/timeout policy stays uniform.

export interface FetchOptions extends RequestInit {
  timeoutMs?: number;       // default 15_000
  retries?: number;         // default 3 (per R5)
  retryOnStatus?: number[]; // default [408, 429, 500, 502, 503, 504]
  backoffMs?: number;       // initial backoff; doubled each retry. default 500
}

const DEFAULT_TIMEOUT_MS = 15_000;
const DEFAULT_RETRIES = 3;
const DEFAULT_RETRY_STATUS = [408, 429, 500, 502, 503, 504];
const DEFAULT_BACKOFF_MS = 500;

export class HttpError extends Error {
  constructor(
    message: string,
    public readonly status: number,
    public readonly url: string,
    public readonly body?: string,
  ) {
    super(message);
    this.name = "HttpError";
  }
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export async function fetchWithRetry(
  url: string,
  options: FetchOptions = {},
): Promise<Response> {
  const {
    timeoutMs = DEFAULT_TIMEOUT_MS,
    retries = DEFAULT_RETRIES,
    retryOnStatus = DEFAULT_RETRY_STATUS,
    backoffMs = DEFAULT_BACKOFF_MS,
    ...init
  } = options;

  let attempt = 0;
  let lastError: unknown;

  while (attempt <= retries) {
    const controller = new AbortController();
    const timer = setTimeout(() => controller.abort(), timeoutMs);

    try {
      const res = await fetch(url, { ...init, signal: controller.signal });
      clearTimeout(timer);

      if (res.ok) return res;

      if (retryOnStatus.includes(res.status) && attempt < retries) {
        attempt++;
        await sleep(backoffMs * 2 ** (attempt - 1));
        continue;
      }

      const body = await res.text().catch(() => undefined);
      throw new HttpError(
        `HTTP ${res.status} ${res.statusText} — ${url}`,
        res.status,
        url,
        body,
      );
    } catch (err) {
      clearTimeout(timer);
      lastError = err;
      if (err instanceof HttpError) throw err;
      if (attempt >= retries) break;
      attempt++;
      await sleep(backoffMs * 2 ** (attempt - 1));
    }
  }

  throw lastError instanceof Error
    ? lastError
    : new Error(`fetchWithRetry exhausted retries: ${url}`);
}

export async function fetchJson<T = unknown>(
  url: string,
  options: FetchOptions = {},
): Promise<T> {
  const res = await fetchWithRetry(url, {
    ...options,
    headers: { Accept: "application/json", ...(options.headers ?? {}) },
  });
  return (await res.json()) as T;
}

export async function fetchText(
  url: string,
  options: FetchOptions = {},
): Promise<string> {
  const res = await fetchWithRetry(url, options);
  return await res.text();
}
