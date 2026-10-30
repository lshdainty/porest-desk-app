/// 나무 증권 화면의 값 묶음 — 폰 목록 · 상세 · 포트폴리오 페이지가 같은 셈을 쓴다(I-13 13-3).
///
/// 웹 `features/stock/lib/holdings.ts`(`mergeNamuHoldings`) · `pages/stocks/model/invest.ts`
/// (`namuInvestSummary` · `namuHoldingLines`)와 같은 셈이다. 금액은 숫자로 들고, 글로 만드는 일
/// (원 · 달러 · 가리기)은 화면이 한다.
library;

import 'package:groo_damda_app/features/stocks/application/stocks_model.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';

/// 통화 하나의 합계.
class NamuCurrencyTotal {
  const NamuCurrencyTotal({
    required this.currency,
    required this.evalAmount,
    required this.profitLoss,
    required this.profitRatePct,
    required this.count,
  });

  final String currency;
  final double evalAmount;
  final double profitLoss;
  final double profitRatePct;
  final int count;
}

/// 국내 · 해외 응답을 한 줄로 합친 보유 행 — 행이 자기 통화를 안다.
class NamuMergedHolding {
  const NamuMergedHolding({required this.item, required this.currency});

  final NamuHoldingItem item;
  final String currency;

  String get symbol => item.symbol;
  String get name => item.name.isNotEmpty ? item.name : item.symbol;
  double get quantity => double.tryParse(item.quantity) ?? 0;
  double get avgPrice => double.tryParse(item.avgPrice) ?? 0;
  double get currentPrice => double.tryParse(item.currentPrice) ?? 0;
  double get evalAmount => item.evalAmountValue;
  double get profitLoss => item.profitLossValue;
  double get costAmount => evalAmount - profitLoss;

  /// 수익률(%) — 매입금액이 0 이하면 0.
  double get returnPct => costAmount > 0 ? profitLoss / costAmount * 100 : 0;

  /// 목록 줄 키 — 같은 코드가 두 통화에 있어도 겹치지 않는다.
  String get key => '$currency:$symbol';
}

class NamuMergedView {
  const NamuMergedView({
    required this.rows,
    required this.krw,
    required this.usd,
    required this.totalKrw,
    required this.appliedFxRate,
    required this.fxMissing,
  });

  /// 합쳐진 보유 행 — 환율이 있으면 원화 환산 큰 순, 없으면 국내 → 해외 묶음 안에서만 큰 순.
  final List<NamuMergedHolding> rows;
  final NamuCurrencyTotal? krw;
  final NamuCurrencyTotal? usd;

  /// 원화 환산 총액 — 해외가 없으면 국내 합계, 해외가 있는데 환율이 없으면 null.
  final double? totalKrw;
  final double? appliedFxRate;

  /// 해외 보유가 있는데 환율이 없어 총액 · 비중을 못 낸 상태.
  final bool fxMissing;

  int get count => rows.length;
  bool get mixed => krw != null && usd != null;
}

NamuCurrencyTotal? _totalOf(List<NamuMergedHolding> rows, String currency) {
  if (rows.isEmpty) return null;
  final ev = rows.fold<double>(0, (s, r) => s + r.evalAmount);
  final pnl = rows.fold<double>(0, (s, r) => s + r.profitLoss);
  final cost = ev - pnl;
  return NamuCurrencyTotal(
    currency: currency,
    evalAmount: ev,
    profitLoss: pnl,
    profitRatePct: cost > 0 ? pnl / cost * 100 : 0,
    count: rows.length,
  );
}

/// 행의 원화 환산 평가금액 — 외화인데 환율이 없으면 0(정렬이 쓰는 척도).
double namuKrwValueOf(NamuMergedHolding r, double? fx) {
  if (r.currency == 'KRW') return r.evalAmount;
  return (fx != null && fx > 0) ? r.evalAmount * fx : 0;
}

/// 국내 · 해외 응답과 환율을 하나의 화면 모델로. 조회에 실패한 쪽은 null 을 넘긴다(남은 통화만 보인다).
NamuMergedView mergeNamuHoldings(
  NamuHoldings? krwHoldings,
  NamuHoldings? usdHoldings,
  double? fxRate,
) {
  List<NamuMergedHolding> rowsOf(NamuHoldings? h, String c) => [
    for (final i in h?.items ?? const <NamuHoldingItem>[])
      NamuMergedHolding(item: i, currency: c),
  ];
  final krwRows = rowsOf(krwHoldings, 'KRW');
  final usdRows = rowsOf(usdHoldings, 'USD');
  final krw = _totalOf(krwRows, 'KRW');
  final usd = _totalOf(usdRows, 'USD');
  final fx = (fxRate != null && fxRate.isFinite && fxRate > 0) ? fxRate : null;

  int byEvalDesc(NamuMergedHolding a, NamuMergedHolding b) =>
      b.evalAmount.compareTo(a.evalAmount);
  final rows = fx != null
      ? ([...krwRows, ...usdRows]..sort(
          (a, b) => namuKrwValueOf(b, fx).compareTo(namuKrwValueOf(a, fx)),
        ))
      : [
          ...(List.of(krwRows)..sort(byEvalDesc)),
          ...(List.of(usdRows)..sort(byEvalDesc)),
        ];

  final hasUsd = usd != null;
  final totalKrw = !hasUsd
      ? krw?.evalAmount
      : (fx != null ? (krw?.evalAmount ?? 0) + usd.evalAmount * fx : null);
  return NamuMergedView(
    rows: rows,
    krw: krw,
    usd: usd,
    totalKrw: totalKrw,
    appliedFxRate: hasUsd && fx != null ? fx : null,
    fxMissing: hasUsd && fx == null,
  );
}

/// 구성 비중 — 원화 환산으로 센다. 해외가 있는데 환율이 없으면 null(도넛 대신 안내).
List<CompositionSlice>? namuCompositionOf(NamuMergedView view) {
  if (view.fxMissing) return null;
  final values = <(NamuMergedHolding, double)>[];
  for (final r in view.rows) {
    final v = namuKrwValueOf(r, view.appliedFxRate);
    if (v > 0) values.add((r, v));
  }
  final total = values.fold<double>(0, (s, e) => s + e.$2);
  if (total <= 0) return const [];
  values.sort((a, b) => b.$2.compareTo(a.$2));
  return [
    for (final e in values)
      CompositionSlice(
        symbol: e.$1.key,
        name: e.$1.name,
        krwValue: e.$2,
        weightPct: e.$2 / total * 100,
      ),
  ];
}
