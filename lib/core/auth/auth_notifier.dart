import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/auth/auth_events.dart';
import 'package:porest_desk_app/core/auth/oauth_link_listener.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/core/auth/auth_repository.dart';
import 'package:porest_desk_app/core/auth/user.dart';

final authRepositoryProvider = FutureProvider<AuthRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return AuthRepository(dio);
});

/// 인증 상태 = `AsyncValue<User?>`.
/// - loading: 세션 검증 중
/// - data(user): 로그인됨
/// - data(null): 로그아웃 / 미인증
/// - error: 검증 자체가 네트워크 등으로 실패
final authProvider = AsyncNotifierProvider<AuthNotifier, User?>(
  AuthNotifier.new,
);

class AuthNotifier extends AsyncNotifier<User?> {
  @override
  Future<User?> build() async {
    // 401(세션 만료) 신호 구독 — dio 인터셉터가 신호를 올리면 강제 로그아웃.
    // dio 는 auth 를 직접 참조하지 않고 신호만 올리므로 dio↔auth 순환이 끊긴다.
    ref.listen(sessionExpiredProvider, (prev, next) {
      if ((prev ?? 0) < next) {
        logout();
      }
    });

    final repo = await ref.watch(authRepositoryProvider.future);
    try {
      return await repo.check();
    } on ApiException catch (e) {
      // 401 = 미로그인 상태로 간주 (정상 케이스)
      if (e.isUnauthorized) return null;
      rethrow;
    }
  }

  /// OAuth2 인가코드(PKCE)를 desk 토큰으로 교환 후 인증 상태 갱신 (표준 흐름, BFF).
  ///
  /// 인앱 WebView 가 가로챈 인가코드(code)+codeVerifier 를 desk-back 으로 교환한다.
  /// 1. `/auth/exchange-code` → desk_access_token 쿠키 발급
  /// 2. `/auth/check` → 사용자 정보 (rowId 포함)
  /// 3. AsyncData(user) → router redirect 가 /home 으로 이동
  ///
  /// 실패 시 [ApiException] 등을 그대로 throw — LoginScreen 의 catch 가 사용자에게 표시.
  Future<void> exchangeAndLoginWithCode({
    required String code,
    required String codeVerifier,
    required String redirectUri,
  }) async {
    final repo = await ref.read(authRepositoryProvider.future);
    state = const AsyncLoading();
    try {
      await repo.exchangeCode(
        code: code,
        codeVerifier: codeVerifier,
        redirectUri: redirectUri,
      );
      final user = await repo.check();
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  /// 로그아웃: 서버 호출 + 쿠키 정리 + 상태 초기화.
  Future<void> logout() async {
    final repo = await ref.read(authRepositoryProvider.future);
    final jar = await ref.read(cookieJarProvider.future);
    state = const AsyncLoading();
    try {
      await repo.logout();
    } on ApiException {
      // transient 실패 대비 1회 재시도 — 서버 세션이 살아있는 채 클라만 비는 상황 최소화.
      try {
        await repo.logout();
      } on ApiException {
        // 그래도 실패하면 클라이언트 세션만 정리(UI 로그아웃 보장).
        // 서버 세션 무효화는 토큰 만료 시점에 처리됨.
      }
    }
    await jar.deleteAll();
    // SSO Refresh 쿠키는 시스템 브라우저 안에 있어 앱이 지울 수 없다 — 다음 로그인에
    // prompt=login 을 실어 무음 재인증이 로그아웃을 조용히 되살리는 것을 막는다.
    // (해제는 다음 로그인 성공 시 콜백 처리기가 한다)
    await ref.read(oauthFlowStoreProvider).markForceLoginPrompt();
    state = const AsyncData(null);
  }
}
