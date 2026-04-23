-- 20260423_002_schema_raw.sql
-- Nine Forge P0: raw layer — untouched API snapshots.

CREATE TABLE IF NOT EXISTS raw_api_snapshots (
  id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  source           TEXT        NOT NULL,
  endpoint         TEXT        NOT NULL,
  request_params   JSONB       NOT NULL DEFAULT '{}'::jsonb,
  response_body    JSONB,
  response_status  INT,
  fetched_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  ingested_at      TIMESTAMPTZ,
  ingest_error     TEXT
);

CREATE INDEX IF NOT EXISTS idx_raw_api_snapshots_source_endpoint_fetched_at
  ON raw_api_snapshots (source, endpoint, fetched_at DESC);

CREATE INDEX IF NOT EXISTS idx_raw_api_snapshots_pending_ingest
  ON raw_api_snapshots (ingested_at)
  WHERE ingested_at IS NULL;

COMMENT ON TABLE  raw_api_snapshots       IS 'R1: store raw API payloads untouched before any transform.';
COMMENT ON COLUMN raw_api_snapshots.source IS 'kopis / tourapi / sbiz / datalab';
