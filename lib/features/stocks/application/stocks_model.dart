/// 증권 화면의 값 묶음 — 폰 화면과 상세 · 포트폴리오 페이지가 같은 셈을 쓴다(I-13 A.3).
///
/// 화면이 build 안에서 직접 셈하던 것을 꺼냈다. 금액은 숫자로 들고, 글로 만드는 일(원 · 달러 · 가리기)은
/// 화면이 한다. 웹 `pages/stocks/model/invest.ts` · `features/stock/lib/watch-prices.ts` 와 같은 셈이다.
library;

import 'package:flutter/foundation.dart' show visibleForTesting;

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
  // 통화를 아직 모르면(응답 전) 숫자만 — "190원" 처럼 틀린 단위를 붙이지 않는다(M10)
  if (currency.isEmpty) {
    final cents = (price * 100).round();
    final frac = (cents % 100).abs();
    return frac == 0
        ? krw(cents ~/ 100)
        : '${krw(cents ~/ 100)}.${frac.toString().padLeft(2, '0')}';
  }
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

/// 체결 시각 — 서버 글을 오전 · 오후 12시간으로("오후 1:00"). **초는 쓰지 않는다**(DESIGN.md:3676).
/// 오프셋이 붙어 오면(`+09:00` · `-04:00` · `Z`) 순간으로 읽어 **한국 시각**으로, 없으면("10:11:12") 쓰인 벽시계 그대로.
/// 읽을 수 없으면 받은 글 그대로. 웹 `tradeClock` 과 같은 규칙.
String clock12Minutes(String raw) {
  String fmt(int h, int min) {
    final h12 = h % 12 == 0 ? 12 : h % 12;
    final mm = min.toString().padLeft(2, '0');
    return localeIsEn()
        ? '$h12:$mm ${h < 12 ? 'AM' : 'PM'}'
        : '${h < 12 ? '오전' : '오후'} $h12:$mm';
  }

  if (RegExp(r'(?:Z|[+-]\d{2}:?\d{2})$').hasMatch(raw)) {
    final inst = DateTime.tryParse(raw);
    if (inst != null) {
      final kst = inst.toUtc().add(const Duration(hours: 9));
      return fmt(kst.hour, kst.minute);
    }
  }
  final m = RegExp(r'(\d{1,2}):(\d{2})(?::\d{2})?').firstMatch(raw);
  if (m == null) return raw;
  final h = int.parse(m.group(1)!);
  final min = int.parse(m.group(2)!);
  if (h > 23 || min > 59) return raw;
  return fmt(h, min);
}

/// 전일 종가 — 토스 봉은 **최신순(timestamp 내림차순)** 이다(OpenAPI `/candles`: "배열의 첫 요소가 가장 최근 봉"). 순서를 믿지
/// 않고 봉 날짜로 정렬해, 그 시장의 "오늘"([marketToday])보다 앞선 가장 최근 봉의 종가를 돌려준다. 오프셋이 붙은 시각은 순간으로 읽어
/// 시장 날짜로 옮기고(웹 `prevCloseOf` 와 같은 규칙), 날짜뿐인 글은 그 날짜가 시장의 영업일이다. 전부 오늘 봉이면 null.
double? prevCloseFromCandles(
  List<TossCandle> candles,
  String marketToday, {
  String symbol = '',
}) {
  if (candles.isEmpty) return null;
  final keyed = [for (final c in candles) (candleDay(c.timestamp, symbol), c)]
    ..sort((a, b) => b.$1.compareTo(a.$1));
  for (final e in keyed) {
    if (e.$1.compareTo(marketToday) < 0) {
      final v = double.tryParse(e.$2.closePrice);
      return (v != null && v > 0) ? v : null;
    }
  }
  return null;
}

/// 오늘 시세의 오늘 봉 — **그 시장의 오늘**([marketToday])인 가장 최근 봉, 없으면 null(M11).
/// 기기 날짜가 아니라 시장 날짜로 견준다 — 미국 종목은 한국 0~5시(미국 장중)에 일봉 날짜가 현지 날짜라 기기 날짜와 어긋나
/// 시가 · 고가 · 저가 · 거래량 줄이 사라지던 것을 막는다. 봉 순서는 믿지 않는다(최신순으로 온다).
TossCandle? todayBarOf(
  List<TossCandle> candles,
  String symbol,
  DateTime nowUtc,
) {
  final today = marketToday(symbol, nowUtc);
  TossCandle? best;
  var bestKey = '';
  for (final c in candles) {
    final key = candleDay(c.timestamp, symbol);
    if (key == today && c.timestamp.compareTo(bestKey) >= 0) {
      best = c;
      bestKey = c.timestamp;
    }
  }
  return best;
}

/// 봉 하나의 시장 날짜 `YYYY-MM-DD` — 오프셋이 붙은 시각은 순간 → 시장 시간대 날짜, 아니면 앞 10자리.
String candleDay(String ts, String symbol) {
  if (RegExp(r'T.*(?:Z|[+-]\d{2}:?\d{2})$').hasMatch(ts)) {
    final inst = DateTime.tryParse(ts);
    if (inst != null) return _dateIn(symbol, inst.toUtc());
  }
  return ts.length >= 10 ? ts.substring(0, 10) : ts;
}

/// 미국 동부가 서머타임(EDT, UTC−4)인가 — **3월 둘째 일요일 02:00(표준시, 07:00 UTC) ~ 11월 첫째 일요일 02:00(EDT, 06:00 UTC)**.
/// 4~10월로 어림하면 3월 둘째 일요일 ~ 말일 · 11월 첫째 일요일 전에 현지 자정 봉(`T00:00:00-04:00`)이 전날로 밀린다(N2).
@visibleForTesting
bool isUsEasternDst(DateTime utc) {
  final u = utc.toUtc();
  DateTime nthSunday(int month, int n) {
    var d = DateTime.utc(u.year, month, 1);
    var count = 0;
    while (true) {
      if (d.weekday == DateTime.sunday && ++count == n) return d;
      d = d.add(const Duration(days: 1));
    }
  }

  final start = nthSunday(3, 2).add(const Duration(hours: 7));
  final end = nthSunday(11, 1).add(const Duration(hours: 6));
  return !u.isBefore(start) && u.isBefore(end);
}

String _dateIn(String symbol, DateTime utc) {
  final us = RegExp(r'^[A-Za-z]').hasMatch(symbol);
  final shift = us
      ? Duration(hours: isUsEasternDst(utc) ? -4 : -5)
      : const Duration(hours: 9);
  final d = utc.add(shift);
  String two(int n) => n.toString().padLeft(2, '0');
  return '${d.year}-${two(d.month)}-${two(d.day)}';
}

/// 그 시장의 오늘(`YYYY-MM-DD`) — 국내는 한국 날짜, 미국 심볼(영문으로 시작)은 동부 날짜(서머타임은 3월 둘째 일요일 ~ 11월 첫째 일요일 규칙으로
/// 계산한다). 한국 0~5시(미국 장중)에 오늘 봉을 전일로 읽지 않게 한다(H6).
String marketToday(String symbol, DateTime nowUtc) =>
    _dateIn(symbol, nowUtc.toUtc());

/// 전일 종가를 받아 둔 시장 날짜 중 **지금 시장 날짜와 달라진** 종목들(N3) — 앱을 끄지 않고 다음 날 보면 이 종목들의
/// 전일 종가는 어제 기준이다. 호출부(타이머 · 앱 복귀)가 이 종목들의 [prevCloseProvider] 를 비운다.
List<String> stalePrevCloseSymbols(
  Map<String, String> fetchedDay,
  DateTime nowUtc,
) => [
  for (final e in fetchedDay.entries)
    if (e.value != marketToday(e.key, nowUtc)) e.key,
];
