import 'dart:ui';

import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/settings/user_locale.dart';

/// `Accept-Language` 헤더를 사용자 선택 → OS locale 순으로 채운다.
/// 백엔드는 message 번역에 이 헤더를 사용한다.
class LangInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final user = UserLocale.current;
    final locale = user ?? PlatformDispatcher.instance.locale;
    options.headers['Accept-Language'] = locale.toLanguageTag();
    handler.next(options);
  }
}
