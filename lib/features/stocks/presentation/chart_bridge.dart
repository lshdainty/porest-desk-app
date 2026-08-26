/// 차트 임베드 WebView 로 나가는 값(embed_token · 기간 · 테마)의 **전달 규칙**만 담는다.
///
/// 위젯에서 떼어낸 이유는 두 가지를 테스트로 못 박기 위해서다.
///
///  1. **임베드 URL 에 시크릿이 실리지 않는다.** [buildEmbedUrl] 은 토큰을 인자로 받지도 않는다 —
///     넣을 자리가 없으면 실수로 넣을 수도 없다. URL 에 시크릿을 넣으면 아무도 "남기겠다" 고
///     결정한 적 없는 곳에 남는다: nginx 요청줄 · 같은 오리진이라 full URL 이 붙는 Referer ·
///     WebView 히스토리. 이 레포는 같은 유형의 사고를 이미 겪었다(desk-back#266).
///  2. **ready 핸드셰이크 전에 밀어넣은 값이 유실되지 않는다.** 페이지가 ready 를 알리기 전에는
///     `window.__*Bridge` 가 아직 없어 `window.X && window.X(...)` 가 조용히 no-op 된다.
///     그래서 ready 전 push 는 최신값만 보관했다가 ready 때 replay 한다.
library;

import 'dart:convert';

/// 임베드 페이지 URL.
///
/// **토큰을 받지 않는다.** 첫 토큰도 회전 토큰과 같은 길(`__tokenBridge`)로 간다.
///
/// `range`·`theme`·`isUs` 는 계속 쿼리로 보낸다 — 시크릿이 아니고, **첫 페인트 전에** 필요하다.
/// 브릿지는 페이지가 마운트된 뒤에야 도는 길이라 이 셋을 브릿지로 옮기면 라이트→다크 깜빡임과
/// 잘못된 기간으로의 첫 조회가 생긴다. 반면 토큰은 첫 페인트에 필요하지 않다(데이터 조회 때 필요).
String buildEmbedUrl({
  required String webBaseUrl,
  required String symbol,
  required String range,
  required String theme,
  required bool isUs,
}) {
  final base = Uri.parse('$webBaseUrl/embed/stocks/${Uri.encodeComponent(symbol)}');
  return base.replace(queryParameters: <String, String>{
    ...base.queryParameters,
    'range': range,
    'theme': theme,
    'isUs': isUs ? '1' : '0',
  }).toString();
}

/// Dart → JS 푸시 큐. ready 전 push 는 **최신값만** 보관했다가 ready 시 replay 한다.
///
/// 최신값만 남기는 게 핵심이다 — 큐에 쌓아 두면 45초마다 도는 토큰 회전이 만료된 토큰들을
/// 순서대로 뱉어 마지막에야 유효한 값이 도착한다.
class ChartBridge {
  ChartBridge(this._run);

  /// 실제로 WebView 에 JS 를 실행하는 함수. 테스트는 문자열을 수집한다.
  final void Function(String js) _run;

  bool _ready = false;
  String? _token;
  String? _range;
  String? _theme;

  /// 페이지가 ready 를 알렸는지. 테스트/디버그용.
  bool get isReady => _ready;

  /// 페이지가 ready 를 알렸다 — 보관해 둔 값을 replay 한다.
  ///
  /// **토큰이 먼저다.** 페이지는 토큰 없이는 데이터를 못 부르는데, 기간이 먼저 도착하면
  /// 그 기간으로 조회를 시도했다가 토큰 없이 실패할 여지가 생긴다.
  ///
  /// 보관값을 지우지 않는다 — 페이지가 스스로 리로드해 ready 를 다시 보내면 그때도 replay 해야
  /// 한다(호스트는 그 리로드를 모른다).
  void onReady() {
    _ready = true;
    final token = _token;
    if (token != null) _send('__tokenBridge', token);
    final range = _range;
    if (range != null) _send('__rangeBridge', range);
    final theme = _theme;
    if (theme != null) _send('__themeBridge', theme);
  }

  /// 새 페이지를 띄운다 — 다음 ready 까지 다시 보관 모드로 돌린다.
  /// 옛 페이지 앞으로 쌓아 둔 값은 새 URL 이 다시 싣고 가므로 버린다.
  void reset() {
    _ready = false;
    _token = null;
    _range = null;
    _theme = null;
  }

  /// 첫 토큰과 회전 토큰이 **같은 길로** 간다. ready 전이면 보관했다가 ready 때 나간다.
  void pushToken(String token) {
    if (token.isEmpty) return; // 빈 값으로 유효한 토큰을 덮지 않는다
    _token = token;
    if (_ready) _send('__tokenBridge', token);
  }

  void pushRange(String range) {
    _range = range;
    if (_ready) _send('__rangeBridge', range);
  }

  void pushTheme(String theme) {
    _theme = theme;
    if (_ready) _send('__themeBridge', theme);
  }

  /// 인자는 반드시 [jsonEncode] 로 감싼다 — 토큰은 외부에서 온 문자열이라
  /// 따옴표를 직접 붙이면 JS 문맥이 깨지거나 주입된다.
  void _send(String fn, String arg) => _run('window.$fn && window.$fn(${jsonEncode(arg)})');
}
