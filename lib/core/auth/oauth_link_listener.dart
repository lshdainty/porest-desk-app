import 'dart:async';

import 'package:app_links/app_links.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/oauth_callback_handler.dart';
import 'package:porest_desk_app/core/auth/oauth_flow_store.dart';

/// PKCE 흐름 보관소 — 로그인 화면(저장)과 콜백 리스너(복원)가 같은 인스턴스를 본다.
final oauthFlowStoreProvider = Provider<OAuthFlowStore>((ref) => OAuthFlowStore());

/// OAuth 콜백 딥링크 리스너.
///
/// 앱 기동 시 한 번 켜 둔다(app.dart 에서 watch). 두 경로를 모두 받는다:
/// - 앱이 살아 있는 복귀: [AppLinks.uriLinkStream]
/// - 브라우저에 가 있는 동안 프로세스가 죽었다 떠도: [AppLinks.getInitialLink]
///
/// 후자가 핵심이다 — 예전 flutter_appauth 는 이 경우 진행 상태를 잃어
/// "No stored state" 로 로그인이 깨졌다. 지금은 code_verifier 가
/// [OAuthFlowStore](디스크)에 있으므로 콜드 스타트에서도 교환을 이어간다.
final oauthLinkListenerProvider = Provider<void>((ref) {
  final handler = OAuthCallbackHandler(
    store: ref.watch(oauthFlowStoreProvider),
    exchange: ({required String code, required String codeVerifier}) =>
        ref.read(authProvider.notifier).exchangeAndLoginWithCode(
              code: code,
              codeVerifier: codeVerifier,
              redirectUri: Env.oauthRedirectUri,
            ),
  );

  Future<void> onLink(Uri uri) async {
    try {
      final result = await handler.handle(uri);
      if (result != OAuthCallbackResult.exchanged &&
          result != OAuthCallbackResult.notCallback) {
        // 위조·중복·불완전 콜백 — 사용자에게 띄울 일은 아니고 진단용 로그만.
        debugPrint('OAuth callback ignored: $result');
      }
    } catch (e) {
      // 교환 실패는 authProvider 가 AsyncError 로 들고 있어 로그인 화면이 표시한다.
      debugPrint('OAuth exchange failed: $e');
    }
  }

  final appLinks = AppLinks();
  // 콜드 스타트 분 — 놓친 initial link 를 먼저 소화하고 스트림을 켠다.
  unawaited(appLinks.getInitialLink().then((uri) {
    if (uri != null) onLink(uri);
  }));
  final sub = appLinks.uriLinkStream.listen(onLink);
  ref.onDispose(sub.cancel);
});
