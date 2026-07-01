import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'package:porest_desk_app/app/theme/spacing.dart';
import 'package:porest_desk_app/app/theme/tokens.dart';
import 'package:porest_desk_app/app/theme/typography.dart';
import 'package:porest_desk_app/shared/widgets/p_back_button.dart';
import 'package:porest_desk_app/shared/widgets/p_progress.dart';

/// SSO 로그인 인앱 WebView (OAuth 2.0 Authorization Code + PKCE).
///
/// 시스템 브라우저(Custom Tab) 대체 — 앱이 포그라운드를 유지한 채 SSO 로그인 폼을
/// 띄운다. 보안 프로토콜은 그대로(Authorization Code + PKCE + RS256 + BFF), UA 만 교체.
///
/// 흐름:
/// 1. [authorizeUrl] (`${ssoUrl}/api/v1/oauth2/authorize?...`) 로드 → SSO 가 로그인 폼으로 302.
/// 2. 사용자가 ID/PW 로그인 → SSO 가 최종적으로
///    `porestdesk://oauth/callback?code=&state=` 로 navigation 시도(서버 302).
/// 3. [shouldOverrideUrlLoading] 가 커스텀스킴을 가로채(navigation CANCEL) `code` 를
///    [Navigator.pop] 으로 호출자(login_screen)에 반환. state 불일치면 에러 표시.
///
/// flutter_inappwebview 의 `shouldOverrideUrlLoading` 은 iOS·Android 양쪽에서 커스텀스킴
/// (private-use scheme) navigation 을 확실히 가로챈다(`useShouldOverrideUrlLoading: true`).
class SsoWebViewPage extends StatefulWidget {
  const SsoWebViewPage({
    super.key,
    required this.authorizeUrl,
    required this.expectedState,
    required this.redirectUri,
  });

  /// SSO `/api/v1/oauth2/authorize` 전체 URL(쿼리 포함).
  final String authorizeUrl;

  /// authorize 요청에 실어 보낸 state — 콜백의 state 와 일치해야 한다(CSRF 방지).
  final String expectedState;

  /// OAuth2 redirect_uri (= `porestdesk://oauth/callback`). 이 스킴으로의 navigation 을 가로챈다.
  final String redirectUri;

  @override
  State<SsoWebViewPage> createState() => _SsoWebViewPageState();
}

class _SsoWebViewPageState extends State<SsoWebViewPage> {
  /// 콜백 스킴(= `porestdesk`). 이 스킴으로의 navigation 이면 OAuth 콜백으로 간주.
  late final String _redirectScheme = Uri.parse(widget.redirectUri).scheme;

  bool _firstLoadDone = false; // 최초 페이지 로드 완료 전까지 스피너 오버레이
  String? _error; // 메인 프레임 로드 실패 / state 불일치 시 표시

  /// 커스텀스킴 콜백 가로채기. `porestdesk://oauth/callback?code=&state=` 도착 시
  /// code 를 pop 으로 반환하고 navigation 은 CANCEL. 그 외 url 은 ALLOW(정상 이동).
  Future<NavigationActionPolicy> _onNavigation(
    InAppWebViewController controller,
    NavigationAction action,
  ) async {
    final url = action.request.url;
    if (url == null || url.scheme != _redirectScheme) {
      return NavigationActionPolicy.ALLOW;
    }

    // 콜백 — code/state 파싱.
    final code = url.queryParameters['code'];
    final state = url.queryParameters['state'];

    if (state != widget.expectedState) {
      // CSRF 의심 — 인가코드 폐기, 에러 표시.
      if (mounted) {
        setState(() => _error = '보안 검증에 실패했어요 (state 불일치). 다시 시도해 주세요.');
      }
      return NavigationActionPolicy.CANCEL;
    }

    if (code == null || code.isEmpty) {
      if (mounted) {
        setState(() => _error = '인가코드를 받지 못했어요. 다시 시도해 주세요.');
      }
      return NavigationActionPolicy.CANCEL;
    }

    if (mounted) Navigator.of(context).pop(code);
    return NavigationActionPolicy.CANCEL;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Scaffold(
      backgroundColor: t.bgCanvas,
      appBar: AppBar(
        leadingWidth: PBackButton.leadingWidth,
        titleSpacing: 0,
        // 뒤로가기 = 로그인 취소 (null 반환).
        leading: PBackButton(onPressed: () => Navigator.of(context).pop()),
        title: const Text('로그인'),
        backgroundColor: t.bgSurface,
        foregroundColor: t.fgPrimary,
        elevation: 0,
      ),
      body: SafeArea(
        child: _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(PSpace.x24),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: PTypo.bodySm.copyWith(color: t.statusDangerFg),
                  ),
                ),
              )
            : Stack(
                children: [
                  InAppWebView(
                    initialUrlRequest: URLRequest(
                      url: WebUri(widget.authorizeUrl),
                    ),
                    initialSettings: InAppWebViewSettings(
                      // 커스텀스킴 가로채기 — iOS 에서 필수(Android 는 기본 동작).
                      useShouldOverrideUrlLoading: true,
                      javaScriptEnabled: true,
                      // sso 세션 쿠키 재사용 허용(따로 안 지움).
                      clearCache: false,
                    ),
                    shouldOverrideUrlLoading: _onNavigation,
                    onLoadStop: (controller, url) {
                      if (mounted && !_firstLoadDone) {
                        setState(() => _firstLoadDone = true);
                      }
                    },
                    onReceivedError: (controller, request, error) {
                      // 메인 프레임 로드 실패만 사용자에게 노출(서브 리소스 누락 무시).
                      if (mounted && request.isForMainFrame == true) {
                        setState(
                          () => _error = '로그인 페이지를 불러오지 못했어요.\n${error.description}',
                        );
                      }
                    },
                  ),
                  if (!_firstLoadDone)
                    ColoredBox(
                      color: t.bgCanvas,
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
