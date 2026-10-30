/// 증권 화면의 값 묶음 — 폰 화면과 상세 · 포트폴리오 페이지가 같은 셈을 쓴다(I-13 A.3).
///
/// 화면이 build 안에서 직접 셈하던 것을 꺼냈다. 금액은 숫자로 들고, 글로 만드는 일(원 · 달러 · 가리기)은
/// 화면이 한다. 웹 `pages/stocks/model/invest.ts` · `features/stock/lib/watch-prices.ts` 와 같은 셈이다.
library;

import 'package:groo_damda_app/core/format/format_locale.dart';
import 'package:groo_damda_app/core/format/krw.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';
import 'package:groo_damda_app/features/stocks/data/watch_dto.dart';
import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 증감 방향 — 좋고 나쁨이 아니라 오르내림이다(ds Delta 의 방향).
enum StockDirection { up, down, flat }

StockDirection directionOf(double n) => n > 0
    ? StockDirection.up
    : (n < 0 ? StockDirection.down : StockDirection.flat);

/// 소수 둘째 자리에서 0 으로 반올림되면 변화 없음으로 본다(0.004% 에 화살표를 달지 않는다).
StockDirection directionOfPct(double pct) =>
    directionOf((pct * 100).round() / 100);

// ---- 내 투자 요약 -----------------------------------------------------------

class InvestSummary {
  const InvestSummary({
    required this.evalAmount,
    required this.purchaseAmount,
    required this.pnl,
    required this.pnlPct,
    required this.dailyPnl,
    required this.dailyPnlPct,
    required this.count,
  });

  final int evalAmount;
  final int purchaseAmount;
  final int pnl;
  final double pnlPct;
  final int dailyPnl;
  final double dailyPnlPct;
  final int count;
}

/// 토스 보유 응답 → 요약. 서버가 센 원화 합계를 그대로 쓴다.
InvestSummary investSummaryOf(TossHoldings h) => InvestSummary(
  evalAmount: h.marketValueAmountValue.round(),
  purchaseAmount: h.totalPurchaseAmountValue.round(),
  pnl: h.profitLossAmountValue.round(),
  pnlPct: h.profitLossRateValue,
  dailyPnl: (double.tryParse(h.dailyProfitLossAmount) ?? 0).round(),
  dailyPnlPct: double.tryParse(h.dailyProfitLossRate) ?? 0,
  count: h.items.length,
);

// ---- 보유 줄 · 구성 -------------------------------------------------------------

/// 종목 금액을 원화로 — 원화 종목은 그대로, 달러는 환율을 곱한다. 환율이 없으면 null(Q5-A).
double? krwValueOf(TossHoldingsItem h, double? fxRate) {
  final v = h.marketValueAmountValue;
  if (h.currency.toUpperCase() == 'KRW' || h.currency.isEmpty) return v;
  if (h.currency.toUpperCase() == 'USD') {
    return (fxRate != null && fxRate > 0) ? v * fxRate : null;
  }
  return null;
}

/// 평가금액이 큰 순(원화 환산) — 환산 못 한 종목은 맨 뒤로 보낸다. 같으면 들어온 차례 그대로.
List<TossHoldingsItem> sortHoldings(
  List<TossHoldingsItem> items,
  double? fxRate,
) {
  final indexed = [for (var i = 0; i < items.length; i++) (i, items[i])];
  indexed.sort((a, b) {
    final va = krwValueOf(a.$2, fxRate);
    final vb = krwValueOf(b.$2, fxRate);
    if (va == null && vb == null) return a.$1.compareTo(b.$1);
    if (va == null) return 1;
    if (vb == null) return -1;
    final c = vb.compareTo(va);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  return [for (final e in indexed) e.$2];
}

class CompositionSlice {
  const CompositionSlice({
    required this.symbol,
    required this.name,
    required this.krwValue,
    required this.weightPct,
  });

  final String symbol;
  final String name;
  final double krwValue;
  final double weightPct;
}

/// 구성 비중 — 원화 환산으로 센다. 달러 종목이 있는데 환율이 없으면 null(도넛 대신 안내).
List<CompositionSlice>? compositionOf(
  List<TossHoldingsItem> items,
  double? fxRate,
) {
  final values = <(TossHoldingsItem, double)>[];
  for (final h in items) {
    final v = krwValueOf(h, fxRate);
    if (v == null) return null;
    if (v > 0) values.add((h, v));
  }
  final total = values.fold<double>(0, (s, e) => s + e.$2);
  if (total <= 0) return const [];
  values.sort((a, b) => b.$2.compareTo(a.$2));
  return [
    for (final e in values)
      CompositionSlice(
        symbol: e.$1.symbol,
        name: e.$1.name.isNotEmpty ? e.$1.name : e.$1.symbol,
        krwValue: e.$2,
        weightPct: e.$2 / total * 100,
      ),
  ];
}

// ---- 표기 --------------------------------------------------------------------

/// 통화별 가격 표기 — KRW=원화, USD=$ 소수 2자리, 그 외(CNY·JPY 등)=값+통화코드.
String fmtByCurrency(double price, String currency) {
  if (currency == 'USD') {
    final fixed = price.abs().toStringAsFixed(2);
    final dot = fixed.indexOf('.');
    final body =
        '${krw(int.parse(fixed.substring(0, dot)))}${fixed.substring(dot)}';
    return price < 0 ? '$kMinus\$$body' : '\$$body';
  }
  if (currency == 'KRW') return krwSigned(price.round(), false, unit: true);
  final cents = (price * 100).round();
  final whole = cents ~/ 100;
  final frac = (cents % 100).abs();
  final fracStr = frac == 0
      ? ''
      : (frac % 10 == 0
            ? '.${frac ~/ 10}'
            : '.${frac.toString().padLeft(2, '0')}');
  return '${krw(whole)}$fracStr $currency';
}

/// 지수 포인트 표기 — 천단위 구분 + 소수 2자리(뒤 0 은 생략). 통화 기호가 없다.
String fmtIndexPoint(double v) {
  final cents = (v * 100).round();
  final whole = cents ~/ 100;
  final frac = (cents % 100).abs();
  if (frac == 0) return krw(whole);
  return frac % 10 == 0
      ? '${krw(whole)}.${frac ~/ 10}'
      : '${krw(whole)}.${frac.toString().padLeft(2, '0')}';
}

/// 환율 표기 — "1,385.20원"(소수 둘째 자리 고정).
String fmtFxRate(double v) {
  final fixed = v.toStringAsFixed(2);
  final dot = fixed.indexOf('.');
  final whole = int.parse(fixed.substring(0, dot));
  final body = '${krw(whole)}${fixed.substring(dot)}';
  return localeIsEn() ? '₩$body' : '$body원';
}

/// 지수 이름 — 심볼로 찾고, 모르는 심볼이면 null(그리지 않는다. 다른 지표가 와도 "코스닥" 이 되지 않는다).
String? indexNameOf(AppLocalizations l, String symbol) => switch (symbol) {
  'KOSPI' => l.stockMarketKospi,
  'KOSDAQ' => l.stockMarketKosdaq,
  _ => null,
};

// ---- 관심 그룹 시세 호출 (I-13 22) --------------------------------------------

/// 서버 다건 시세 상한 — 토스는 코드에 상한이 없어 같은 값을 쓴다.
const int kPriceBatchMax = 50;

/// 보이는 그룹들의 심볼 — 겹침을 빼고 정렬한다.
List<String> visibleSymbols(List<StockWatchGroup> groups, Set<int> visibleIds) {
  final set = <String>{};
  for (final g in groups) {
    if (visibleIds.contains(g.rowId)) {
      for (final i in g.items) {
        set.add(i.symbol);
      }
    }
  }
  return set.toList()..sort();
}

/// 50 씩 나눈다.
List<List<String>> chunkSymbols(List<String> symbols, [int size = 50]) => [
  for (var i = 0; i < symbols.length; i += size)
    symbols.sublist(i, i + size > symbols.length ? symbols.length : i + size),
];

/// 체결 시각 — 서버 글("10:11:12" · "2026-10-29T13:00:05")의 시 · 분 · 초를 오전 · 오후 12시간으로("오후 1:00:05").
/// 읽을 수 없으면 받은 글 그대로. 체결 줄은 같은 분에 여러 건이라 초를 남긴다(DESIGN.md:3676 의 "초는 쓰지 않는다" 는
/// 체결 줄만 예외 — 스펙 몫으로 결과표에 질문).
String clock12WithSeconds(String raw) {
  final m = RegExp(r'(\d{1,2}):(\d{2}):(\d{2})').firstMatch(raw);
  if (m == null) return raw;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  final sec = m.group(3)!;
  if (h > 23 || min > 59) return raw;
  final h12 = h % 12 == 0 ? 12 : h % 12;
  final mm = m.group(2)!;
  return localeIsEn()
      ? '$h12:$mm:$sec ${h < 12 ? 'AM' : 'PM'}'
      : '${h < 12 ? '오전' : '오후'} $h12:$mm:$sec';
}
