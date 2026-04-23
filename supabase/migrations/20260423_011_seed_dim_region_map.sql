-- 20260423_011_seed_dim_region_map.sql
-- Nine Forge P0: seed dim_region_code_map for Gangneung (강릉시).
--
-- SCOPE NOTE (§5 handoff item):
--   · KOPIS uses Korean sido/sigungu name strings → text mapping.
--   · TourAPI / DataLab share the same 한국관광공사 code system.
--     The areaCode (sido) / sigunguCode (sigungu) pairs here are
--     based on the published TourAPI_4 spec. Verify against live
--     API responses in P1 before relying on them.

INSERT INTO dim_region_code_map (region_code, source, external_code, external_name, notes) VALUES
  -- KOPIS (문자열 매칭 — 구 '강원도' 표기도 병행 등록)
  ('4215000000', 'kopis',   '강원특별자치도|강릉시', '강원특별자치도 강릉시', '승격 후 표기'),
  ('4215000000', 'kopis',   '강원도|강릉시',         '강원도 강릉시',         '승격 전 레거시 표기 호환용'),

  -- TourAPI (areaCode=32, sigunguCode=1 for 강릉시 — 공식 스펙 기준, P1에서 재검증)
  ('4215000000', 'tourapi', '32|1',                  '강원도 강릉시',         'areaCode=32, sigunguCode=1'),

  -- DataLab (한국관광데이터랩, TourAPI와 동일 코드 체계 사용)
  ('4215000000', 'datalab', '32|1',                  '강원도 강릉시',         'TourAPI와 동일 코드 체계')
ON CONFLICT (source, external_code) DO UPDATE SET
  region_code   = EXCLUDED.region_code,
  external_name = EXCLUDED.external_name,
  notes         = EXCLUDED.notes;
