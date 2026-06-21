/// 증권 도메인 모델 — 토스증권 Open API 연동 전 단계.
/// 연동 시 응답 DTO 를 이 모델로 매핑하면 화면은 그대로 재사용한다.
library;

enum StockMarket { kr, us }

class Stock {
  // const 아님 — 토스 Open API 연동 시 [price] 를 in-place 갱신(라이브 시세 오버레이).
  Stock({
    required this.ticker,
    required this.name,
    required this.market,
    required this.sector,
    required this.price,
    required this.changePct,
    required this.spark,
    required this.marketCap,
    required this.per,
    required this.eps,
    required this.high52,
    required this.low52,
    required this.vol,
  });

  final String ticker;
  final String name;
  final StockMarket market;
  final String sector;

  /// KR=원, US=달러. 라이브 시세 적용 시 갱신(mutable).
  double price;
  final double changePct;
  final List<double> spark;
  final String marketCap;
  final double? per;
  final double? eps;
  final double high52;
  final double low52;
  final String vol;

  bool get isUs => market == StockMarket.us;
}

class StockHolding {
  const StockHolding({
    required this.ticker,
    required this.qty,
    required this.avg,
  });

  final String ticker;
  final int qty;

  /// 평균단가 — KR=원, US=달러
  final double avg;
}

class WatchGroup {
  const WatchGroup({
    required this.id,
    required this.name,
    required this.tickers,
  });

  final String id;
  final String name;
  final List<String> tickers;

  WatchGroup copyWith({List<String>? tickers}) =>
      WatchGroup(id: id, name: name, tickers: tickers ?? this.tickers);
}

/// 시장 지수 — 상단 스트립 (토스증권 Market Info 가정)
class MarketIndex {
  const MarketIndex({
    required this.id,
    required this.name,
    required this.value,
    required this.changePct,
    required this.spark,
  });

  final String id;
  final String name;
  final double value;
  final double changePct;
  final List<double> spark;
}

/// 일별 시세 — 종목 상세 표 한 행
class DailyQuote {
  const DailyQuote({
    required this.date,
    required this.close,
    required this.chg,
    required this.vol,
  });

  final String date;
  final double close;

  /// 전일 대비 등락률 (%)
  final double chg;

  /// 거래량 — US는 백만(M) 단위
  final double vol;
}
