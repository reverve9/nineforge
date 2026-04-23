-- 20260423_008_seed_dim_category.sql
-- Nine Forge P0: seed dim_category (6 rows) + dim_tag_group (4 rows).

INSERT INTO dim_category (code, display_name, description, sort_order, is_active) VALUES
  ('tourism',    '관광',        '관광지·방문·숙박 관련 데이터',         10, true),
  ('commerce',   '상권',        '상권·점포·업종·매출 관련 데이터',       20, true),
  ('culture',    '문화예술',    '공연·전시·축제·문화시설 관련 데이터',   30, true),
  ('population', '인구',        '인구·유동인구·인구구조 관련 데이터',     40, true),
  ('economy',    '경제·마케팅', '경제지표·소비·마케팅 관련 데이터',       50, true),
  ('space',      '공간·행정',   '행정구역·공간·지리 관련 데이터',         60, true)
ON CONFLICT (code) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description  = EXCLUDED.description,
  sort_order   = EXCLUDED.sort_order,
  is_active    = EXCLUDED.is_active;

INSERT INTO dim_tag_group (code, display_name, description, is_active) VALUES
  ('type',     '형식',      '대상 엔티티의 최상위 형식 (공연/축제/전시/점포 등)', true),
  ('genre',    '장르·업종', '장르 또는 업종 세부 구분',                            true),
  ('audience', '대상',      '이용자 유형 (유료/무료/방문자/상주 등)',              true),
  ('temporal', '시간성',    '시간 단위 또는 시간적 성격',                          true)
ON CONFLICT (code) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  description  = EXCLUDED.description,
  is_active    = EXCLUDED.is_active;
