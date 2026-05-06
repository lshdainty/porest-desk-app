import 'package:dio/dio.dart';
import 'package:logger/logger.dart';

/// 개발용 HTTP 로깅. release 빌드는 [Logger.level] 을 [Level.warning] 이상으로 올려 끈다.
class AppLogInterceptor extends Interceptor {
  AppLogInterceptor(this._log);
  final Logger _log;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('→ ${options.method} ${options.uri}');
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log.d('← ${response.statusCode} ${response.requestOptions.uri}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.w('✗ ${err.response?.statusCode} ${err.requestOptions.uri} — ${err.message}');
    handler.next(err);
  }
}
