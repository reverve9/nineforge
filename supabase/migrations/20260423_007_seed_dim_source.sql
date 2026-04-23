-- 20260423_007_seed_dim_source.sql
-- Nine Forge P0: seed dim_source (4 rows).

INSERT INTO dim_source (code, name, base_url, auth_type, default_granularity, update_frequency, is_active) VALUES
  ('kopis',   'KOPIS 공연예술통합전산망',         'https://www.kopis.or.kr/openApi',   'query_param', 'day',      'daily',     true),
  ('tourapi', '한국관광공사 TourAPI',              'http://apis.data.go.kr/B551011',    'query_param', 'span',     'daily',     true),
  ('datalab', '한국관광데이터랩',                    'http://apis.data.go.kr/B551011',    'query_param', 'month',    'monthly',   true),
  ('sbiz',    '소상공인시장진흥공단 상권정보',       'https://apis.data.go.kr/B553077',   'query_param', 'snapshot', 'quarterly', true)
ON CONFLICT (code) DO UPDATE SET
  name                 = EXCLUDED.name,
  base_url             = EXCLUDED.base_url,
  auth_type            = EXCLUDED.auth_type,
  default_granularity  = EXCLUDED.default_granularity,
  update_frequency     = EXCLUDED.update_frequency,
  is_active            = EXCLUDED.is_active;
