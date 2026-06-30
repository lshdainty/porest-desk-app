import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/auth/pkce.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/auth/presentation/sso_webview_page.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';

/// SSO 로그인 화면 (OAuth 2.0 Authorization Code + PKCE, 인앱 WebView).
///
/// 흐름:
/// 1. 앱이 PKCE(code_verifier/code_challenge) + state 를 직접 생성.
/// 2. [SsoWebViewPage] 를 push → 인앱 WebView 가 SSO `/api/v1/oauth2/authorize` 오픈
///    (SSO 가 로그인 폼으로 redirect, 앱은 포그라운드 유지).
/// 3. 로그인 성공 → SSO 가 `porestdesk://oauth/callback?code=&state=` 로 navigation →
///    WebView 가 가로채 code 를 pop 으로 반환 (token 교환은 하지 않음 — BFF).
/// 4. desk-back `/auth/exchange-code` 로 교환(code+codeVerifier) → desk_access_token 쿠키.
/// 5. router redirect 가 /home 으로 이동.
///
/// 시스템 브라우저(flutter_appauth) 대신 인앱 WebView 를 쓰는 이유: 일부 Android 기기에서
/// Custom Tab 으로 나가는 순간 앱 액티비티가 상태를 잃어 콜백을 못 받는 문제 회피. 보안
/// 프로토콜(Authorization Code + PKCE + RS256 + BFF)은 그대로, UA 만 인앱 WebView 로 교체.
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
    // 비-local 환경에서 SSO 가 HTTPS 가 아니면 거부 (자격증명 평문 전송/MITM 방지).
    final ssoOrigin = Uri.tryParse(Env.ssoUrl);
    if (Env.appEnv != 'local' && ssoOrigin?.scheme != 'https') {
      setState(() => _error = '보안 오류: SSO 서버가 HTTPS 가 아닙니다 (${Env.ssoUrl}).');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      // 1) PKCE + state 생성 (flutter_appauth 가 하던 일을 앱이 직접).
      final verifier = generateCodeVerifier();
      final challenge = codeChallengeS256(verifier);
      final state = generateState();

      // 2) authorize URL 조립. challenge/state 는 base64url(no padding) 이라 URL-safe.
      final authorizeUrl =
          '${Env.ssoUrl}/api/v1/oauth2/authorize'
          '?response_type=code'
          '&client_id=${Env.oauthClientId}'
          '&redirect_uri=${Uri.encodeComponent(Env.appAuthRedirectUri)}'
          '&code_challenge=$challenge'
          '&code_challenge_method=S256'
          '&state=${Uri.encodeComponent(state)}';

      // 3) 인앱 WebView 로 로그인 → code 수신(취소 시 null).
      final code = await Navigator.of(context).push<String?>(
        MaterialPageRoute(
          builder: (_) => SsoWebViewPage(
            authorizeUrl: authorizeUrl,
            expectedState: state,
            redirectUri: Env.appAuthRedirectUri,
          ),
        ),
      );

      if (code == null || code.isEmpty) {
        // 사용자가 로그인 취소 — 조용히 복귀.
        if (!mounted) return;
        setState(() => _busy = false);
        return;
      }

      // 4) BFF 교환 — authorize 와 동일한 redirect_uri 로(SSO redirect_uri 일치검증).
      await ref.read(authProvider.notifier).exchangeAndLoginWithCode(
            code: code,
            codeVerifier: verifier,
            redirectUri: Env.appAuthRedirectUri,
          );
      // 성공 → router redirect 가 자동으로 /home 으로 이동.
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '로그인 실패: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '로그인 처리 중 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      body: SafeArea(
        child: Stack(
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: PSpace.x24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Porest Desk',
                      style: PTypo.displayMd.copyWith(
                        color: t.fgPrimary,
                        fontWeight: PFontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: PSpace.x8),
                    Text(
                      'SSO 계정으로 로그인하세요',
                      style: PTypo.bodySm.copyWith(color: t.fgSecondary),
                    ),
                    const SizedBox(height: PSpace.x32),
                    PButton(
                      label: 'SSO 로그인',
                      onPressed: _busy ? null : _login,
                      loading: _busy,
                      fullWidth: true,
                      size: PButtonSize.lg,
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: PSpace.x16),
                      Material(
                        color: t.statusDangerSubtle,
                        borderRadius:
                            const BorderRadius.all(Radius.circular(PRadius.md)),
                        child: Padding(
                          padding: const EdgeInsets.all(PSpace.x12),
                          child: Text(
                            _error!,
                            style: PTypo.bodySm
                                .copyWith(color: t.statusDangerFg),
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
