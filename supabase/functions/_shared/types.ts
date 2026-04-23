// Nine Forge P0 — shared types.
// Covers fetch/transform/sync adapter contracts and common response shapes.

export type SourceCode = "kopis" | "tourapi" | "datalab" | "sbiz";

export type PeriodGranularity =
  | "day"
  | "week"
  | "month"
  | "quarter"
  | "year"
  | "span"
  | "snapshot"
  | "always";

export type SyncOperation = "fetch" | "transform" | "sync" | "ingest-all";

export type SyncStatus = "success" | "partial" | "failed" | "running";

export type TriggeredBy = "cron" | "manual" | "admin_ui";

// ───────────────────────────────────────────────────────────────
// Raw snapshot shape (mirrors raw_api_snapshots row)
// ───────────────────────────────────────────────────────────────
export interface RawSnapshot {
  id: string;
  source: SourceCode;
  endpoint: string;
  request_params: Record<string, unknown>;
  response_body: unknown;
  response_status: number | null;
  fetched_at: string;
  ingested_at: string | null;
  ingest_error: string | null;
}

// ───────────────────────────────────────────────────────────────
// Adapter contract (P1 implements these per source)
// ───────────────────────────────────────────────────────────────
export interface FetchParams {
  // source-specific shape; adapters narrow this.
  [key: string]: unknown;
}

export interface FetchResult {
  snapshot_ids: string[];
  fetched_at: string;
  records_fetched: number;
}

export interface TransformResult {
  snapshot_id: string;
  records_transformed: number;
  errors: Array<{ record_index: number; message: string }>;
}

export interface SyncOptions {
  since?: string;            // ISO timestamp lower bound
  until?: string;            // ISO timestamp upper bound
  region_codes?: string[];   // filter 법정동코드 10-digit
  dry_run?: boolean;
  triggered_by?: TriggeredBy;
}

export interface SyncResult {
  source: SourceCode;
  operation: SyncOperation;
  started_at: string;
  finished_at: string;
  status: SyncStatus;
  records_processed: number;
  errors: Array<{ stage: string; message: string; context?: unknown }>;
  sync_log_id: string;
}

export interface AdapterModule {
  source: SourceCode;
  fetch(params: FetchParams): Promise<FetchResult>;
  transform(snapshot_id: string): Promise<TransformResult>;
  sync(options: SyncOptions): Promise<SyncResult>;
}

// ───────────────────────────────────────────────────────────────
// Edge Function response envelope (§3 Q5)
// ───────────────────────────────────────────────────────────────
export interface ApiError {
  code: string;
  message: string;
  details?: unknown;
}

export interface ApiSuccess<T> {
  ok: true;
  data: T;
  meta?: Record<string, unknown>;
}

export interface ApiFailure {
  ok: false;
  error: ApiError;
}

export type ApiResponse<T> = ApiSuccess<T> | ApiFailure;

// ───────────────────────────────────────────────────────────────
// Export function specific types
// ───────────────────────────────────────────────────────────────
export type DeliveryMode = "storage" | "direct";

export interface ExportRequest {
  export_type: string;
  filters: Record<string, unknown>;
  delivery_mode: DeliveryMode;
  file_name?: string;
}

export interface ExportStorageResult {
  delivery_mode: "storage";
  storage_path: string;
  signed_url: string;
  file_name: string;
  file_size_bytes: number;
}

export interface ExportDirectResult {
  delivery_mode: "direct";
  file_name: string;
  file_size_bytes: number;
  mime_type: string;
  body_base64: string;
}

export type ExportResult = ExportStorageResult | ExportDirectResult;

// ───────────────────────────────────────────────────────────────
// Shared tag classification shapes
// ───────────────────────────────────────────────────────────────
export interface TagResolution {
  resolved: { group_code: string; code: string; display_name: string } | null;
  pending_queued: boolean;
  raw_value: string;
}
