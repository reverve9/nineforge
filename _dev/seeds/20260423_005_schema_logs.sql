-- 20260423_005_schema_logs.sql
-- Nine Forge P0: log layer — sync runs and export records.

CREATE TABLE IF NOT EXISTS sync_log (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  source              TEXT        NOT NULL,
  operation           TEXT        NOT NULL,
  started_at          TIMESTAMPTZ NOT NULL,
  finished_at         TIMESTAMPTZ,
  status              TEXT        NOT NULL,
  records_processed   INT         NOT NULL DEFAULT 0,
  errors              JSONB       NOT NULL DEFAULT '[]'::jsonb,
  triggered_by        TEXT
);

CREATE INDEX IF NOT EXISTS idx_sync_log_source_started ON sync_log (source, started_at DESC);

CREATE TABLE IF NOT EXISTS export_log (
  id                UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           TEXT,
  export_type       TEXT        NOT NULL,
  filters           JSONB       NOT NULL,
  delivery_mode     TEXT        NOT NULL,
  storage_path      TEXT,
  file_name         TEXT,
  file_size_bytes   BIGINT,
  status            TEXT        NOT NULL,
  created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
