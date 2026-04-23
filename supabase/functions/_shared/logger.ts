// Nine Forge P0 — structured logger + sync_log bridge.
// Adapters wrap a sync run with `withSyncLog()` so every sync gets a
// single audit row (sync_log) plus structured stdout logs.

import type { SupabaseClient } from "./supabase-client.ts";
import type {
  SourceCode,
  SyncOperation,
  SyncStatus,
  TriggeredBy,
} from "./types.ts";

type LogLevel = "debug" | "info" | "warn" | "error";

function emit(level: LogLevel, message: string, context: Record<string, unknown> = {}): void {
  const line = JSON.stringify({
    level,
    message,
    ts: new Date().toISOString(),
    ...context,
  });
  if (level === "error") console.error(line);
  else if (level === "warn") console.warn(line);
  else console.log(line);
}

export const log = {
  debug: (msg: string, ctx?: Record<string, unknown>) => emit("debug", msg, ctx),
  info:  (msg: string, ctx?: Record<string, unknown>) => emit("info",  msg, ctx),
  warn:  (msg: string, ctx?: Record<string, unknown>) => emit("warn",  msg, ctx),
  error: (msg: string, ctx?: Record<string, unknown>) => emit("error", msg, ctx),
};

export interface SyncLogHandle {
  id: string;
  append_error(stage: string, message: string, details?: unknown): void;
  increment(count: number): void;
}

export interface WithSyncLogOptions {
  source: SourceCode;
  operation: SyncOperation;
  triggered_by?: TriggeredBy;
}

export async function withSyncLog<T>(
  client: SupabaseClient,
  options: WithSyncLogOptions,
  work: (handle: SyncLogHandle) => Promise<T>,
): Promise<{ result: T; sync_log_id: string; status: SyncStatus }> {
  const started_at = new Date().toISOString();

  const { data: inserted, error: insertErr } = await client
    .from("sync_log")
    .insert({
      source: options.source,
      operation: options.operation,
      started_at,
      status: "running",
      triggered_by: options.triggered_by ?? "manual",
    })
    .select("id")
    .single();

  if (insertErr || !inserted) {
    log.error("sync_log insert failed", { error: insertErr?.message });
    throw insertErr ?? new Error("sync_log insert returned no row");
  }

  const sync_log_id: string = inserted.id;
  const errors: Array<{ stage: string; message: string; details?: unknown }> = [];
  let records_processed = 0;

  const handle: SyncLogHandle = {
    id: sync_log_id,
    append_error(stage, message, details) {
      errors.push({ stage, message, details });
    },
    increment(count) {
      records_processed += count;
    },
  };

  let status: SyncStatus = "success";
  let result: T;

  try {
    result = await work(handle);
    if (errors.length > 0) status = "partial";
  } catch (err) {
    status = "failed";
    errors.push({
      stage: "uncaught",
      message: err instanceof Error ? err.message : String(err),
    });
    await finalize(client, sync_log_id, status, records_processed, errors);
    throw err;
  }

  await finalize(client, sync_log_id, status, records_processed, errors);
  return { result, sync_log_id, status };
}

async function finalize(
  client: SupabaseClient,
  id: string,
  status: SyncStatus,
  records_processed: number,
  errors: unknown[],
): Promise<void> {
  const { error } = await client
    .from("sync_log")
    .update({
      status,
      records_processed,
      errors,
      finished_at: new Date().toISOString(),
    })
    .eq("id", id);

  if (error) {
    log.error("sync_log finalize failed", { id, error: error.message });
  }
}
