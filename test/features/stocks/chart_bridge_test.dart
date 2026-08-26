// 차트 임베드 WebView 의 값 전달 규칙 — 시크릿이 URL 로 새지 않는 것과
// ready 핸드셰이크 앞뒤의 레이스를 고정한다.
//
// 왜 이걸 테스트로 박아 두나
//   URL 에 실린 embed_token 은 아무도 "남기겠다" 고 결정한 적 없는 곳에 남는다 —
//   nginx 요청줄 · 같은 오리진이라 full URL 이 붙는 Referer · WebView 히스토리.
//   같은 유형의 사고를 이미 겪었다(desk-back#266: 시크릿을 쿼리에 실은 URL 이 예외 메시지를 타고 로그로).
//   토큰을 브릿지로 옮긴 뒤에는 "실수로 다시 URL 에 넣는" 회귀와 "ready 를 놓쳐 토큰이 사라지는"
//   회귀가 각각 조용하다 — 전자는 화면이 멀쩡하고, 후자는 차트만 빈 채로 뜬다.
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/stocks/presentation/chart_bridge.dart';

/// 브릿지가 내보낸 JS 를 모으는 가짜 WebView.
class _JsRecorder {
  final List<String> calls = [];
  void run(String js) => calls.add(js);
}

void main() {
  group('buildEmbedUrl — 시크릿이 쿼리로 나가지 않는다', () {
    String url({String symbol = 'AAPL', String range = '1D', String theme = 'light', bool isUs = true}) =>
        buildEmbedUrl(
          webBaseUrl: 'https://desk.example.com',
          symbol: symbol,
          range: range,
          theme: theme,
          isUs: isUs,
        );

    test('token 파라미터가 아예 없다', () {
      final u = url();
      expect(Uri.parse(u).queryParameters.containsKey('token'), isFalse);
      // 문자열 수준으로도 확인 — 다른 이름(access_token 등)으로 되살아나는 것도 잡는다.
      expect(u.toLowerCase(), isNot(contains('token')));
    });

    test('range·theme·isUs 는 그대로 실린다 — 첫 페인트 전에 필요한 값들', () {
      final qp = Uri.parse(url(range: '3개월', theme: 'dark', isUs: false)).queryParameters;
      expect(qp['range'], '3개월');
      expect(qp['theme'], 'dark');
      expect(qp['isUs'], '0');
    });

    test('심볼은 경로에 인코딩돼 들어간다', () {
      expect(url(symbol: '005930').startsWith('https://desk.example.com/embed/stocks/005930'), isTrue);
      expect(url(symbol: 'BRK/B'), contains('/embed/stocks/BRK%2FB'));
    });
  });

  group('ChartBridge — ready 앞뒤 레이스', () {
    late _JsRecorder js;
    late ChartBridge bridge;

    setUp(() {
      js = _JsRecorder();
      bridge = ChartBridge(js.run);
    });

    test('ready 전 push 는 나가지 않는다 — 이때 window.__*Bridge 가 아직 없다', () {
      bridge.pushToken('tok-1');
      bridge.pushRange('1주');
      bridge.pushTheme('dark');
      expect(js.calls, isEmpty);
      expect(bridge.isReady, isFalse);
    });

    test('ready 가 오면 보관해 둔 값이 replay 된다 — 토큰이 먼저', () {
      bridge.pushToken('tok-1');
      bridge.pushRange('1주');
      bridge.pushTheme('dark');

      bridge.onReady();

      expect(js.calls, [
        'window.__tokenBridge && window.__tokenBridge("tok-1")',
        'window.__rangeBridge && window.__rangeBridge("1주")',
        'window.__themeBridge && window.__themeBridge("dark")',
      ]);
    });

    test('첫 토큰만 있어도 ready 에 나간다 — URL 이 안 싣는 그 토큰', () {
      bridge.pushToken('tok-1');
      bridge.onReady();
      expect(js.calls, ['window.__tokenBridge && window.__tokenBridge("tok-1")']);
    });

    test('ready 후 push 는 즉시 나간다', () {
      bridge.onReady();
      expect(js.calls, isEmpty); // 보관된 게 없으면 replay 도 없다

      bridge.pushToken('tok-2');
      bridge.pushRange('1년');
      bridge.pushTheme('light');

      expect(js.calls, [
        'window.__tokenBridge && window.__tokenBridge("tok-2")',
        'window.__rangeBridge && window.__rangeBridge("1년")',
        'window.__themeBridge && window.__themeBridge("light")',
      ]);
    });

    test('ready 전 회전이 여러 번 돌면 마지막 토큰만 나간다 — 만료된 값을 순서대로 뱉지 않는다', () {
      bridge.pushToken('tok-1');
      bridge.pushToken('tok-2');
      bridge.pushToken('tok-3');

      bridge.onReady();

      expect(js.calls, ['window.__tokenBridge && window.__tokenBridge("tok-3")']);
    });

    test('빈 토큰은 무시한다 — 유효한 토큰을 덮지 않는다', () {
      bridge.pushToken('tok-1');
      bridge.pushToken('');
      bridge.onReady();
      expect(js.calls, ['window.__tokenBridge && window.__tokenBridge("tok-1")']);
    });

    test('페이지가 스스로 리로드해 ready 를 다시 보내면 최신값을 다시 밀어넣는다', () {
      bridge.pushToken('tok-1');
      bridge.onReady();
      bridge.pushToken('tok-2'); // 회전
      js.calls.clear();

      bridge.onReady(); // 리로드 후 두 번째 ready

      expect(js.calls, ['window.__tokenBridge && window.__tokenBridge("tok-2")']);
    });

    test('reset 은 다시 보관 모드로 돌린다 — 새 페이지가 ready 를 알리기 전엔 안 나간다', () {
      bridge.pushToken('tok-1');
      bridge.onReady();
      js.calls.clear();

      bridge.reset(); // 401 fallback / 심볼 변경으로 새 페이지를 띄운다
      expect(bridge.isReady, isFalse);

      bridge.pushToken('tok-new');
      expect(js.calls, isEmpty);

      bridge.onReady();
      expect(js.calls, ['window.__tokenBridge && window.__tokenBridge("tok-new")']);
    });

    test('reset 은 옛 페이지 앞으로 쌓인 값을 버린다 — 새 URL 이 다시 싣고 간다', () {
      bridge.pushToken('tok-1');
      bridge.pushRange('1년');
      bridge.reset();

      bridge.onReady();

      expect(js.calls, isEmpty);
    });

    test('인자는 JSON 으로 감싼다 — 따옴표가 든 토큰이 JS 문맥을 깨지 않는다', () {
      bridge.onReady();
      bridge.pushToken('a"b\\c\nd');
      expect(js.calls.single, r'window.__tokenBridge && window.__tokenBridge("a\"b\\c\nd")');
    });
  });
}
