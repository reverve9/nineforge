-- 20260423_010_seed_dim_region.sql
-- Nine Forge P0: seed dim_region.
--
-- SCOPE NOTE (P0 partial seed — see §5 handoff report):
--   · 17 sido rows + 18 Gangwon-do sigungu rows are seeded here.
--   · Full nationwide eup/myeon/dong rows (~46,000) require the MOIS
--     (행정안전부) 법정동코드 CSV, which is not yet bundled in the repo.
--     Load that CSV via a follow-up migration once the file is provided.
--   · 강원특별자치도 승격 (2023-06-11): 법정동코드의 시도코드 '42'는
--     명칭만 변경되고 숫자 코드는 유지 중으로 확인됨. `sido_name`은
--     '강원특별자치도'로 적재한다. (행정안전부 공식 데이터와 재검증
--     필요 → §5 handoff report 항목 6)

-- ──────────────────────────────────────────────────────────────
-- Sido (17)
-- ──────────────────────────────────────────────────────────────
INSERT INTO dim_region (region_code, region_name, sido_code, sido_name, level, parent_code) VALUES
  ('1100000000', '서울특별시',           '11', '서울특별시',           'sido', NULL),
  ('2600000000', '부산광역시',           '26', '부산광역시',           'sido', NULL),
  ('2700000000', '대구광역시',           '27', '대구광역시',           'sido', NULL),
  ('2800000000', '인천광역시',           '28', '인천광역시',           'sido', NULL),
  ('2900000000', '광주광역시',           '29', '광주광역시',           'sido', NULL),
  ('3000000000', '대전광역시',           '30', '대전광역시',           'sido', NULL),
  ('3100000000', '울산광역시',           '31', '울산광역시',           'sido', NULL),
  ('3600000000', '세종특별자치시',       '36', '세종특별자치시',       'sido', NULL),
  ('4100000000', '경기도',               '41', '경기도',               'sido', NULL),
  ('4200000000', '강원특별자치도',       '42', '강원특별자치도',       'sido', NULL),
  ('4300000000', '충청북도',             '43', '충청북도',             'sido', NULL),
  ('4400000000', '충청남도',             '44', '충청남도',             'sido', NULL),
  ('4500000000', '전북특별자치도',       '45', '전북특별자치도',       'sido', NULL),
  ('4600000000', '전라남도',             '46', '전라남도',             'sido', NULL),
  ('4700000000', '경상북도',             '47', '경상북도',             'sido', NULL),
  ('4800000000', '경상남도',             '48', '경상남도',             'sido', NULL),
  ('5000000000', '제주특별자치도',       '50', '제주특별자치도',       'sido', NULL)
ON CONFLICT (region_code) DO UPDATE SET
  region_name = EXCLUDED.region_name,
  sido_code   = EXCLUDED.sido_code,
  sido_name   = EXCLUDED.sido_name,
  level       = EXCLUDED.level,
  parent_code = EXCLUDED.parent_code;

-- ──────────────────────────────────────────────────────────────
-- Gangwon-do sigungu (18)  — 강원특별자치도 하위 7시 11군
-- ──────────────────────────────────────────────────────────────
INSERT INTO dim_region (region_code, region_name, sido_code, sido_name, sigungu_code, sigungu_name, level, parent_code) VALUES
  ('4211000000', '춘천시', '42', '강원특별자치도', '42110', '춘천시', 'sigungu', '4200000000'),
  ('4213000000', '원주시', '42', '강원특별자치도', '42130', '원주시', 'sigungu', '4200000000'),
  ('4215000000', '강릉시', '42', '강원특별자치도', '42150', '강릉시', 'sigungu', '4200000000'),
  ('4217000000', '동해시', '42', '강원특별자치도', '42170', '동해시', 'sigungu', '4200000000'),
  ('4219000000', '태백시', '42', '강원특별자치도', '42190', '태백시', 'sigungu', '4200000000'),
  ('4221000000', '속초시', '42', '강원특별자치도', '42210', '속초시', 'sigungu', '4200000000'),
  ('4223000000', '삼척시', '42', '강원특별자치도', '42230', '삼척시', 'sigungu', '4200000000'),
  ('4272000000', '홍천군', '42', '강원특별자치도', '42720', '홍천군', 'sigungu', '4200000000'),
  ('4273000000', '횡성군', '42', '강원특별자치도', '42730', '횡성군', 'sigungu', '4200000000'),
  ('4275000000', '영월군', '42', '강원특별자치도', '42750', '영월군', 'sigungu', '4200000000'),
  ('4276000000', '평창군', '42', '강원특별자치도', '42760', '평창군', 'sigungu', '4200000000'),
  ('4277000000', '정선군', '42', '강원특별자치도', '42770', '정선군', 'sigungu', '4200000000'),
  ('4278000000', '철원군', '42', '강원특별자치도', '42780', '철원군', 'sigungu', '4200000000'),
  ('4279000000', '화천군', '42', '강원특별자치도', '42790', '화천군', 'sigungu', '4200000000'),
  ('4280000000', '양구군', '42', '강원특별자치도', '42800', '양구군', 'sigungu', '4200000000'),
  ('4281000000', '인제군', '42', '강원특별자치도', '42810', '인제군', 'sigungu', '4200000000'),
  ('4282000000', '고성군', '42', '강원특별자치도', '42820', '고성군', 'sigungu', '4200000000'),
  ('4283000000', '양양군', '42', '강원특별자치도', '42830', '양양군', 'sigungu', '4200000000')
ON CONFLICT (region_code) DO UPDATE SET
  region_name  = EXCLUDED.region_name,
  sido_code    = EXCLUDED.sido_code,
  sido_name    = EXCLUDED.sido_name,
  sigungu_code = EXCLUDED.sigungu_code,
  sigungu_name = EXCLUDED.sigungu_name,
  level        = EXCLUDED.level,
  parent_code  = EXCLUDED.parent_code;
