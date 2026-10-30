/// 증권사별 구역(I-13b 13b-1)의 응답 모양 — 나무 종목 상세 시세 · 체결 · 투자자별 · 주문 가능 금액.
///
/// **문서대로 구현하고 나중에 실응답으로 고친다**(사용자 10-23) — 그래서 모든 칸이 null 을 받는다.
/// 서버가 숫자를 문자열로 내리지만(정밀도), 혹시 숫자로 와도 깨지지 않게 `'$v'` 로 읽는다.
/// 빈 문자열은 null 로 본다(값 없는 줄은 화면이 그리지 않는다).
library;

import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';

String? _s(Object? v) {
  if (v == null) return null;
  final t = '$v'.trim();
  return t.isEmpty ? null : t;
}

double? _d(Object? v) {
  final t = _s(v);
  return t == null ? null : double.tryParse(t);
}

/// 나무 종목 상세 시세 — 서버 `GET /namu/{kr|gb}/quote`(NamuQuoteDto.Detail).
/// 머리 · 오늘 시세 · 호가 · 경고 · 기본 정보가 한 응답이다.
class NamuQuoteDetail {
  const NamuQuoteDetail({
    this.symbol,
    this.name,
    this.currency,
    this.price,
    this.previousClose,
    this.open,
    this.high,
    this.low,
    this.volume,
    this.upperLimit,
    this.lowerLimit,
    this.orderbook,
    this.warnings = const [],
    this.marketState,
    this.sector,
    this.marketCap,
    this.listingDate,
    this.listedShares,
  });

  final String? symbol;
  final String? name;
  final String? currency;
  final double? price;
  final double? previousClose;
  final double? open;
  final double? high;
  final double? low;
  final double? volume;
  final double? upperLimit;
  final double? lowerLimit;
  final TossOrderbook? orderbook;

  /// 토스 `StockWarning.warningType` 어휘 그대로(서버가 옮긴다).
  final List<String> warnings;
  final String? marketState;
  final String? sector;

  /// 시가총액 — **원 단위**(서버가 억원을 원으로 바꿔 내린다).
  final double? marketCap;
  final String? listingDate;
  final double? listedShares;

  /// 오늘 시세 여섯 줄 중 하나라도 있나 — 없으면 띠를 그리지 않는다.
  bool get hasToday =>
      open != null ||
      high != null ||
      low != null ||
      volume != null ||
      upperLimit != null ||
      lowerLimit != null;

  factory NamuQuoteDetail.fromJson(Map<String, dynamic> j) {
    double? pos(Object? v) {
      final d = _d(v);
      return (d == null || d <= 0) ? null : d;
    }

    return NamuQuoteDetail(
      symbol: _s(j['symbol']),
      name: _s(j['name']),
      currency: _s(j['currency']),
      price: pos(j['price']),
      previousClose: pos(j['previousClose']),
      open: pos(j['open']),
      high: pos(j['high']),
      low: pos(j['low']),
      volume: _d(j['volume']),
      upperLimit: pos(j['upperLimit']),
      lowerLimit: pos(j['lowerLimit']),
      orderbook: _orderbook(j['orderbook']),
      warnings: [
        for (final w in (j['warnings'] as List?) ?? const [])
          if (w is Map && _s(w['warningType']) != null) _s(w['warningType'])!,
      ],
      marketState: _s(j['marketState']),
      sector: _s(j['sector']),
      marketCap: pos(j['marketCap']),
      listingDate: _s(j['listingDate']),
      listedShares: pos(j['listedShares']),
    );
  }

  static TossOrderbook? _orderbook(Object? raw) {
    if (raw is! Map) return null;
    List<TossOrderbookEntry> side(Object? v) => [
      for (final e in (v as List?) ?? const [])
        if (e is Map && _s(e['price']) != null)
          TossOrderbookEntry(
            price: _s(e['price'])!,
            volume: _s(e['volume']) ?? '0',
          ),
    ];
    final asks = side(raw['asks']);
    final bids = side(raw['bids']);
    if (asks.isEmpty && bids.isEmpty) return null;
    return TossOrderbook(asks: asks, bids: bids, currency: _s(raw['currency']));
  }
}

/// 나무 목록 시세 — 서버 `GET /namu/prices`(NamuQuoteDto.ListQuote). 장 상태가 딸려 온다.
class NamuListQuote {
  const NamuListQuote({
    required this.symbol,
    required this.price,
    required this.currency,
    this.previousClose,
    this.marketState,
  });
  final String symbol;
  final double price;
  final String currency;
  final double? previousClose;
  final String? marketState;

  factory NamuListQuote.fromJson(Map<String, dynamic> j) => NamuListQuote(
    symbol: _s(j['symbol']) ?? '',
    price: _d(j['price']) ?? 0,
    currency: _s(j['currency']) ?? 'KRW',
    previousClose: _d(j['previousClose']),
    marketState: _s(j['marketState']),
  );
}

/// 투자자별 매매동향 하루 — 두 증권사가 같은 모양이다(순매수 주, 개인이 null 일 수 있다).
class InvestorTradingDay {
  const InvestorTradingDay({
    required this.date,
    this.individual,
    this.foreigner,
    this.institution,
  });
  final String date;
  final double? individual;
  final double? foreigner;
  final double? institution;

  factory InvestorTradingDay.fromJson(Map<String, dynamic> j) =>
      InvestorTradingDay(
        date: _s(j['date']) ?? '',
        individual: _d(j['individual']),
        foreigner: _d(j['foreigner']),
        institution: _d(j['institution']),
      );
}

/// 주문 가능 금액 한 줄 — 토스 `buying-power`(`cashBuyingPower`) · 나무 `margin`(`foreignDeposit`).
class BuyingPower {
  const BuyingPower({required this.currency, this.amount});
  final String currency;
  final double? amount;
}

/// 나무 체결 한 건 — 토스 `Trade` 와 같은 이름으로 내려오므로 [TossTrade] 로 옮긴다.
List<TossTrade> tradesFromJson(Object? raw) => [
  for (final e in (raw as List?) ?? const [])
    if (e is Map && _s(e['price']) != null)
      TossTrade(
        price: _s(e['price'])!,
        volume: _s(e['volume']) ?? '0',
        timestamp: _s(e['timestamp']) ?? '',
      ),
];

List<InvestorTradingDay> investorDaysFromJson(Object? raw) => [
  for (final e in (raw as List?) ?? const [])
    if (e is Map<String, dynamic>) InvestorTradingDay.fromJson(e),
];
