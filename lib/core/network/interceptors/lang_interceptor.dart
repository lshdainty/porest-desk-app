import 'dart:ui';

import 'package:dio/dio.dart';

/// `Accept-Language` 헤더를 OS locale 로 자동 채워준다.
/// 백엔드는 message 번역에 이 헤더를 사용한다.
class LangInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final locale = PlatformDispatcher.instance.locale;
    options.headers['Accept-Language'] = locale.toLanguageTag();
    handler.next(options);
  }
}
