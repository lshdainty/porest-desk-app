import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/shared/widgets/p_button.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';

/// SSO 로그인 화면 (OAuth 2.0 Authorization Code + PKCE, 시스템 브라우저).
///
/// 흐름:
/// 1. flutter_appauth `authorize()` → 시스템 브라우저로 SSO `/api/v1/oauth2/authorize` 오픈
///    (SSO 가 로그인 페이지로 redirect, PKCE code_challenge 는 appauth 가 자동 생성)
/// 2. 로그인 성공 → SSO 가 `porestdesk://oauth/callback?code=&state=` 로 redirect
/// 3. appauth 가 code + codeVerifier 반환 (token 교환은 하지 않음 — BFF)
/// 4. desk-back `/auth/exchange-code` 로 교환 → desk_access_token 쿠키
/// 5. router redirect 가 /home 으로 이동
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static const FlutterAppAuth _appAuth = FlutterAppAuth();

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
      final result = await _appAuth.authorize(
        AuthorizationRequest(
          Env.oauthClientId,
          Env.appAuthRedirectUri,
          serviceConfiguration: AuthorizationServiceConfiguration(
            authorizationEndpoint: '${Env.ssoUrl}/api/v1/oauth2/authorize',
            tokenEndpoint: '${Env.ssoUrl}/api/v1/oauth2/token',
          ),
        ),
      );
      final code = result.authorizationCode;
      final verifier = result.codeVerifier;
      if (code == null || code.isEmpty || verifier == null || verifier.isEmpty) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = '인가코드를 받지 못했어요';
        });
        return;
      }
      await ref.read(authProvider.notifier).exchangeAndLoginWithCode(
            code: code,
            codeVerifier: verifier,
            redirectUri: Env.appAuthRedirectUri,
          );
      // 성공 → router redirect 가 자동으로 /home 으로 이동
    } on FlutterAppAuthUserCancelledException {
      // 사용자가 로그인 취소 — 조용히 복귀
      if (!mounted) return;
      setState(() => _busy = false);
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
