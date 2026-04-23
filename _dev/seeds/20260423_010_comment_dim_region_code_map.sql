-- P0 delta §2-4: dim_region_code_map 테이블 주석
-- 소스별 지역코드 → 법정동코드 매핑의 레퍼런스를 박아
-- P1 각 어댑터 작성자가 바로 참조할 수 있도록 함

COMMENT ON TABLE dim_region_code_map IS
'소스별 지역코드 → 법정동코드 매핑. P1 각 어댑터 첫 sync 시 동적 생성.
레퍼런스:
- tourapi: KorService2/areaCode2 엔드포인트 (apis.data.go.kr/B551011/KorService2). 법정동코드조회 API 우선 사용 검토 가능 (areaCode 대체).
- datalab: 한국관광데이터랩 지역코드 체계 (TourAPI 와 사실상 동일 가정, P1 어댑터에서 검증).
- kopis: 공연예술통합전산망 개발가이드 PDF 부록의 지역코드표 (한글 문자열).
- sbiz: 법정동코드 그대로 사용. 본 매핑 테이블 미경유.';
