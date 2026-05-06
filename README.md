# porest-desk-app

Porest Desk 모바일 앱 (Flutter, iOS + Android).

## 기술 스택
- Flutter (FVM stable 핀, 현재 3.41.x)
- Dart 3.11.x
- Riverpod 3.0 / go_router / dio + cookie_jar / freezed / fl_chart / table_calendar / wolt_modal_sheet

## 개발 환경 셋업
1. FVM 설치: `brew tap leoafarias/fvm && brew install fvm`
2. Flutter SDK 설치: `fvm install` (`.fvmrc`에 핀된 stable 채널 자동 사용)
3. 의존성 받기: `fvm flutter pub get`
4. 실행: `fvm flutter run --dart-define=API_BASE=http://localhost:8002 --dart-define=SSO_URL=http://localhost:8000`

## 환경변수
- `API_BASE` — Desk 백엔드 base URL (기본 local: `http://localhost:8002`)
- `SSO_URL` — SSO 백엔드 base URL (기본 local: `http://localhost:8000`)

## 백엔드 의존
- [porest-desk-back](https://github.com/lshdainty/porest-desk-back) — REST API
- [porest-sso-back](https://github.com/lshdainty/porest-sso-back) — SSO 인증
