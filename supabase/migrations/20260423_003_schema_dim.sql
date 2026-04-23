-- 20260423_003_schema_dim.sql
-- Nine Forge P0: dim layer — controlled vocabularies, regions, venues.

-- ──────────────────────────────────────────────────────────────
-- dim_source
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_source (
  code                  TEXT        PRIMARY KEY,
  name                  TEXT        NOT NULL,
  base_url              TEXT,
  auth_type             TEXT,
  default_granularity   TEXT,
  update_frequency      TEXT,
  is_active             BOOLEAN     NOT NULL DEFAULT true,
  last_synced_at        TIMESTAMPTZ,
  notes                 TEXT
);

-- ──────────────────────────────────────────────────────────────
-- dim_category
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_category (
  code          TEXT        PRIMARY KEY,
  display_name  TEXT        NOT NULL,
  description   TEXT,
  is_active     BOOLEAN     NOT NULL DEFAULT true,
  sort_order    INT         NOT NULL DEFAULT 0,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ──────────────────────────────────────────────────────────────
-- dim_tag_group
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_tag_group (
  code          TEXT        PRIMARY KEY,
  display_name  TEXT        NOT NULL,
  description   TEXT,
  is_active     BOOLEAN     NOT NULL DEFAULT true
);

-- ──────────────────────────────────────────────────────────────
-- dim_tag
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_tag (
  id            UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  group_code    TEXT        NOT NULL REFERENCES dim_tag_group(code) ON UPDATE CASCADE ON DELETE RESTRICT,
  code          TEXT        NOT NULL,
  display_name  TEXT        NOT NULL,
  synonyms      TEXT[]      NOT NULL DEFAULT '{}',
  is_active     BOOLEAN     NOT NULL DEFAULT true,
  created_by    TEXT,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (group_code, code)
);

CREATE INDEX IF NOT EXISTS idx_dim_tag_group_code ON dim_tag (group_code);

-- ──────────────────────────────────────────────────────────────
-- dim_tag_pending  (auto-queue for unknown tag strings)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_tag_pending (
  id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
  raw_value           TEXT        NOT NULL,
  seen_in_source      TEXT        NOT NULL,
  first_seen_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  seen_count          INT         NOT NULL DEFAULT 1,
  suggested_group     TEXT,
  suggested_mapping   TEXT,
  status              TEXT        NOT NULL DEFAULT 'pending',
  reviewed_by         TEXT,
  reviewed_at         TIMESTAMPTZ,
  UNIQUE (raw_value, seen_in_source)
);

CREATE INDEX IF NOT EXISTS idx_dim_tag_pending_status ON dim_tag_pending (status);

-- ──────────────────────────────────────────────────────────────
-- dim_region  (법정동코드 10-digit master)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_region (
  region_code         TEXT                          PRIMARY KEY,
  region_name         TEXT                          NOT NULL,
  sido_code           TEXT,
  sido_name           TEXT,
  sigungu_code        TEXT,
  sigungu_name        TEXT,
  eupmyeondong_code   TEXT,
  eupmyeondong_name   TEXT,
  level               TEXT,
  parent_code         TEXT                          REFERENCES dim_region(region_code) ON UPDATE CASCADE ON DELETE SET NULL,
  bbox                GEOMETRY(Polygon, 4326),
  centroid            GEOGRAPHY(Point, 4326)
);

CREATE INDEX IF NOT EXISTS idx_dim_region_sido      ON dim_region (sido_code);
CREATE INDEX IF NOT EXISTS idx_dim_region_sigungu   ON dim_region (sigungu_code);
CREATE INDEX IF NOT EXISTS idx_dim_region_parent    ON dim_region (parent_code);
CREATE INDEX IF NOT EXISTS idx_dim_region_centroid  ON dim_region USING GIST (centroid);
CREATE INDEX IF NOT EXISTS idx_dim_region_bbox      ON dim_region USING GIST (bbox);

-- ──────────────────────────────────────────────────────────────
-- dim_region_code_map  (source-specific region codes → 법정동)
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_region_code_map (
  id              UUID  PRIMARY KEY DEFAULT gen_random_uuid(),
  region_code     TEXT  NOT NULL REFERENCES dim_region(region_code) ON UPDATE CASCADE ON DELETE RESTRICT,
  source          TEXT  NOT NULL,
  external_code   TEXT  NOT NULL,
  external_name   TEXT,
  notes           TEXT,
  UNIQUE (source, external_code)
);

CREATE INDEX IF NOT EXISTS idx_dim_region_code_map_region ON dim_region_code_map (region_code);

-- ──────────────────────────────────────────────────────────────
-- dim_venue
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_venue (
  id                UUID                        PRIMARY KEY DEFAULT gen_random_uuid(),
  source            TEXT                        NOT NULL,
  source_id         TEXT                        NOT NULL,
  venue_type        TEXT                        NOT NULL,
  name              TEXT                        NOT NULL,
  address           TEXT,
  region_code       TEXT                        REFERENCES dim_region(region_code) ON UPDATE CASCADE ON DELETE SET NULL,
  location          GEOGRAPHY(Point, 4326),
  categories        TEXT[]                      NOT NULL DEFAULT '{}',
  tags              TEXT[]                      NOT NULL DEFAULT '{}',
  metadata          JSONB                       NOT NULL DEFAULT '{}'::jsonb,
  raw_snapshot_id   UUID                        REFERENCES raw_api_snapshots(id) ON DELETE SET NULL,
  created_at        TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
  updated_at        TIMESTAMPTZ                 NOT NULL DEFAULT NOW(),
  UNIQUE (source, source_id)
);

CREATE INDEX IF NOT EXISTS idx_dim_venue_region     ON dim_venue (region_code);
CREATE INDEX IF NOT EXISTS idx_dim_venue_type       ON dim_venue (venue_type);
CREATE INDEX IF NOT EXISTS idx_dim_venue_location   ON dim_venue USING GIST (location);
CREATE INDEX IF NOT EXISTS idx_dim_venue_categories ON dim_venue USING GIN (categories);
CREATE INDEX IF NOT EXISTS idx_dim_venue_tags       ON dim_venue USING GIN (tags);
