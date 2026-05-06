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
- `API_BASE` — Desk 백엔드 (Spring Boot) base URL — 기본 `http://localhost:8002`
- `SSO_URL` — SSO **프론트** (React 로그인 페이지) base URL — 기본 `http://localhost:3000`
  - SSO 백엔드 API(:8000) 아님. WebView 가 띄우는 건 ID/PW 폼 페이지다.

Android 에뮬레이터는 `localhost` 대신 `10.0.2.2` 사용:
```sh
fvm flutter run \
  --dart-define=API_BASE=http://10.0.2.2:8002 \
  --dart-define=SSO_URL=http://10.0.2.2:3000
```

## 백엔드 의존
- [porest-desk-back](https://github.com/lshdainty/porest-desk-back) — REST API
- [porest-sso-back](https://github.com/lshdainty/porest-sso-back) — SSO 인증
