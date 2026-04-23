# Nine Forge P0 — SQL Editor 실행 가이드

Supabase Dashboard → SQL Editor 에서 **아래 순서대로** 파일을 열어 전체 내용을 복사·붙여넣고 `RUN` 한다. 각 파일은 `IF NOT EXISTS` / `ON CONFLICT ... DO UPDATE` 로 멱등(idempotent)하므로 재실행해도 안전하다.

## 실행 순서

| # | 파일 | 목적 | 예상 결과 |
|---|------|------|-----------|
| 1 | `20260423_001_extensions.sql`        | postgis · pg_cron · pgcrypto 활성화 | 3 extension enabled |
| 2 | `20260423_002_schema_raw.sql`        | `raw_api_snapshots` 테이블          | 1 table + 2 index |
| 3 | `20260423_003_schema_dim.sql`        | dim 계층 8 테이블 (dim_region 신규 스키마 포함) | 8 table + 인덱스 다수 |
| 4 | `20260423_004_schema_fact.sql`       | fact 계층 2 테이블                    | 2 table + 인덱스 다수 |
| 5 | `20260423_005_schema_logs.sql`       | 로그 2 테이블                          | 2 table |
| 6 | `20260423_006_views.sql`             | 뷰 3개 + MV 2개 + `refresh_monthly_stats()` 스텁 | 뷰 3 · MV 2 · func 1 |
| 7 | `20260423_007_seed_dim_source.sql`   | `dim_source` 4건                     | INSERT 4 / UPSERT 4 |
| 8 | `20260423_008_seed_dim_category.sql` | `dim_category` 6건 + `dim_tag_group` 4건 | INSERT 6 + 4 |
| 9 | `20260423_009_seed_dim_tag.sql`      | `dim_tag` 31건                       | INSERT 31 |

> `dim_region` 은 SQL Editor 로 적재하지 않는다. 행정표준코드 `.txt` 파일 배치 후 아래 **법정동코드 적재** 섹션 참조.
> `dim_region_code_map` 은 P0 에서는 빈 테이블로 둔다. P1 각 어댑터가 첫 sync 시 동적 생성.

## 법정동코드 적재 (선택적, 파일 도착 후)

1. MOIS 행정표준코드관리시스템(`https://www.code.go.kr/stdcode/regCodeL.do`) 에서 법정동코드 전체 조회 → `.txt` 다운로드 → ZIP 해제.
2. 내부 단일 파일을 **`_dev/seeds/legal_dong_code.txt`** 로 배치. 인코딩은 EUC-KR 그대로 두어도 로더가 자동 변환한다.
3. 환경변수 설정 후 Deno 로더 실행:
   ```bash
   export SUPABASE_URL="https://<ref>.supabase.co"
   export SUPABASE_SERVICE_ROLE_KEY="<service_role_key>"   # anon 키 아님
   deno run --allow-read --allow-env --allow-net \
     _dev/scripts/load_legal_dong_code.ts
   ```
4. 파일이 없어도 로더는 경고 로그 1회 후 정상 종료(exit 0). 마이그레이션을 블로킹하지 않는다.
5. 폐지 건도 `is_deprecated=true` 로 함께 적재된다.

## 실행 후 검증 쿼리

```sql
-- 1) 테이블 목록
SELECT table_name FROM information_schema.tables
WHERE table_schema = 'public' ORDER BY table_name;

-- 2) 확장 모듈 설치 상태
SELECT extname, extversion FROM pg_extension
WHERE extname IN ('postgis','pg_cron','pgcrypto');

-- 3) 마스터 데이터 카운트
SELECT 'dim_source'           AS tbl, COUNT(*) FROM dim_source
UNION ALL SELECT 'dim_category',          COUNT(*) FROM dim_category
UNION ALL SELECT 'dim_tag_group',         COUNT(*) FROM dim_tag_group
UNION ALL SELECT 'dim_tag',               COUNT(*) FROM dim_tag
UNION ALL SELECT 'dim_region (total)',    COUNT(*) FROM dim_region
UNION ALL SELECT 'dim_region (active)',   COUNT(*) FROM dim_region WHERE is_deprecated = false
UNION ALL SELECT 'dim_region_code_map',   COUNT(*) FROM dim_region_code_map;

-- 4) 뷰/MV 존재 확인
SELECT table_name, table_type FROM information_schema.tables
WHERE table_schema = 'public' AND table_type = 'VIEW';
SELECT matviewname FROM pg_matviews WHERE schemaname = 'public';

-- 5) dim_region 최신본 판정 (파일 적재 후에만 유효)
SELECT DISTINCT sido_code FROM dim_region ORDER BY sido_code;
-- 결과에 '51' (강원특별자치도), '52' (전북특별자치도) 가 포함되면 최신본.
```

## 알려진 TODO

1. **TourAPI/DataLab areaCode·sigunguCode** — P1 어댑터 첫 sync 때 실측값으로 `dim_region_code_map` 채움.
2. **`dim_region.bbox` / `centroid`** — NULL 상태. 공간 쿼리(§3 Q6 쿼리 B) 실행 전 좌표 보강 필요.
3. **Storage 버킷 `exports` (private)** — SQL Editor 로는 생성 불가. Supabase Dashboard → Storage 에서 수동 생성.
