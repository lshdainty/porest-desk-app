// 자산 화면 실시간 평가의 **시세 갱신** — 다시 받는지, 실패하면 어떻게 하는지.
//
// 2026-08-25 시세 조회를 `livePricesProvider` 한 곳으로 모은 뒤, 자산 화면의 10초 타이머는
// 평가 맵만 무효화했다. 시세 provider 는 스스로 비워지지 않아서 평가 맵은 **받아 둔 시세로
// 다시 계산**할 뿐이었고, 앱을 켤 때 받은 시세가 다시 켤 때까지 그대로였다(웹은 10초마다
// 다시 받는다). 측정: 60초 동안 시세 요청 1번.
//
// 그래서 여기서 세는 건 "무효화를 불렀다" 가 아니라 **시세 요청이 실제로 몇 번 나갔는가** 다.
// 실제 사슬(자산 → 평가 맵 → 시세 → 저장소)을 그대로 두고 맨 끝 저장소만 가짜로 바꾼다.
// 시간은 위젯 테스트의 가짜 시계로 민다(재시도 타이머까지 가짜 시계를 탄다).
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:porest_desk_app/features/asset/application/asset_providers.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/stocks/application/securities_providers.dart';
import 'package:porest_desk_app/features/stocks/data/securities_repository.dart';
import 'package:porest_desk_app/features/subscription/application/subscription_providers.dart';
import 'package:porest_desk_app/features/subscription/data/subscription_repository.dart';

const _tick = Duration(seconds: 10);
const _step = Duration(milliseconds: 100);

/// 시세 저장소 대역 — 부를 때마다 값이 100원씩 오른다(화면 값이 바뀌는지 보려고).
/// [failing] 이 참인 동안은 실패한다(토스가 거절하면 서버가 502 를 주는 모양 — 예외).
class _Prices extends SecuritiesRepository {
  _Prices() : super(Dio());

  bool failing = false;
  int calls = 0;
  int price = 70000;

  @override
  Future<List<BrokerQuote>> getPrices(List<String> symbols) async {
    calls++;
    if (failing) throw Exception('502 SEC_003');
    price += 100;
    // 전일 종가를 같이 준다 — 토스 사용자는 안 주면 캔들 경로로 가는데, 여기서 재려는
    // 것과 무관하고 그 경로는 쿠키 저장소를 물고 있다.
    return [
      BrokerQuote(
        symbol: '005930',
        price: price.toDouble(),
        currency: 'KRW',
        previousClose: 69000,
      ),
    ];
  }

  @override
  Future<double?> getExchangeRate({
    String base = 'USD',
    String quote = 'KRW',
  }) async => null;
}

/// 보유 10주 — 평가액 = 시세 × 10.
final _asset = Asset(
  rowId: 1,
  assetName: '주식 계좌',
  assetType: 'INVESTMENT',
  balance: 500000, // 서버에 저장된 잔액 — 시세를 못 받으면 이 값이 보인다
  holdings: const [
    AssetHolding(linked: true, tossSymbol: '005930', quantity: '10'),
  ],
);

class _Harness {
  _Harness(this.tester, this.container, this.prices);
  final WidgetTester tester;
  final ProviderContainer container;
  final _Prices prices;

  /// 화면이 보는 평가액. 시세를 못 받았으면 null(화면은 서버 잔액을 쓴다).
  int? get valuation =>
      container.read(investmentValuationMapProvider).value?[1]?.value;

  Future<void> advance(Duration d) async {
    for (var t = Duration.zero; t < d; t += _step) {
      await tester.pump(_step);
    }
  }

  /// 자산 화면 10초 주기가 하는 일 그대로.
  void refresh() => refreshLiveValuation(container.invalidate);
}

Future<_Harness> _start(WidgetTester tester) async {
  final prices = _Prices();
  final container = ProviderContainer(
    overrides: [
      myFeaturesProvider.overrideWith(
        (ref) async => const MyFeatures(
          features: ['SECURITIES'],
          connectedBrokers: ['TOSS'],
          primaryBroker: 'TOSS',
        ),
      ),
      assetsProvider.overrideWith((ref) async => [_asset]),
      securitiesRepositoryProvider.overrideWith((ref) async => prices),
    ],
  );
  addTearDown(container.dispose);
  container.listen(investmentValuationMapProvider, (_, _) {});
  final h = _Harness(tester, container, prices);
  await h.advance(_step);
  return h;
}

void main() {
  testWidgets('새로 고칠 때마다 시세를 다시 받아 평가액이 바뀐다', (tester) async {
    final h = await _start(tester);
    expect(h.prices.calls, 1);
    expect(h.valuation, 701000);

    for (var i = 1; i <= 3; i++) {
      h.refresh();
      await h.advance(_tick);
      expect(h.prices.calls, 1 + i, reason: '$i번째 10초 — 시세를 다시 받아야 한다');
    }
    expect(h.valuation, 704000, reason: '마지막으로 받은 시세(70,400 × 10)여야 한다');
  });

  testWidgets('평가 맵만 무효화하면 시세를 다시 받지 않는다 — 그래서 시세까지 민다', (tester) async {
    // riverpod 의 동작을 고정해 두는 테스트다. 이게 깨지면(=평가 맵만 밀어도 다시 받게 되면)
    // refreshLiveValuation 이 시세를 따로 밀 이유가 사라진 것이니 그때 다시 본다.
    final h = await _start(tester);

    for (var i = 0; i < 3; i++) {
      h.container.invalidate(investmentValuationMapProvider);
      await h.advance(_tick);
    }

    expect(
      h.prices.calls,
      1,
      reason: '평가 맵만 밀어서는 받아 둔 시세로 다시 계산할 뿐이다 — 이게 08-25 회귀의 원인이었다',
    );
  });

  testWidgets('실패하면 다시 조르지 않는다 — 다음 주기에 한 번만 부른다', (tester) async {
    final h = await _start(tester);
    h.prices.failing = true;

    h.refresh();
    await h.advance(_tick); // 이 10초 동안 riverpod 기본값이면 6번을 더 친다
    expect(h.prices.calls, 2, reason: '실패 뒤 다음 주기 전까지 재시도가 나가면 안 된다');

    h.refresh();
    await h.advance(_tick);
    h.refresh();
    await h.advance(_tick);
    expect(
      h.prices.calls,
      4,
      reason: '계속 실패해도 10초에 한 번이다(웹 retry: false 와 같다)',
    );
  });

  testWidgets('다시 받다 실패해도 직전 시세로 평가한다 — 서버 잔액으로 뛰지 않는다', (tester) async {
    final h = await _start(tester);
    expect(h.valuation, 701000);

    h.prices.failing = true;
    h.refresh();
    await h.advance(_tick);

    expect(h.prices.calls, 2);
    expect(
      h.valuation,
      701000,
      reason: '증권사가 한 번 거절했다고 평가액이 서버 잔액으로 바뀌면 10초마다 숫자가 뛴다',
    );
  });

  testWidgets('한 번도 못 받았으면 평가하지 않는다 — 화면은 서버 잔액을 쓴다', (tester) async {
    final prices = _Prices()..failing = true;
    final container = ProviderContainer(
      overrides: [
        myFeaturesProvider.overrideWith(
          (ref) async => const MyFeatures(
            features: ['SECURITIES'],
            connectedBrokers: ['TOSS'],
            primaryBroker: 'TOSS',
          ),
        ),
        assetsProvider.overrideWith((ref) async => [_asset]),
        securitiesRepositoryProvider.overrideWith((ref) async => prices),
      ],
    );
    addTearDown(container.dispose);
    container.listen(investmentValuationMapProvider, (_, _) {});
    await tester.pump(_step);

    expect(container.read(investmentValuationMapProvider).value, isEmpty);
  });

  testWidgets('잠깐 실패했다 회복하면 다음 주기에 돌아온다', (tester) async {
    final h = await _start(tester);
    h.prices.failing = true;
    h.refresh();
    await h.advance(_tick);
    expect(h.valuation, 701000, reason: '실패 동안은 직전 시세');

    h.prices.failing = false;
    h.refresh();
    await h.advance(_tick);

    expect(h.prices.calls, 3);
    expect(h.valuation, 702000, reason: '회복한 주기에 새 시세(70,200 × 10)로 돌아와야 한다');
  });
}
