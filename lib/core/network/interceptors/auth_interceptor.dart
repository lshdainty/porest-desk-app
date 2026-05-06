import 'package:dio/dio.dart';

/// 401 응답을 감지하면 [onUnauthorized] 콜백을 호출 — 호출자(상위)는 보통
/// AuthNotifier.logout() 으로 세션 정리 후 router redirect.
///
/// `/auth/check`, `/auth/exchange`, `/auth/logout` 자체의 401 은 통과 (정상 흐름):
/// - check 의 401 = 미로그인 상태(부팅 시 첫 호출)
/// - exchange 실패는 LoginScreen 이 직접 처리
/// - logout 의 401 = 이미 만료된 세션, 무한 루프 방지
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.onUnauthorized});
  final void Function() onUnauthorized;

  static const _skipPaths = <String>{
    '/auth/check',
    '/auth/exchange',
    '/auth/logout',
  };

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401 && !_isSkipped(err.requestOptions.path)) {
      onUnauthorized();
    }
    handler.next(err);
  }

  bool _isSkipped(String path) {
    return _skipPaths.any(path.endsWith);
  }
}
