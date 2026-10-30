// 나무 증권 모델(I-13 13-3) — 국내 · 해외 합치기, 환율 있고 없을 때의 정렬 · 합계 · 비중.
import 'package:flutter_test/flutter_test.dart';

import 'package:groo_damda_app/features/stocks/application/namu_model.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';

NamuHoldingItem item(String symbol, String eval, {String pnl = '0'}) =>
    NamuHoldingItem(
      symbol: symbol,
      name: symbol,
      quantity: '2',
      avgPrice: '10',
      currentPrice: '12',
      evalAmount: eval,
      profitLoss: pnl,
    );

NamuHoldings holdings(String currency, List<NamuHoldingItem> items) =>
    NamuHoldings(
      accountNo: 'a',
      currency: currency,
      totalEvalAmount: '0',
      totalProfitLoss: '0',
      profitRate: '0',
      items: items,
    );

void main() {
  final krw = holdings('KRW', [item('K1', '1000000'), item('K2', '3000000')]);
  final usd = holdings('USD', [item('U1', '5000', pnl: '500')]);

  test('환율이 있으면 원화 환산 큰 순으로 통화를 섞어 세운다', () {
    final v = mergeNamuHoldings(krw, usd, 1400);
    expect([for (final r in v.rows) r.symbol], ['U1', 'K2', 'K1']);
    expect(v.totalKrw, 1000000 + 3000000 + 5000 * 1400);
    expect(v.appliedFxRate, 1400);
    expect(v.fxMissing, isFalse);
    expect(v.mixed, isTrue);
  });

  test('환율이 없으면 국내 → 해외 묶음 안에서만 큰 순, 합계 · 비중은 내지 않는다', () {
    final v = mergeNamuHoldings(krw, usd, null);
    expect([for (final r in v.rows) r.symbol], ['K2', 'K1', 'U1']);
    expect(v.totalKrw, isNull);
    expect(v.fxMissing, isTrue);
    expect(namuCompositionOf(v), isNull);
  });

  test('해외가 없으면 환율이 없어도 국내 합계가 총액이다', () {
    final v = mergeNamuHoldings(krw, null, null);
    expect(v.totalKrw, 4000000);
    expect(v.fxMissing, isFalse);
    expect(v.mixed, isFalse);
    expect(namuCompositionOf(v)!.length, 2);
  });

  test('한쪽 조회가 실패해도(null) 남은 통화만 보인다', () {
    final v = mergeNamuHoldings(null, usd, 1400);
    expect(v.krw, isNull);
    expect(v.count, 1);
    expect(v.mixed, isFalse);
  });

  test('수익률은 매입금액 기준, 매입금액이 0 이하면 0', () {
    final r = mergeNamuHoldings(null, usd, 1400).rows.single;
    expect(r.costAmount, 4500);
    expect(r.returnPct, closeTo(500 / 4500 * 100, 1e-9));
    expect(
      mergeNamuHoldings(
        holdings('KRW', [item('Z', '0', pnl: '5')]),
        null,
        null,
      ).rows.single.returnPct,
      0,
    );
  });

  test('구성 비중은 원화 환산이고 합이 100 이다 — 달러 금액을 원 금액과 섞지 않는다', () {
    final comp = namuCompositionOf(mergeNamuHoldings(krw, usd, 1400))!;
    expect(comp.first.name, 'U1');
    expect(comp.first.krwValue, 7000000);
    expect(comp.fold<double>(0, (s, e) => s + e.weightPct), closeTo(100, 1e-9));
  });

  test('같은 코드가 두 통화에 있어도 줄 키가 겹치지 않는다', () {
    final v = mergeNamuHoldings(
      holdings('KRW', [item('X', '10')]),
      holdings('USD', [item('X', '10')]),
      1400,
    );
    expect({for (final r in v.rows) r.key}.length, 2);
  });
}
