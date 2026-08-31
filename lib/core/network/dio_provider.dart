import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/core/auth/auth_events.dart';
import 'package:porest_desk_app/core/network/interceptors/auth_interceptor.dart';
import 'package:porest_desk_app/core/network/interceptors/error_toast_interceptor.dart';
import 'package:porest_desk_app/core/network/interceptors/lang_interceptor.dart';
import 'package:porest_desk_app/core/network/interceptors/log_interceptor.dart';
import 'package:porest_desk_app/core/network/secure_cookie_storage.dart';
import 'package:porest_desk_app/core/network/user_agent.dart';

/// 영속 cookie_jar (`desk_access_token` 보존) — OS 보안 저장소(Keystore/Keychain)에
/// 암호화 저장(SecureCookieStorage). 단일 인스턴스를 dio 와 로그아웃 헬퍼가 공유.
final cookieJarProvider = FutureProvider<PersistCookieJar>((ref) async {
  return PersistCookieJar(ignoreExpires: true, storage: SecureCookieStorage());
});

/// Dio 인스턴스 (싱글톤). cookie_jar 가 응답 쿠키를 자동 저장·재전송한다.
final dioProvider = FutureProvider<Dio>((ref) async {
  final jar = await ref.watch(cookieJarProvider.future);
  // 안 보내면 dart:io 기본값이 나가고, 서버는 어떤 기기인지 알 수 없다 —
  // "로그인된 기기" 목록이 전부 "Porest 앱" 으로만 보인다.
  final userAgent = await buildUserAgent();
  final dio =
      Dio(
          BaseOptions(
            baseUrl: '${Env.apiBase}/api/v1',
            headers: {'User-Agent': userAgent},
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 30),
            contentType: 'application/json',
            responseType: ResponseType.json,
          ),
        )
        ..interceptors.add(CookieManager(jar))
        ..interceptors.add(
          AuthInterceptor(
            onUnauthorized: () {
              // 다음 microtask 에서 처리해 onError 콜체인이 끝난 뒤 신호 발행.
              // dio 는 "세션 만료" 신호만 올리고(auth 의존성 없음), AuthNotifier 가
              // 이를 구독해 logout 한다 — dio↔auth 순환(CircularDependencyError) 제거.
              Future.microtask(() {
                ref.read(sessionExpiredProvider.notifier).bump();
              });
            },
          ),
        )
        // 아무 화면도 처리하지 않은 API 에러를 잡는 마지막 그물.
        // 화면이 자기 토스트를 띄우면 스스로 취소한다(주석은 인터셉터 파일 참조).
        ..interceptors.add(ErrorToastInterceptor())
        ..interceptors.add(LangInterceptor())
        ..interceptors.add(
          AppLogInterceptor(
            Logger(
              // release 빌드는 debug 로그(요청/응답 URL 등) 출력 차단 — warning 이상만.
              level: kDebugMode ? Level.debug : Level.warning,
              printer: SimplePrinter(printTime: true),
            ),
          ),
        );

  ref.onDispose(dio.close);
  return dio;
});
