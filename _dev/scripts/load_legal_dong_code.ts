// Nine Forge — legal_dong_code loader.
//
// Loads the MOIS 행정표준코드관리시스템 법정동코드 (`.txt`, tab-separated)
// into `dim_region`. The source file is OPTIONAL — if absent, the loader
// prints a single warning and exits 0 so migrations never block.
//
// File layout (tab-separated, order fixed):
//   법정동코드(10-digit)  \t  법정동명  \t  폐지여부(존재|폐지)
//
// Encoding: the MOIS export is typically EUC-KR. The loader auto-detects
// UTF-8 BOM first; otherwise it decodes as EUC-KR (with `fatal: false`
// so malformed bytes become U+FFFD rather than throwing).
//
// Idempotency: upsert on `code`, so re-running with the same (or newer)
// file is safe and will update deprecation flags in place.
//
// Run:
//   deno run --allow-read --allow-env --allow-net \
//     _dev/scripts/load_legal_dong_code.ts
//
// Env vars required (present when file exists and upsert should run):
//   SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY
// Env var optional:
//   LEGAL_DONG_CODE_PATH  (default: _dev/seeds/legal_dong_code.txt)

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const DEFAULT_PATH = "_dev/seeds/legal_dong_code.txt";
const BATCH_SIZE = 500;

interface Row {
  code: string;
  name: string;
  is_deprecated: boolean;
}

function log(level: "info" | "warn" | "error", message: string, ctx: Record<string, unknown> = {}): void {
  const line = JSON.stringify({
    level,
    message,
    ts: new Date().toISOString(),
    script: "load_legal_dong_code",
    ...ctx,
  });
  if (level === "error") console.error(line);
  else if (level === "warn") console.warn(line);
  else console.log(line);
}

function decodeBytes(bytes: Uint8Array): string {
  // UTF-8 BOM
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf) {
    return new TextDecoder("utf-8").decode(bytes.subarray(3));
  }
  // Heuristic: if valid UTF-8 with Hangul, keep UTF-8. Otherwise decode EUC-KR.
  try {
    const tryUtf8 = new TextDecoder("utf-8", { fatal: true }).decode(bytes);
    if (/[가-힣]/.test(tryUtf8)) return tryUtf8;
  } catch {
    // fall through to EUC-KR
  }
  return new TextDecoder("euc-kr", { fatal: false }).decode(bytes);
}

function parseRows(text: string): { rows: Row[]; skipped: number } {
  const rows: Row[] = [];
  let skipped = 0;
  const lines = text.split(/\r?\n/);

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    if (!line || line.trim().length === 0) continue;

    const parts = line.split("\t");
    if (parts.length < 3) {
      skipped++;
      continue;
    }

    const code = parts[0]?.trim() ?? "";
    const name = parts[1]?.trim() ?? "";
    const statusRaw = parts[2]?.trim() ?? "";

    // skip header row if present
    if (i === 0 && !/^\d{10}$/.test(code)) {
      skipped++;
      continue;
    }

    if (!/^\d{10}$/.test(code)) {
      skipped++;
      continue;
    }
    if (name.length === 0) {
      skipped++;
      continue;
    }

    const is_deprecated = statusRaw === "폐지";

    rows.push({ code, name, is_deprecated });
  }

  return { rows, skipped };
}

async function upsertInBatches(
  client: ReturnType<typeof createClient>,
  rows: Row[],
): Promise<{ inserted: number; errors: number }> {
  let inserted = 0;
  let errors = 0;

  for (let i = 0; i < rows.length; i += BATCH_SIZE) {
    const batch = rows.slice(i, i + BATCH_SIZE);
    const { error, count } = await client
      .from("dim_region")
      .upsert(batch, { onConflict: "code", count: "exact" });

    if (error) {
      errors++;
      log("error", "batch upsert failed", {
        batch_start: i,
        batch_size: batch.length,
        error: error.message,
      });
      continue;
    }

    inserted += count ?? batch.length;
    if ((i / BATCH_SIZE) % 10 === 0) {
      log("info", "batch progress", { processed: i + batch.length, total: rows.length });
    }
  }

  return { inserted, errors };
}

async function main(): Promise<void> {
  const path = Deno.env.get("LEGAL_DONG_CODE_PATH") ?? DEFAULT_PATH;

  let bytes: Uint8Array;
  try {
    bytes = await Deno.readFile(path);
  } catch (err) {
    if (err instanceof Deno.errors.NotFound) {
      log("warn", "legal_dong_code.txt not found, dim_region left empty", { path });
      return; // exit 0 — non-blocking
    }
    throw err;
  }

  const text = decodeBytes(bytes);
  const { rows, skipped } = parseRows(text);

  log("info", "parsed legal dong code file", {
    path,
    bytes: bytes.length,
    rows: rows.length,
    skipped,
  });

  if (rows.length === 0) {
    log("warn", "no valid rows parsed, skipping upsert");
    return;
  }

  const url = Deno.env.get("SUPABASE_URL");
  const key = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!url || !key) {
    log("error", "missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY env vars");
    Deno.exit(1);
  }

  const client = createClient(url, key, {
    auth: { persistSession: false, autoRefreshToken: false },
  });

  const active = rows.filter((r) => !r.is_deprecated).length;
  const deprecated = rows.length - active;
  const sidoCodes = Array.from(new Set(rows.map((r) => r.code.substring(0, 2)))).sort();

  log("info", "starting upsert", { total: rows.length, active, deprecated, sido_codes: sidoCodes });

  const { inserted, errors } = await upsertInBatches(client, rows);

  log("info", "upsert complete", { inserted, errors, total: rows.length });

  if (errors > 0) Deno.exit(2);
}

if (import.meta.main) {
  await main();
}
