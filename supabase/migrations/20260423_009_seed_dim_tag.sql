-- 20260423_009_seed_dim_tag.sql
-- Nine Forge P0: seed dim_tag (30+ rows across 4 groups).

INSERT INTO dim_tag (group_code, code, display_name, synonyms) VALUES
  -- type (6)
  ('type',     'performance',      '공연',       ARRAY['공연예술']),
  ('type',     'festival',         '축제',       ARRAY['페스티벌']),
  ('type',     'exhibition',       '전시',       ARRAY['전시회']),
  ('type',     'shop',             '점포',       ARRAY['상가','매장']),
  ('type',     'tourist_spot',     '관광지',     ARRAY[]::TEXT[]),
  ('type',     'statistic',        '통계',       ARRAY['지표']),
  -- genre (10)
  ('genre',    'musical',          '뮤지컬',     ARRAY['뮤지컬공연']),
  ('genre',    'concert',          '콘서트',     ARRAY['공연','음악회']),
  ('genre',    'classical',        '클래식',     ARRAY['클래식음악']),
  ('genre',    'gugak',            '국악',       ARRAY['전통음악']),
  ('genre',    'dance',            '무용',       ARRAY['춤']),
  ('genre',    'theater',          '연극',       ARRAY['연극공연']),
  ('genre',    'restaurant',       '음식점',     ARRAY['식당']),
  ('genre',    'cafe',             '카페',       ARRAY['커피숍','카페테리아']),
  ('genre',    'accommodation',    '숙박',       ARRAY['숙박업','호텔','펜션']),
  ('genre',    'retail',           '소매',       ARRAY['소매업']),
  -- audience (6)
  ('audience', 'paid',             '유료관객',   ARRAY[]::TEXT[]),
  ('audience', 'free',             '무료',       ARRAY[]::TEXT[]),
  ('audience', 'external_visitor', '외부방문자', ARRAY['관광객']),
  ('audience', 'resident',         '상주인구',   ARRAY['주민']),
  ('audience', 'all_ages',         '전연령',     ARRAY[]::TEXT[]),
  ('audience', 'family',           '가족',       ARRAY[]::TEXT[]),
  -- temporal (9)
  ('temporal', 'daily',            '일단위',     ARRAY[]::TEXT[]),
  ('temporal', 'weekly',           '주단위',     ARRAY[]::TEXT[]),
  ('temporal', 'monthly',          '월단위',     ARRAY[]::TEXT[]),
  ('temporal', 'quarterly',        '분기단위',   ARRAY[]::TEXT[]),
  ('temporal', 'yearly',           '연단위',     ARRAY[]::TEXT[]),
  ('temporal', 'seasonal',         '계절성',     ARRAY[]::TEXT[]),
  ('temporal', 'always',           '상시',       ARRAY[]::TEXT[]),
  ('temporal', 'span',             '기간제',     ARRAY[]::TEXT[]),
  ('temporal', 'snapshot',         '스냅샷',     ARRAY['시점지표'])
ON CONFLICT (group_code, code) DO UPDATE SET
  display_name = EXCLUDED.display_name,
  synonyms     = EXCLUDED.synonyms;
