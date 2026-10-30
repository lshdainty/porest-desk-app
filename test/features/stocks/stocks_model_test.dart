// 증권 모델(I-13 A.3 · 22 · 11 · 9) — 화면이 아니라 셈만 잰다.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations_ko.dart';

TossHoldingsItem item(String symbol, String currency, String value) =>
    TossHoldingsItem(
      symbol: symbol,
      name: symbol,
      marketCountry: currency == 'USD' ? 'US' : 'KR',
      currency: currency,
      quantity: '1',
      lastPrice: value,
      averagePurchasePrice: value,
      marketValueAmount: value,
      profitLossAmount: '0',
      profitLossRate: '0',
      dailyProfitLossAmount: '0',
      dailyProfitLossRate: '0',
      purchaseAmount: value,
      commission: '0',
      tax: '0',
    );

StockWatchGroup group(int id, List<String> symbols) => StockWatchGroup(
  rowId: id,
  groupName: 'g$id',
  sortOrder: id,
  items: [
    for (final s in symbols)
      WatchItem(
        rowId: id * 100 + s.hashCode % 100,
        stockMasterRowId: 1,
        countryCode: 'KR',
        marketCode: 'KOSPI',
        symbol: s,
        nameKr: s,
        securityType: 'STOCK',
        currency: 'KRW',
      ),
  ],
);

void main() {
  test('미국 종목 금액은 달러 그대로, 원화는 원 — 환율이 있으면 원화로 환산해 줄 세운다(Q5-A)', () {
    expect(fmtByCurrency(6185.55, 'USD'), r'$6,185.55');
    expect(fmtByCurrency(8760000, 'KRW'), '8,760,000원');
    final items = [
      item('KR1', 'KRW', '1000000'),
      item('US1', 'USD', '6185.55'),
    ];
    // 환율 1385.2 → 달러 종목 8,568,... 원 > 1,000,000 원
    expect(sortHoldings(items, 1385.2).map((e) => e.symbol), ['US1', 'KR1']);
    // 환율이 없으면 환산 못 한 달러 종목은 맨 뒤
    expect(sortHoldings(items, null).map((e) => e.symbol), ['KR1', 'US1']);
  });

  test('구성 비중 — 원화 환산 합이 100, 환율 없이 달러 종목이 있으면 null', () {
    final items = [item('KR1', 'KRW', '1000000'), item('US1', 'USD', '1000')];
    final comp = compositionOf(items, 1500)!;
    expect(comp.map((e) => e.symbol), ['US1', 'KR1']);
    expect(comp.fold<double>(0, (s, e) => s + e.weightPct), closeTo(100, 1e-9));
    expect(compositionOf(items, null), isNull);
    expect(compositionOf([item('KR1', 'KRW', '5')], null), isNotNull);
  });

  test('모르는 지수 심볼은 이름이 없다 — "코스닥" 으로 나오지 않는다', () {
    final l = AppLocalizationsKo();
    expect(indexNameOf(l, 'KOSPI'), '코스피');
    expect(indexNameOf(l, 'KOSDAQ'), '코스닥');
    expect(indexNameOf(l, 'KR3Y'), isNull);
  });

  test('환율은 소수 둘째 자리 + 원', () {
    expect(fmtFxRate(1385.2), '1,385.20원');
  });

  test('관심 시세 — 보이는 그룹의 심볼만 합쳐 겹침을 빼고 정렬, 50 넘으면 50 씩 나눈다(22)', () {
    final groups = [
      group(1, ['B', 'A']),
      group(2, ['C', 'A']),
      group(3, ['Z']),
    ];
    expect(visibleSymbols(groups, {1, 2}), ['A', 'B', 'C']);
    expect(visibleSymbols(groups, {}), isEmpty);
    final many = [
      for (var i = 0; i < 120; i++) 'S${i.toString().padLeft(3, '0')}',
    ];
    final chunks = chunkSymbols(many);
    expect(chunks.map((c) => c.length), [50, 50, 20]);
  });

  test('Delta 방향 — 소수 둘째 자리에서 0 이면 변화 없음', () {
    expect(directionOfPct(0.004), StockDirection.flat);
    expect(directionOfPct(0.006), StockDirection.up);
    expect(directionOfPct(-12.3), StockDirection.down);
  });
}
