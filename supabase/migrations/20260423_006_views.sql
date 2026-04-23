-- 20260423_006_views.sql
-- Nine Forge P0: enriched views + monthly materialized views (skeleton only).
-- Actual data loads happen in P1; refresh function is a stub for now.

-- ──────────────────────────────────────────────────────────────
-- view_events_enriched
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW view_events_enriched AS
SELECT
  e.id,
  e.source,
  e.source_id,
  e.event_type,
  e.name,
  e.period_start,
  e.period_end,
  e.period_granularity,
  e.categories,
  e.tags,
  e.metadata,
  e.fetched_at,
  e.ingested_at,
  v.id            AS venue_id,
  v.name          AS venue_name,
  v.venue_type    AS venue_type,
  v.address       AS venue_address,
  v.location      AS venue_location,
  r.region_code,
  r.region_name,
  r.sido_code,
  r.sido_name,
  r.sigungu_code,
  r.sigungu_name,
  r.level         AS region_level
FROM fact_event e
LEFT JOIN dim_venue  v ON v.id         = e.venue_id
LEFT JOIN dim_region r ON r.region_code = COALESCE(e.region_code, v.region_code);

-- ──────────────────────────────────────────────────────────────
-- view_metrics_enriched
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW view_metrics_enriched AS
SELECT
  m.id,
  m.source,
  m.source_id,
  m.metric_key,
  m.metric_value,
  m.metric_unit,
  m.period_start,
  m.period_end,
  m.period_granularity,
  m.categories,
  m.tags,
  m.metadata,
  m.fetched_at,
  m.ingested_at,
  r.region_code,
  r.region_name,
  r.sido_code,
  r.sido_name,
  r.sigungu_code,
  r.sigungu_name,
  r.level         AS region_level,
  v.id            AS venue_id,
  v.name          AS venue_name,
  v.venue_type    AS venue_type
FROM fact_metric m
LEFT JOIN dim_region r ON r.region_code = m.region_code
LEFT JOIN dim_venue  v ON v.id         = m.venue_id;

-- ──────────────────────────────────────────────────────────────
-- view_venues_enriched
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE VIEW view_venues_enriched AS
SELECT
  v.id,
  v.source,
  v.source_id,
  v.venue_type,
  v.name,
  v.address,
  v.location,
  v.categories,
  v.tags,
  v.metadata,
  v.created_at,
  v.updated_at,
  r.region_code,
  r.region_name,
  r.sido_code,
  r.sido_name,
  r.sigungu_code,
  r.sigungu_name,
  r.level         AS region_level
FROM dim_venue v
LEFT JOIN dim_region r ON r.region_code = v.region_code;

-- ──────────────────────────────────────────────────────────────
-- mv_monthly_tourism  (datalab-sourced monthly metrics)
-- ──────────────────────────────────────────────────────────────
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_tourism AS
SELECT
  region_code,
  date_trunc('month', period_start)::date AS month,
  metric_key,
  metric_unit,
  SUM(metric_value) AS total_value,
  AVG(metric_value) AS avg_value,
  COUNT(*)          AS record_count
FROM fact_metric
WHERE source = 'datalab'
GROUP BY region_code, date_trunc('month', period_start), metric_key, metric_unit;

CREATE INDEX IF NOT EXISTS idx_mv_monthly_tourism_region_month
  ON mv_monthly_tourism (region_code, month);

-- ──────────────────────────────────────────────────────────────
-- mv_monthly_culture  (KOPIS-sourced monthly event counts)
-- ──────────────────────────────────────────────────────────────
CREATE MATERIALIZED VIEW IF NOT EXISTS mv_monthly_culture AS
SELECT
  region_code,
  date_trunc('month', period_start)::date AS month,
  event_type,
  COUNT(*) AS event_count
FROM fact_event
WHERE source = 'kopis'
GROUP BY region_code, date_trunc('month', period_start), event_type;

CREATE INDEX IF NOT EXISTS idx_mv_monthly_culture_region_month
  ON mv_monthly_culture (region_code, month);

-- ──────────────────────────────────────────────────────────────
-- refresh_monthly_stats() — stub, wired up by pg_cron in P1.
-- ──────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION refresh_monthly_stats()
RETURNS void
LANGUAGE plpgsql
AS $$
BEGIN
  REFRESH MATERIALIZED VIEW mv_monthly_tourism;
  REFRESH MATERIALIZED VIEW mv_monthly_culture;
END;
$$;

COMMENT ON FUNCTION refresh_monthly_stats() IS
  'P0 stub: rebuilds monthly MVs. Hook up via pg_cron in P1 once adapters populate fact tables.';
