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
4. 실행: `fvm flutter run --dart-define-from-file=config/dev.json`

## 환경변수 (config/*.json)
환경별 설정은 `config/local.json` · `config/dev.json` · `config/prod.json` 에 모아두고
`--dart-define-from-file` 로 한 번에 주입한다. (미지정 시 `lib/app/env.dart` 기본값 = **dev**)

| 키 | 설명 |
|---|---|
| `APP_ENV` | 환경 식별자 (local \| dev \| prod) |
| `API_BASE` | Desk 백엔드 base URL (dio 가 뒤에 `/api/v1` 부착) |
| `SSO_URL` | SSO **프론트**(React 로그인 페이지) base URL — SSO 백엔드 아님 |

```sh
fvm flutter run                  --dart-define-from-file=config/local.json   # 로컬 도커
fvm flutter run                  --dart-define-from-file=config/dev.json      # dev (기본)
fvm flutter build apk --release  --dart-define-from-file=config/dev.json
fvm flutter build apk --release  --dart-define-from-file=config/prod.json     # prod (config/prod.json 주소 먼저 채울 것)
```

- **로컬 도커**(`config/local.json`)는 `http://localhost:8002`. 단 실기기는 localhost=폰 자신이라 못 닿으니
  PC LAN IP(예: `http://192.168.0.x:8002`), Android 에뮬레이터는 `http://10.0.2.2:8002` 로 바꿔 쓴다.
- **dev**: `https://desk-dev.porest.cloud:10443` / SSO `https://sso-dev.porest.cloud:10443`.
- **prod**: `config/prod.json` 의 `REPLACE-WITH-PROD-*` 를 실주소로 교체해야 동작(미교체 시 의도적으로 실패).

## 백엔드 의존
- [porest-desk-back](https://github.com/lshdainty/porest-desk-back) — REST API
- [porest-sso-back](https://github.com/lshdainty/porest-sso-back) — SSO 인증
