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
-- dim_region  (법정동코드 10-digit master — MOIS 행정표준코드 기준)
-- Loader: _dev/scripts/load_legal_dong_code.ts (file optional; table
-- stays empty if source file is absent).
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_region (
  code           TEXT                          PRIMARY KEY,
  name           TEXT                          NOT NULL,
  is_deprecated  BOOLEAN                       NOT NULL DEFAULT false,
  sido_code      TEXT GENERATED ALWAYS AS (substring(code, 1, 2)) STORED,
  sgg_code       TEXT GENERATED ALWAYS AS (substring(code, 1, 5)) STORED,
  umd_code       TEXT GENERATED ALWAYS AS (substring(code, 1, 8)) STORED,
  bbox           GEOMETRY(Polygon, 4326),
  centroid       GEOGRAPHY(Point, 4326),
  ingested_at    TIMESTAMPTZ                   NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_dim_region_sido          ON dim_region (sido_code);
CREATE INDEX IF NOT EXISTS idx_dim_region_sgg           ON dim_region (sgg_code);
CREATE INDEX IF NOT EXISTS idx_dim_region_umd           ON dim_region (umd_code);
CREATE INDEX IF NOT EXISTS idx_dim_region_is_deprecated ON dim_region (is_deprecated);
CREATE INDEX IF NOT EXISTS idx_dim_region_centroid      ON dim_region USING GIST (centroid);
CREATE INDEX IF NOT EXISTS idx_dim_region_bbox          ON dim_region USING GIST (bbox);

-- ──────────────────────────────────────────────────────────────
-- dim_region_code_map  (source-specific region codes → 법정동)
-- P0 leaves this empty; P1 adapters populate on first sync.
-- ──────────────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS dim_region_code_map (
  source            TEXT        NOT NULL,
  source_code       TEXT        NOT NULL,
  legal_dong_code   TEXT        NOT NULL REFERENCES dim_region(code) ON UPDATE CASCADE ON DELETE RESTRICT,
  matched_level     TEXT        NOT NULL CHECK (matched_level IN ('sido', 'sgg', 'umd')),
  notes             TEXT,
  ingested_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  PRIMARY KEY (source, source_code)
);

CREATE INDEX IF NOT EXISTS idx_dim_region_code_map_legal_dong ON dim_region_code_map (legal_dong_code);

COMMENT ON TABLE dim_region_code_map IS
  '소스별 지역코드 → 법정동코드 매핑. P1 각 어댑터 첫 sync 시 동적 생성.
레퍼런스:
- tourapi: KorService2/areaCode2 엔드포인트 (apis.data.go.kr/B551011/KorService2)
- datalab: 한국관광데이터랩 지역코드 체계 (TourAPI 와 사실상 동일 가정, P1 어댑터에서 검증)
- kopis: 공연예술통합전산망 개발가이드 PDF 부록의 지역코드표 (한글 문자열)
- sbiz: 법정동코드 그대로 사용. 본 매핑 테이블 미경유';

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
  region_code       TEXT                        REFERENCES dim_region(code) ON UPDATE CASCADE ON DELETE SET NULL,
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
