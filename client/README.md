# Nine Forge — macOS Client

Flutter desktop 앱 (macOS 15 Sequoia 전용). 이 저장소의 [백엔드](../supabase/) 와 연동되는 내부용 공공데이터 큐레이션 워크벤치 UI.

현 단계는 **P0-Client 초기화** — 실제 업무 UI 는 포함되어 있지 않고, Supabase 연결이 정상인지를 확인하는 **헬스체크 배너** 한 개만 표시한다. 실 UI 는 P2 에서 붙인다.

---

## 빠른 시작

```bash
cd client
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run -d macos --dart-define-from-file=.env.dart-define.json
```

- 첫 실행 전 `.env.dart-define.json` 생성이 필수. 미생성 상태로 실행하면 앱은 "환경변수가 주입되지 않았습니다" 안내 화면을 띄우고 Supabase 초기화를 건너뛴다.
- Riverpod `@riverpod` 어노테이션이 붙은 파일을 수정하면 `build_runner` 재실행 필요.

## 환경변수 설정

번들 리소스에 평문 키가 포함되지 않도록 `.env` 파일 번들링은 금지. 대신 `--dart-define-from-file` 로 빌드 시 주입한다.

1. `client/.env.dart-define.json` 을 아래 형식으로 직접 생성 (`.gitignore` 에 걸려 있어 커밋되지 않음):
   ```json
   {
     "SUPABASE_URL": "https://<project-ref>.supabase.co",
     "SUPABASE_ANON_KEY": "eyJhbGciOiJIUzI1NiI..."
   }
   ```
2. 값은 Supabase Dashboard → **Project Settings → API** 에서 복사.
3. `service_role` 키는 사용하지 않는다 (클라이언트에서 절대 사용 금지).

## 배포 빌드 파이프라인

Shell script 기반. `client/scripts/` 아래에 구성되어 있고, 사용자가 직접 실행한다 (Claude Code 는 스크립트를 실행하지 않는다).

| 스크립트 | 역할 |
|----------|------|
| `scripts/build.sh` | `flutter clean` → `pub get` → `build_runner` → `flutter build macos --release` |
| `scripts/sign.sh` | Developer ID 로 `.app` 서명 (hardened runtime + entitlements) |
| `scripts/notarize.sh` | Apple notary 제출 + wait + staple |
| `scripts/dmg.sh` | `create-dmg` 또는 `hdiutil` 로 DMG 생성 |
| `scripts/release.sh` | 위 4개 순차 실행 (one-shot) |
| `scripts/entitlements/release.entitlements` | hardened runtime 용 entitlements |

### 필요 환경변수 (사용자가 `~/.zshrc` 등에 등록)

| 변수 | 용도 |
|------|------|
| `NINEFORGE_APPLE_ID` | Apple 개발자 계정 이메일 |
| `NINEFORGE_APP_SPECIFIC_PASSWORD` | [appleid.apple.com](https://appleid.apple.com) 에서 발급한 앱 암호 |
| `NINEFORGE_TEAM_ID` | Apple Developer Team ID (10자리) |
| `NINEFORGE_SIGN_IDENTITY` | `Developer ID Application: Your Name (TEAMID)` 문자열 (`security find-identity -v -p codesigning` 으로 확인) |

### create-dmg 설치 (선택)

```bash
brew install create-dmg
```

미설치 시 `dmg.sh` 는 자동으로 `hdiutil` 로 폴백한다.

### 실행 예

```bash
cd client
scripts/release.sh
# 최종 산출물: dist/NineForge-<version>.dmg
```

## 프로젝트 구조

```
client/
├── lib/
│   ├── main.dart                           # 엔트리포인트 (env 검증 → Supabase init → runApp)
│   ├── app.dart                            # MacosApp.router + EnvMissingApp
│   ├── core/
│   │   ├── env.dart                        # --dart-define 값 래퍼
│   │   ├── supabase_client.dart            # Supabase.initialize + client getter
│   │   └── providers/
│   │       └── supabase_provider.dart      # Provider<SupabaseClient>
│   ├── routing/
│   │   └── router.dart                     # GoRouter (현재 '/' 단일 라우트)
│   └── features/
│       └── home/
│           ├── home_page.dart              # MacosWindow + 헬스체크 배너
│           └── providers/
│               └── healthcheck_provider.dart
├── macos/                                  # 네이티브 macOS 쉘 (15.0 deployment target)
├── scripts/                                # 배포 파이프라인
├── test/                                   # P2 에서 실 테스트 추가
├── pubspec.yaml
└── README.md
```

`lib/` 는 feature-first 로 확장 예정. `widgets/common/`, `models/`, `services/` 같은 범용 폴더는 P2 에서 필요해질 때 추가.

## 다음 단계

- **P2 UI 구현**: 사이드바 · 데이터셋 목록 · 쿼리 편집기 · 차트 · 지도 · 내보내기 UX (별도 핸드오프)
- **아이콘/브랜드 리소스**: 런칭 직전 P3 이후 대응

현 페이즈는 골격과 파이프라인만. 실 기능은 후속 페이즈에서 붙인다.
