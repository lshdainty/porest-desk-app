/// 빌드/실행 시 `--dart-define-from-file=config/<env>.json` 으로 주입되는 환경변수.
///
/// 환경별 설정 파일: `config/local.json` · `config/dev.json` · `config/prod.json`
///   fvm flutter run                       --dart-define-from-file=config/dev.json
///   fvm flutter build apk --release       --dart-define-from-file=config/prod.json
///
/// 미지정 시 기본값 = **dev** (실기기에서 localhost 를 부르지 않도록 안전한 dev 서버).
/// localhost 는 로컬 도커용이라 `config/local.json` 에서만 사용한다.
abstract final class Env {
  /// 현재 환경 식별자 (local | dev | prod).
  static const String appEnv = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  /// Desk 백엔드 base URL (dio 가 뒤에 `/api/v1` 부착). 기본 = dev 게이트웨이.
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://desk-dev.porest.cloud:10443',
  );

  /// SSO **프론트** URL (React 로그인 페이지, WebView 가 띄우는 ID/PW 폼). 기본 = dev.
  /// SSO 백엔드가 아님.
  static const String ssoUrl = String.fromEnvironment(
    'SSO_URL',
    defaultValue: 'https://sso-dev.porest.cloud:10443',
  );

  /// desk-front (React 웹) URL — 차트 WebView 가 띄우는 임베드 페이지(`/embed/stocks/:symbol`)의 origin.
  /// dev/prod 는 nginx 가 백엔드와 동일 호스트에서 SPA 도 서빙하므로 [apiBase] 와 동일.
  /// 로컬은 vite dev 가 별도 포트(`:3002`)에서 SPA 만 띄운다.
  static const String webBaseUrl = String.fromEnvironment(
    'WEB_BASE_URL',
    defaultValue: 'https://desk-dev.porest.cloud:10443',
  );

  /// SSO 로그인 후 캐치할 모바일 전용 redirect_uri.
  /// SSO DB의 client_redirect_uris 에 동일 값으로 등록되어 있어야 한다.
  static const String authCallbackScheme = 'porestdesk';

  /// flutter_appauth(시스템 브라우저) OAuth2 표준 흐름의 redirect (private-use scheme).
  /// SSO client_redirect_uris 에 동일 값 등록 필요. 네이티브 scheme=[authCallbackScheme] 등록 필요.
  static const String appAuthRedirectUri = '$authCallbackScheme://oauth/callback';

  /// OAuth2 client_id (SSO clients.client_code).
  static const String oauthClientId = 'desk';
}
