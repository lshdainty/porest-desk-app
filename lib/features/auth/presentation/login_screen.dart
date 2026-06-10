import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:webview_flutter/webview_flutter.dart';

import 'package:porest_desk_app/app/env.dart';
import 'package:porest_desk_app/app/theme/radius.dart';
import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/core/auth/auth_notifier.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';

/// SSO 로그인 화면.
///
/// 흐름 (Phase 5 계획서):
/// 1. WebView 로 `${Env.ssoUrl}/login?redirect_uri=porestdesk://auth/callback` 오픈
/// 2. SSO 페이지에서 사용자가 ID/PW 입력
/// 3. SSO 가 `porestdesk://auth/callback#token=<JWT>` 로 리다이렉트
/// 4. NavigationDelegate 가 그 URL 을 prevent + fragment 에서 token 추출
/// 5. AuthNotifier.exchangeAndLogin(token) → desk_access_token 쿠키 자동 저장
/// 6. router redirect 가 /home 으로 보냄
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _exchanging = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final ssoOrigin = Uri.tryParse(Env.ssoUrl);
    // 비-local 환경에서 SSO 가 HTTPS 가 아니면 로드 거부 (cleartext 자격증명 전송/MITM 방지).
    if (Env.appEnv != 'local' && ssoOrigin?.scheme != 'https') {
      _controller = WebViewController();
      _loading = false;
      _error = '보안 오류: SSO 서버가 HTTPS 가 아닙니다 (${Env.ssoUrl}).';
      return;
    }
    final allowedHost = ssoOrigin?.host;
    _controller = WebViewController()
      // React SSO 로그인 페이지 동작에 JS 필요 — 대신 네비게이션을 SSO 오리진으로 제한.
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => mounted ? setState(() => _loading = true) : null,
          onPageFinished: (_) => mounted ? setState(() => _loading = false) : null,
          onWebResourceError: (e) {
            if (!mounted) return;
            setState(() => _error = '${e.errorCode}: ${e.description}');
          },
          onNavigationRequest: (req) {
            if (req.url.startsWith(Env.authCallbackUri)) {
              _handleCallback(req.url);
              return NavigationDecision.prevent;
            }
            // SSO 오리진 밖 http/https 메인프레임 네비게이션 차단 (오리진 이탈/피싱 방지).
            final target = Uri.tryParse(req.url);
            if (target != null &&
                (target.scheme == 'http' || target.scheme == 'https') &&
                target.host != allowedHost) {
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(_buildLoginUrl()));
  }

  String _buildLoginUrl() {
    final encoded = Uri.encodeComponent(Env.authCallbackUri);
    return '${Env.ssoUrl}/login?redirect_uri=$encoded';
  }

  Future<void> _handleCallback(String url) async {
    final fragment = Uri.parse(url).fragment;
    final token = Uri.splitQueryString(fragment)['token'];
    if (token == null || token.isEmpty) {
      setState(() => _error = '콜백 URL 에서 token 을 찾지 못함');
      return;
    }
    setState(() => _exchanging = true);
    try {
      await ref.read(authProvider.notifier).exchangeAndLogin(token);
      // 성공 → router redirect 가 자동으로 /home 으로 이동
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _exchanging = false;
        _error = '로그인 실패: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _exchanging = false;
        _error = '로그인 처리 중 오류: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        title: const Text('로그인'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading || _exchanging)
            ColoredBox(
              color: t.bgCanvas.withValues(alpha: 0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: t.bgBrand),
                    if (_exchanging) ...[
                      const SizedBox(height: PSpace.x16),
                      Text('토큰 교환 중…',
                          style: PTypo.bodySm.copyWith(color: t.fgSecondary)),
                    ],
                  ],
                ),
              ),
            ),
          if (_error != null)
            Positioned(
              left: PSpace.x16,
              right: PSpace.x16,
              bottom: PSpace.x16,
              child: Material(
                color: t.statusDangerSubtle,
                borderRadius: const BorderRadius.all(Radius.circular(PRadius.md)),
                child: Padding(
                  padding: const EdgeInsets.all(PSpace.x12),
                  child: Text(_error!,
                      style: PTypo.bodySm.copyWith(color: t.statusDangerFg)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
