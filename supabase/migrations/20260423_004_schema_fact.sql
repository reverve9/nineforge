-- 20260423_004_schema_fact.sql
-- Nine Forge P0: fact layer — event (time-bound) and metric (measurement).

-- ──────────────────────────────────────────────────────────────
-- fact_event  (공연 / 축제 / 전시 / etc.)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fact_event (
  id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  source                TEXT          NOT NULL,
  source_id             TEXT          NOT NULL,
  event_type            TEXT          NOT NULL,
  name                  TEXT          NOT NULL,
  venue_id              UUID          REFERENCES dim_venue(id) ON DELETE SET NULL,
  region_code           TEXT          REFERENCES dim_region(region_code) ON UPDATE CASCADE ON DELETE SET NULL,
  period_start          DATE          NOT NULL,
  period_end            DATE          NOT NULL,
  period_granularity    TEXT          NOT NULL,
  categories            TEXT[]        NOT NULL DEFAULT '{}',
  tags                  TEXT[]        NOT NULL DEFAULT '{}',
  metadata              JSONB         NOT NULL DEFAULT '{}'::jsonb,
  raw_snapshot_id       UUID          REFERENCES raw_api_snapshots(id) ON DELETE SET NULL,
  fetched_at            TIMESTAMPTZ   NOT NULL,
  ingested_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
  UNIQUE (source, source_id)
);

CREATE INDEX IF NOT EXISTS idx_fact_event_region_period ON fact_event (region_code, period_start);
CREATE INDEX IF NOT EXISTS idx_fact_event_venue         ON fact_event (venue_id);
CREATE INDEX IF NOT EXISTS idx_fact_event_type          ON fact_event (event_type);
CREATE INDEX IF NOT EXISTS idx_fact_event_categories    ON fact_event USING GIN (categories);
CREATE INDEX IF NOT EXISTS idx_fact_event_tags          ON fact_event USING GIN (tags);

-- ──────────────────────────────────────────────────────────────
-- fact_metric  (통계 지표 — 방문·소비·상권 등)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS fact_metric (
  id                    UUID          PRIMARY KEY DEFAULT gen_random_uuid(),
  source                TEXT          NOT NULL,
  source_id             TEXT,
  region_code           TEXT          REFERENCES dim_region(region_code) ON UPDATE CASCADE ON DELETE SET NULL,
  venue_id              UUID          REFERENCES dim_venue(id) ON DELETE SET NULL,
  metric_key            TEXT          NOT NULL,
  metric_value          NUMERIC,
  metric_unit           TEXT,
  period_start          DATE          NOT NULL,
  period_end            DATE          NOT NULL,
  period_granularity    TEXT          NOT NULL,
  categories            TEXT[]        NOT NULL DEFAULT '{}',
  tags                  TEXT[]        NOT NULL DEFAULT '{}',
  metadata              JSONB         NOT NULL DEFAULT '{}'::jsonb,
  raw_snapshot_id       UUID          REFERENCES raw_api_snapshots(id) ON DELETE SET NULL,
  fetched_at            TIMESTAMPTZ   NOT NULL,
  ingested_at           TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_fact_metric_region_key_period ON fact_metric (region_code, metric_key, period_start);
CREATE INDEX IF NOT EXISTS idx_fact_metric_venue             ON fact_metric (venue_id);
CREATE INDEX IF NOT EXISTS idx_fact_metric_categories        ON fact_metric USING GIN (categories);
CREATE INDEX IF NOT EXISTS idx_fact_metric_tags              ON fact_metric USING GIN (tags);
