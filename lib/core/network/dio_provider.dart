import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../../app/env.dart';
import '../auth/auth_notifier.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/lang_interceptor.dart';
import 'interceptors/log_interceptor.dart';
import 'secure_cookie_storage.dart';

/// 영속 cookie_jar (`desk_access_token` 보존) — OS 보안 저장소(Keystore/Keychain)에
/// 암호화 저장(SecureCookieStorage). 단일 인스턴스를 dio 와 로그아웃 헬퍼가 공유.
final cookieJarProvider = FutureProvider<PersistCookieJar>((ref) async {
  return PersistCookieJar(
    ignoreExpires: true,
    storage: SecureCookieStorage(),
  );
});

/// Dio 인스턴스 (싱글톤). cookie_jar 가 응답 쿠키를 자동 저장·재전송한다.
final dioProvider = FutureProvider<Dio>((ref) async {
  final jar = await ref.watch(cookieJarProvider.future);
  final dio = Dio(
    BaseOptions(
      baseUrl: '${Env.apiBase}/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      contentType: 'application/json',
      responseType: ResponseType.json,
    ),
  )
    ..interceptors.add(CookieManager(jar))
    ..interceptors.add(AuthInterceptor(
      onUnauthorized: () {
        // 다음 microtask 에서 처리해 onError 콜체인이 끝난 뒤 logout 실행
        Future.microtask(() {
          ref.read(authProvider.notifier).logout();
        });
      },
    ))
    ..interceptors.add(LangInterceptor())
    ..interceptors.add(AppLogInterceptor(Logger(
      // release 빌드는 debug 로그(요청/응답 URL 등) 출력 차단 — warning 이상만.
      level: kDebugMode ? Level.debug : Level.warning,
      printer: SimplePrinter(printTime: true),
    )));

  ref.onDispose(dio.close);
  return dio;
});
