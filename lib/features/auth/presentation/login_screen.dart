import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:porest_desk_app/l10n/generated/app_localizations.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/oauth_link_listener.dart';
import 'package:porest_desk_app/core/auth/pkce.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';

/// SSO 로그인 화면 (OAuth 2.0 Authorization Code + PKCE, 시스템 브라우저 — RFC 8252).
///
/// 흐름:
/// 1. 앱이 PKCE(code_verifier/code_challenge) + state 를 직접 생성,
///    [OAuthFlowStore] 에 **먼저 보관**(브라우저에 가 있는 동안 프로세스가 죽어도 복구).
/// 2. 시스템 브라우저로 SSO `/api/v1/oauth2/authorize` 오픈. SSO 에 Refresh 쿠키가
///    살아 있으면 무음 재인증으로 폼 없이 즉시 복귀한다.
/// 3. 로그인 완료 → SSO 서버가 302 로 `porestdesk://oauth/callback?code=&state=` 를
///    내려보냄 → OS 딥링크로 앱 복귀 → [oauthLinkListenerProvider] 가 state 검증 후
///    desk-back `/auth/exchange-code` 교환(BFF) → router 가 /home 으로.
///
/// 인앱 WebView 가 아니라 시스템 브라우저인 이유: Google 소셜 로그인이 임베디드
/// WebView 를 차단한다(403 disallowed_useragent). 예전 시스템 브라우저 시절의 두 버그는
/// 구조적으로 재발하지 않는다 — iOS 핸드오프는 서버 302 bounce 가, Android 백그라운드
/// 상태 유실은 PKCE 디스크 보관([OAuthFlowStore])이 막는다.
/// 로그인 실패를 사용자 문구로 바꾼다.
///
/// 원문(`ApiException.toString()`)을 그대로 띄우면 사용자에게
/// `ApiException(AUTH_003, ...)` 같은 게 보인다. 아는 경우는 이름을 불러 주고,
/// 나머지도 최소한 서버 메시지만 보여 준다. 화면 밖에 둔 이유는 테스트 때문이다 —
/// 인라인 `switch` 는 로그인 화면을 통째로 띄우지 않으면 확인할 길이 없다.
String loginErrorMessage(Object? e, AppLocalizations l) => switch (e) {
  // 해지한 계정은 "로그인 실패" 가 아니다 — 다시 눌러도 결과가 같다.
  // 무엇이 끝났는지와, 같은 아이디로는 못 돌아온다는 것을 말한다.
  ApiException(isWithdrawn: true) =>
    '${l.withdrawnTitle}\n${l.withdrawIrreversibleRejoin}',
  // 딥링크 코드가 만료됐다 — 다시 누르면 된다. "실패" 라고만 하면 뭘 다시 해야
  // 하는지 알 수 없다.
  ApiException(code: 'AUTH_003') => l.authLoginExpired,
  ApiException(message: final m) when m.isNotEmpty =>
    '${l.authLoginFailed}: $m',
  _ => '${l.authLoginFailed}: ${l.stateError}',
};

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  bool _busy = false;
  String? _error;

  Future<void> _login() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    // 비-local 환경에서 SSO 가 HTTPS 가 아니면 거부 (자격증명 평문 전송/MITM 방지).
    final ssoOrigin = Uri.tryParse(Env.ssoUrl);
    if (Env.appEnv != 'local' && ssoOrigin?.scheme != 'https') {
      setState(() => _error = l.authSecurityNotHttps(Env.ssoUrl));
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // 1) PKCE + state 생성(앱이 직접) → 브라우저로 나가기 전에 디스크 보관.
      //    복귀가 콜드 스타트여도 리스너가 이걸 복원해 교환을 이어간다.
      final verifier = generateCodeVerifier();
      final challenge = codeChallengeS256(verifier);
      final state = generateState();
      final store = ref.read(oauthFlowStoreProvider);
      await store.savePending(verifier: verifier, state: state);

      // 로그아웃 직후 첫 로그인은 폼 강제(prompt=login) — 무음 재인증이 로그아웃을
      // 되살리지 않게. 해제는 로그인 성공 시(리스너)에 한다.
      final forcePrompt = await store.isForceLoginPrompt();

      // 2) authorize URL 조립. challenge/state 는 base64url(no padding) 이라 URL-safe.
      final authorizeUrl =
          '${Env.ssoUrl}/api/v1/oauth2/authorize'
          '?response_type=code'
          '&client_id=${Env.oauthClientId}'
          '&redirect_uri=${Uri.encodeComponent(Env.oauthRedirectUri)}'
          '&code_challenge=$challenge'
          '&code_challenge_method=S256'
          '&state=${Uri.encodeComponent(state)}'
          '${forcePrompt ? '&prompt=login' : ''}';

      // 3) 시스템 브라우저로 — 복귀는 딥링크 리스너(oauthLinkListenerProvider)가 받는다.
      final launched = await launchUrl(
        Uri.parse(authorizeUrl),
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        throw StateError('브라우저를 열 수 없습니다');
      }
      // 여기서 흐름이 앱 밖으로 나간다 — 버튼은 다시 눌러 재시도할 수 있게 되돌린다.
      // (교환 진행 상태는 authProvider 의 AsyncLoading 이 담당)
      if (!mounted) return;
      setState(() => _busy = false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '${l.authLoginFailed}: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '${l.authLoginError}: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final l = AppLocalizations.of(context);
    // 교환은 딥링크 리스너에서 돈다 — 진행(AsyncLoading)은 버튼 스피너로,
    // 실패(AsyncError)는 이 화면의 에러 라인으로 흘려보낸다.
    final exchanging = ref.watch(authProvider).isLoading;
    ref.listen(authProvider, (prev, next) {
      if (next.hasError && mounted) {
        final e = next.error;
        setState(() => _error = loginErrorMessage(e, l));
      }
    });
    return Scaffold(
      backgroundColor: t.bgSurface,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: PSpace.x24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 마크는 타이틀 좌측 가로 배치(사용자 결정) — web 로그인 정합.
                    // 마크 56 / gap 0 — 아이콘 확대·간격 축소(사용자 결정).
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const _BrandMark(size: 56),
                        Text(
                          'Porest Desk',
                          style: PTypo.displayMd.copyWith(
                            color: t.fgPrimary,
                            fontWeight: PFontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: PSpace.x8),
                    Text(
                      l.authLoginPrompt,
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                    ),
                    const SizedBox(height: PSpace.x32),
                    PButton(
                      label: l.authSsoLogin,
                      onPressed: (_busy || exchanging) ? null : _login,
                      loading: _busy || exchanging,
                      fullWidth: true,
                      size: PButtonSize.lg,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: PSpace.x16),
                      Material(
                        color: t.statusDangerSubtle,
                        borderRadius: const BorderRadius.all(
                          Radius.circular(PRadius.md),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(PSpace.x12),
                          child: Text(
                            _error!,
                            style: PTypo.bodySm.copyWith(
                              color: t.statusDangerFg,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_busy)
              ColoredBox(
                color: t.bgCanvas.withValues(alpha: 0.6),
                child: Center(
                  child: PCircularProgressIndicator(color: t.bgBrand),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// 브랜드 마크 — web `porest-desk-mark.svg`(rect 4단 나무) 미러.
/// 색은 web 로그인 마크(fg-brand: 라이트 primary / 다크 primary-light) 정합 — 다크에서 밝게.
class _BrandMark extends StatelessWidget {
  const _BrandMark({this.size = 64});
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = context.tokens.fgBrand;
    // svg viewBox 100 기준 좌표를 size 비율로 환산 (행높이 12, 간격 6, 꼬리 11×10).
    Widget bar(double w, double h) => Container(
      width: size * w / 100,
      height: size * h / 100,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(size * 6 / 100),
      ),
    );
    return SizedBox(
      width: size,
      height: size,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          bar(22, 12),
          SizedBox(height: size * 6 / 100),
          bar(40, 12),
          SizedBox(height: size * 6 / 100),
          bar(58, 12),
          SizedBox(height: size * 6 / 100),
          bar(11, 10),
        ],
      ),
    );
  }
}
