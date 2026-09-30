// 나무증권 화면은 웹과 같은 박자로 새로 받는다.
//
// 예전엔 이 화면에 다시 받는 자리가 하나도 없었다. provider 가 autoDispose 가 아니라
// 처음 받은 시세·보유 종목이 앱을 다시 켤 때까지 굳어 있었고, 앱으로 돌아와도 그대로였다.
//
// 그렇다고 토스 화면처럼 10초마다 전부 조르면 안 된다. 나무엔 다건 조회 API 가 없어
// 조회 한 번이 곧 상류 1콜이고 유량 제한(429)이 있다. 그래서 웹 나무 화면
// (`NamuStocksPage` · `useNamu`)이 하는 만큼만 한다.
//
//   현재가    — 30초마다. 앱이 가려진 동안은 멈춘다.
//   보유 종목 — 주기로 조르지 않는다. 들어올 때·돌아올 때 30초가 지났으면 다시 받는다.
//   실패      — 자동으로 다시 치지 않는다.
//
// 여기서 세는 건 "타이머가 있다" 가 아니라 **나무 조회가 실제로 몇 번 나갔는가** 다.
// 시간은 위젯 테스트의 가짜 시계로 민다.
import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/app/theme/theme_data.dart';
import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/sync/query_freshness.dart';
import 'package:porest_desk_app/features/stocks/application/namu_providers.dart';
import 'package:porest_desk_app/features/stocks/application/stocks_providers.dart';
import 'package:porest_desk_app/features/stocks/data/namu_repository.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';
import 'package:porest_desk_app/features/stocks/presentation/namu_stocks_view.dart';
import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

void main() {
  // ─── 현재가 ─────────────────────────────────────────────────
  group('현재가', () {
    testWidgets('30초마다 다시 받는다 — 그 사이에는 안 받는다', (tester) async {
      final h = await _pumpView(tester);
      await h.pickStock();
      expect(h.namu.priceCalls, 1, reason: '고른 자리에서 한 번 받는다');

      await h.advanceTo(const Duration(seconds: 29));
      expect(
        h.namu.priceCalls,
        1,
        reason: '30초가 안 됐는데 나무를 또 쳤다 — 조회 한 번이 상류 1콜이다',
      );

      await h.advanceTo(const Duration(seconds: 30));
      expect(
        h.namu.priceCalls,
        2,
        reason: '30초가 지났는데 시세가 그대로다 — 예전엔 앱을 다시 켤 때까지 처음 값이었다',
      );

      await h.advanceTo(const Duration(seconds: 59));
      expect(h.namu.priceCalls, 2);
      await h.advanceTo(const Duration(seconds: 60));
      expect(h.namu.priceCalls, 3);
      expect(
        find.text('72000.0 KRW'),
        findsOneWidget,
        reason: '새로 받은 값이 화면에 실려야 한다',
      );
    });

    testWidgets('박자는 고른 순간부터 센다 — 화면을 연 때부터가 아니다', (tester) async {
      final h = await _pumpView(tester);

      await h.advanceTo(const Duration(seconds: 20));
      await h.pickStock();
      expect(h.namu.priceCalls, 1);

      await h.advanceTo(const Duration(seconds: 49));
      expect(
        h.namu.priceCalls,
        1,
        reason: '화면을 연 지 30초라고 고른 지 10초 만에 한 번 더 쳤다',
      );

      await h.advanceTo(const Duration(seconds: 50));
      expect(h.namu.priceCalls, 2);
    });

    testWidgets('고른 종목이 없으면 아무것도 안 나간다', (tester) async {
      final h = await _pumpView(tester);

      await h.advanceTo(const Duration(minutes: 2));

      expect(h.namu.priceCalls, 0, reason: '아무도 안 보는 시세를 받았다');
    });

    testWidgets('앱이 가려진 동안은 건너뛰고, 돌아오면 다음 박자에 이어 받는다', (tester) async {
      final h = await _pumpView(tester);
      await h.pickStock();

      await h.advanceTo(const Duration(seconds: 5));
      await h.background();
      await h.advanceTo(const Duration(seconds: 65));
      expect(
        h.namu.priceCalls,
        1,
        reason: '앱이 안 보이는데 30초·60초 박자에 나무를 쳤다 — 웹도 탭이 가려지면 멈춘다',
      );

      await h.foreground();
      expect(
        h.namu.priceCalls,
        1,
        reason: '돌아온 즉시 받지는 않는다 — 웹도 시세는 포커스로 다시 받지 않고 다음 박자를 기다린다',
      );

      await h.advanceTo(const Duration(seconds: 90));
      expect(h.namu.priceCalls, 2, reason: '돌아왔는데 주기가 다시 안 돈다');
    });

    testWidgets('화면을 닫으면 더 묻지 않는다', (tester) async {
      // 타이머가 새는지는 여기 기대값이 아니라 테스트 틀이 잡는다 — 화면을 걷은 뒤에도
      // 남은 타이머가 있으면 "A Timer is still pending" 으로 이 테스트가 깨진다.
      final h = await _pumpView(tester);
      await h.pickStock();

      await h.close();
      await h.advanceTo(const Duration(minutes: 3));

      expect(h.namu.priceCalls, 1, reason: '화면이 없는데 시세를 계속 받는다');
    });

    testWidgets('실패해도 몰아서 다시 치지 않는다 — 다음 박자까지 기다린다', (tester) async {
      // riverpod 은 실패한 provider 를 기본으로 0.2초부터 두 배씩 최대 10번 다시 만든다.
      // 나무가 429(유량 초과)로 거절했을 때 그러면 한도를 넘긴 그 순간에 열 번을 더 친다.
      final h = await _pumpView(tester);
      h.namu.failPrice = true;
      await h.pickStock();
      expect(h.namu.priceCalls, 1);

      await h.advanceTo(const Duration(seconds: 20));
      expect(
        h.namu.priceCalls,
        1,
        reason: '실패한 조회를 자동으로 다시 쳤다 — 20초면 기본 재시도가 여섯 번 넘게 나간다',
      );

      await h.advanceTo(const Duration(seconds: 30));
      expect(h.namu.priceCalls, 2, reason: '다음 박자에는 다시 물어야 한다');
    });

    testWidgets('다시 받다 실패하면 보던 시세를 그대로 둔다', (tester) async {
      // 예전엔 다시 받는 일이 없어 값이 오류로 뒤집힐 일도 없었다. 폴링 한 번의 실패로
      // 방금까지 보던 시세가 오류 문구로 바뀌면 고치기 전보다 나빠진다.
      final h = await _pumpView(tester);
      await h.pickStock();
      expect(find.text('70000.0 KRW'), findsOneWidget);

      h.namu.failPrice = true;
      await h.advanceTo(const Duration(seconds: 30));
      expect(h.namu.priceCalls, 2);
      expect(find.text('70000.0 KRW'), findsOneWidget, reason: '보던 시세가 사라졌다');
      expect(find.text('현재가를 불러오지 못했어요'), findsNothing);

      h.namu.failPrice = false;
      await h.advanceTo(const Duration(seconds: 60));
      expect(h.namu.priceCalls, 3);
      expect(
        find.text('72000.0 KRW'),
        findsOneWidget,
        reason: '다음 박자에 새 값으로 바뀌어야 한다',
      );
    });

    testWidgets('처음부터 못 받았으면 오류 문구를 보여 준다', (tester) async {
      final h = await _pumpView(tester);
      h.namu.failPrice = true;

      await h.pickStock();

      expect(find.text('현재가를 불러오지 못했어요'), findsOneWidget);
    });

    testWidgets('받는 중이면 겹쳐 조르지 않는다 — 응답이 느려도, 연달아 눌러도', (tester) async {
      final h = await _pumpView(tester);
      h.namu.holdPrice();
      await h.pickStock();
      expect(h.namu.priceCalls, 1);

      // 같은 종목을 또 누른다.
      await h.tapStock();
      expect(h.namu.priceCalls, 1, reason: '답이 오기도 전에 같은 시세를 또 물었다');

      // 30초·60초 박자가 지나도 첫 요청이 아직 안 끝났다.
      await h.advanceTo(const Duration(seconds: 65));
      expect(
        h.namu.priceCalls,
        1,
        reason: '느린 응답 위에 박자마다 요청을 얹었다 — 나무가 느릴수록 더 친다',
      );

      h.namu.releasePrice();
      await h.advanceTo(const Duration(seconds: 90));
      expect(h.namu.priceCalls, 2, reason: '답이 온 뒤에는 다음 박자부터 다시 받는다');
    });

    testWidgets('예전에 본 종목도 고르는 자리에서 새로 받는다', (tester) async {
      final h = await _pumpView(tester);
      await h.pickStock();
      expect(h.namu.priceCalls, 1);

      // 화면을 닫았다 다시 연다 — 받아 둔 시세는 컨테이너에 그대로 남아 있다.
      await h.close();
      await h.advanceTo(const Duration(seconds: 50));
      await h.open();
      await h.pickStock();

      expect(
        h.namu.priceCalls,
        2,
        reason: '50초 전 시세를 "현재가" 로 보여 줬다 — 다음 폴링까지 최대 30초를 묵은 값으로 본다',
      );
    });
  });

  // ─── 보유 종목 ───────────────────────────────────────────────
  group('보유 종목', () {
    testWidgets('주기로 조르지 않는다', (tester) async {
      final h = await _pumpView(tester);
      expect(h.namu.holdingsCalls, ['KRW'], reason: '들어올 때 한 번 받는다');

      await h.advanceTo(const Duration(minutes: 5));

      expect(
        h.namu.holdingsCalls,
        ['KRW'],
        reason: '웹은 보유 종목을 폴링하지 않는다 — 앱만 조르면 나무 유량 제한을 앱이 먼저 쓴다',
      );
    });

    testWidgets('앱으로 돌아왔을 때 30초가 지났으면 다시 받는다', (tester) async {
      final h = await _pumpView(tester);

      await h.background();
      await h.advanceTo(const Duration(seconds: 31));
      await h.foreground();

      expect(
        h.namu.holdingsCalls,
        ['KRW', 'KRW'],
        reason: '앱으로 돌아와도 보유 종목이 떠나기 전 값이다 — 예전엔 앱을 다시 켜야 바뀌었다',
      );
      expect(
        find.text('보유화학 2차'),
        findsOneWidget,
        reason: '새로 받은 값이 화면에 실려야 한다',
      );
    });

    testWidgets('30초가 안 지났으면 돌아와도 그대로 둔다', (tester) async {
      final h = await _pumpView(tester);

      await h.background();
      await h.advanceTo(const Duration(seconds: 20));
      await h.foreground();

      expect(h.namu.holdingsCalls, ['KRW'], reason: '방금 받은 값을 또 받았다');
    });

    testWidgets('화면을 다시 열 때도 같은 규칙이다', (tester) async {
      final h = await _pumpView(tester);

      await h.close();
      await h.advanceTo(const Duration(seconds: 20));
      await h.open();
      expect(h.namu.holdingsCalls, [
        'KRW',
      ], reason: '20초 전에 받은 값이다 — 다시 받을 이유가 없다');

      await h.close();
      await h.advanceTo(const Duration(seconds: 45));
      await h.open();
      expect(
        h.namu.holdingsCalls,
        ['KRW', 'KRW'],
        reason: '45초 묵은 값을 그대로 보여 줬다 — 화면을 다시 열어도 처음 받은 값에 굳어 있다',
      );
    });

    testWidgets('통화를 바꿨다 돌아올 때도 통화마다 따로 잰다', (tester) async {
      final h = await _pumpView(tester);

      await h.advanceTo(const Duration(seconds: 10));
      await h.showCurrency('해외');
      expect(h.namu.holdingsCalls, ['KRW', 'USD'], reason: '해외는 처음 보는 것이라 받는다');

      await h.advanceTo(const Duration(seconds: 20));
      await h.showCurrency('국내');
      expect(h.namu.holdingsCalls, [
        'KRW',
        'USD',
      ], reason: '국내는 20초 전에 받았다 — 탭을 오갔다고 또 받으면 안 된다');

      await h.advanceTo(const Duration(seconds: 45));
      await h.showCurrency('해외');
      expect(h.namu.holdingsCalls, [
        'KRW',
        'USD',
        'USD',
      ], reason: '해외는 35초 전에 받았다');

      await h.advanceTo(const Duration(seconds: 50));
      await h.showCurrency('국내');
      expect(h.namu.holdingsCalls, ['KRW', 'USD', 'USD', 'KRW']);
    });

    testWidgets('다시 받다 실패하면 보던 보유 종목을 그대로 두고, 다음에 돌아올 때 또 받는다', (tester) async {
      final h = await _pumpView(tester);
      expect(find.text('보유화학 1차'), findsOneWidget);

      // 돌아왔을 때의 조회가 실패한다.
      h.namu.failHoldings = true;
      await h.background();
      await h.advanceTo(const Duration(seconds: 31));
      await h.foreground();
      expect(h.namu.holdingsCalls, ['KRW', 'KRW']);
      expect(
        find.text('보유화학 1차'),
        findsOneWidget,
        reason: '실패 한 번으로 보유 종목이 "계좌가 없을 수 있어요" 로 바뀌었다',
      );
      expect(find.textContaining('보유 정보를 불러오지 못했어요'), findsNothing);

      // 바로 다시 돌아와도(30초가 안 됐어도) 또 받는다 — 방금 것은 실패였다.
      h.namu.failHoldings = false;
      await h.background();
      await h.advanceTo(const Duration(seconds: 35));
      await h.foreground();
      expect(h.namu.holdingsCalls, ['KRW', 'KRW', 'KRW']);
      expect(find.text('보유화학 3차'), findsOneWidget);
    });

    testWidgets('실패해도 몰아서 다시 치지 않고, 돌아오면 시각과 무관하게 다시 받는다', (tester) async {
      final h = await _pumpView(tester, failHoldings: true);
      expect(h.namu.holdingsCalls, ['KRW']);
      expect(find.textContaining('보유 정보를 불러오지 못했어요'), findsOneWidget);

      await h.advanceTo(const Duration(seconds: 20));
      expect(
        h.namu.holdingsCalls,
        ['KRW'],
        reason: '실패한 조회를 자동으로 다시 쳤다 — 429 를 맞은 순간에 열 번을 더 친다',
      );

      // 아직 30초가 안 됐지만 받아 둔 값이 없다 — 돌아오면 다시 물어야 한다.
      h.namu.failHoldings = false;
      await h.background();
      await h.foreground();

      expect(h.namu.holdingsCalls, ['KRW', 'KRW']);
      expect(find.textContaining('보유 정보를 불러오지 못했어요'), findsNothing);
    });
  });

  // ─── 판정 ───────────────────────────────────────────────────
  group('namuHoldingsStale', () {
    final fetchedAt = DateTime(2026, 9, 30, 9);

    test('받은 지 30초가 되기 전까지는 새 값이다', () {
      expect(
        namuHoldingsStale(
          fetchedAt,
          fetchedAt.add(const Duration(seconds: 29)),
        ),
        isFalse,
      );
    });

    test('정확히 30초면 낡았다 — 웹 react-query 와 같은 경계', () {
      expect(
        namuHoldingsStale(
          fetchedAt,
          fetchedAt.add(const Duration(seconds: 30)),
        ),
        isTrue,
      );
    });

    test('받은 적이 없으면 낡은 것이다', () {
      expect(namuHoldingsStale(null, fetchedAt), isTrue);
    });
  });

  test('박자는 웹 나무 화면과 같다', () {
    // 웹: WATCH_POLL_MS = 30_000 (NamuStocksPage) · staleTime: 30_000 (useNamuHoldings).
    // 앱에서 따로 줄이면 나무 유량 제한을 앱이 먼저 쓴다 — 바꿀 땐 웹과 같이 바꾼다.
    expect(namuPricePollInterval, const Duration(seconds: 30));
    expect(namuHoldingsStaleTime, const Duration(seconds: 30));
  });
}

// ─── 대역 ─────────────────────────────────────────────────────

const _stock = StockMasterItem(
  countryCode: 'KR',
  marketCode: 'KOSPI',
  symbol: '005930',
  nameKr: '테스트전자',
  securityType: 'STOCK',
  currency: 'KRW',
);

/// 나무 조회 대역 — **몇 번 불렸는지**만 센다. 부를 때마다 값이 달라진다.
class _CountingNamu extends NamuRepository {
  _CountingNamu() : super(Dio());

  /// 현재가를 물은 횟수.
  int priceCalls = 0;

  /// 보유 종목을 물은 통화, 물은 순서대로.
  final holdingsCalls = <String>[];

  bool failPrice = false;
  bool failHoldings = false;

  /// 잡혀 있으면 현재가 요청이 답을 못 받고 기다린다 — 느린 상류.
  Completer<void>? _heldPrice;

  void holdPrice() => _heldPrice = Completer<void>();

  void releasePrice() {
    _heldPrice?.complete();
    _heldPrice = null;
  }

  @override
  Future<BrokerPrice?> getKrPrice(String symbol, {String? marketCode}) async {
    priceCalls++;
    await _heldPrice?.future;
    if (failPrice) {
      throw ApiException(code: 'SEC_429', message: '유량 초과', statusCode: 429);
    }
    // 70000 → 71000 → 72000 … 다시 받았는지가 화면에서도 보인다.
    return BrokerPrice(
      symbol: symbol,
      price: 69000.0 + priceCalls * 1000,
      currency: 'KRW',
    );
  }

  @override
  Future<NamuHoldings> getHoldings({
    String? accountNo,
    String currency = 'KRW',
  }) async {
    holdingsCalls.add(currency);
    if (failHoldings) {
      throw ApiException(code: 'SEC_429', message: '유량 초과', statusCode: 429);
    }
    final nth = holdingsCalls.where((c) => c == currency).length;
    return NamuHoldings(
      accountNo: 'test-account',
      currency: currency,
      totalEvalAmount: '1000',
      totalProfitLoss: '10',
      profitRate: '1.0',
      items: [
        NamuHoldingItem(
          symbol: '000001',
          name: '보유화학 $nth차',
          quantity: '3',
          avgPrice: '300',
          currentPrice: '333',
          evalAmount: '1000',
          profitLoss: '10',
        ),
      ],
    );
  }
}

/// 보유 종목의 "받은 지" 를 재는 시계 — 가짜 시계와 같이 민다.
class _FakeClock {
  DateTime now = DateTime(2026, 9, 30, 9);
}

// ─── 하네스 ───────────────────────────────────────────────────

class _Harness {
  _Harness(this.tester, this.namu, this._clock, this._shown);
  final WidgetTester tester;
  final _CountingNamu namu;
  final _FakeClock _clock;
  final ValueNotifier<bool> _shown;

  /// 화면을 띄운 뒤 흐른 시간.
  Duration _elapsed = Duration.zero;

  /// 화면을 띄운 뒤 [sinceOpen] 이 될 때까지 시계를 민다 — 진짜로 기다리지 않는다.
  Future<void> advanceTo(Duration sinceOpen) async {
    assert(sinceOpen >= _elapsed, '이미 지난 시각이다');
    await _advance(sinceOpen - _elapsed);
  }

  Future<void> _advance(Duration d) async {
    _elapsed += d;
    _clock.now = _clock.now.add(d);
    await tester.pump(d);
    await _flush();
  }

  /// 검색해서 종목을 고른다 — 현재가 카드가 뜬다.
  Future<void> pickStock() async {
    await tester.enterText(find.byType(EditableText), '테스트');
    await _flush();
    await tapStock();
  }

  /// 검색 결과의 종목 행을 누른다(이미 고른 종목을 또 누를 때도 쓴다).
  Future<void> tapStock() async {
    await tester.tap(find.text(_stock.nameKr).last);
    await _flush();
  }

  /// 국내/해외 탭.
  Future<void> showCurrency(String label) async {
    await tester.tap(find.text(label));
    await _flush();
  }

  /// 화면을 닫는다(증권 화면에서 뒤로 가기).
  Future<void> close() async {
    _shown.value = false;
    await _flush();
  }

  /// 화면을 다시 연다.
  Future<void> open() async {
    _shown.value = true;
    await _flush();
  }

  /// 앱을 백그라운드로 — 엔진이 보내는 순서 그대로.
  Future<void> background() => _lifecycle(const [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]);

  /// 앱이 앞으로 돌아온다 — 역순.
  Future<void> foreground() => _lifecycle(const [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]);

  Future<void> _lifecycle(List<AppLifecycleState> states) async {
    for (final s in states) {
      await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
        'flutter/lifecycle',
        const StringCodec().encodeMessage(s.toString()),
        (_) {},
      );
      await tester.pump();
    }
    await _flush();
  }

  /// 조회 한 번은 `await` 를 몇 단계 거친다 — 시계는 안 밀고 프레임만 민다.
  /// `pumpAndSettle` 은 못 쓴다: 로딩 스켈레톤이 무한 애니메이션이라 안 끝난다.
  Future<void> _flush() async {
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }
}

Future<_Harness> _pumpView(
  WidgetTester tester, {
  bool failHoldings = false,
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);
  // 앞 테스트가 백그라운드로 보낸 채 끝났을 수 있다 — 매번 앞에서 시작한다.
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/lifecycle',
    const StringCodec().encodeMessage(AppLifecycleState.resumed.toString()),
    (_) {},
  );

  final namu = _CountingNamu()..failHoldings = failHoldings;
  final clock = _FakeClock();
  final shown = ValueNotifier(true);
  addTearDown(shown.dispose);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        namuRepositoryProvider.overrideWith((ref) async => namu),
        stockSearchProvider.overrideWith((ref, query) async => const [_stock]),
        freshnessClockProvider.overrideWith(
          (ref) =>
              () => clock.now,
        ),
      ],
      child: MaterialApp(
        theme: PorestTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('ko'),
        home: Scaffold(
          body: ValueListenableBuilder<bool>(
            valueListenable: shown,
            builder: (_, visible, _) =>
                visible ? const NamuStocksView() : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
  final h = _Harness(tester, namu, clock, shown);
  await h._flush();
  return h;
}
