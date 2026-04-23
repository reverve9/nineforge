# Nine Forge

공공데이터 큐레이션 워크벤치 — 관광·상권·문화예술·인구·경제·공간 6대 카테고리의 공공데이터를 조합·추출하는 내부 도구.

## 구조

- `supabase/migrations/` — Postgres 스키마·시드 마이그레이션 (실행 순서는 파일명 타임스탬프 기준)
- `supabase/functions/_shared/` — Edge Function 공통 유틸 (Deno TypeScript)

## 현재 단계

**P0 — 백엔드 기초 설계** (이 브랜치)

- Supabase 프로젝트: postgis · pg_cron · pgcrypto 활성화
- 3계층 스키마 (raw / dim / fact) + 로그 2 테이블 + 뷰 3 + MV 2
- 마스터 데이터 초기 적재 (source 4 · category 6 · tag_group 4 · tag 31 · region 35 · region_map 4)
- `_shared/` 공통 TS 유틸 7종

다음 단계(P0-Client, P1)는 별도 브랜치/프롬프트로 진행.

## 마이그레이션 실행

Supabase CLI 사용 시:
```bash
supabase link --project-ref <ref>
supabase db push
```

SQL Editor 수동 입력 시 `_dev/seeds/README.md`의 실행 순서 가이드 참조.
