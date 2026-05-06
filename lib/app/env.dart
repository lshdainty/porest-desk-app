/// 빌드 시 `--dart-define` 으로 주입되는 환경변수.
///
/// 예) `fvm flutter run --dart-define=API_BASE=http://10.0.2.2:8002 \
///                       --dart-define=SSO_URL=http://10.0.2.2:8000`
///
/// 미지정 시 로컬 개발 기본값을 사용한다.
abstract final class Env {
  static const String apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'http://localhost:8002',
  );

  static const String ssoUrl = String.fromEnvironment(
    'SSO_URL',
    defaultValue: 'http://localhost:8000',
  );

  /// SSO 로그인 후 캐치할 모바일 전용 redirect_uri.
  /// SSO DB의 client_redirect_uris 에 동일 값으로 등록되어 있어야 한다.
  static const String authCallbackScheme = 'porestdesk';
  static const String authCallbackUri = '$authCallbackScheme://auth/callback';
}
