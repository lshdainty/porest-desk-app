/// 빌드 시 `--dart-define` 으로 주입되는 환경변수.
///
/// 예) Android 에뮬레이터 (호스트 Mac 가리키기):
///   `fvm flutter run --dart-define=API_BASE=http://10.0.2.2:8002 \
///                    --dart-define=SSO_URL=http://10.0.2.2:3000`
///
/// 미지정 시 로컬 개발 기본값 (iOS 시뮬용 — localhost 가 호스트 Mac).
abstract final class Env {
  /// Desk 백엔드 base URL (Spring Boot, 기본 :8002).
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8002',
  );

  /// SSO **프론트** URL (React 로그인 페이지, 기본 :3000).
  /// SSO 백엔드(:8000)가 아님 — WebView 가 띄우는 건 ID/PW 폼이 있는 프론트 페이지다.
  static const String ssoUrl = String.fromEnvironment(
    'SSO_URL',
    defaultValue: 'http://localhost:3000',
  );

  /// SSO 로그인 후 캐치할 모바일 전용 redirect_uri.
  /// SSO DB의 client_redirect_uris 에 동일 값으로 등록되어 있어야 한다.
  static const String authCallbackScheme = 'porestdesk';
  static const String authCallbackUri = '$authCallbackScheme://auth/callback';
}
