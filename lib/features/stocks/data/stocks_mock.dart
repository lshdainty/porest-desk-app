/// 증권 mock 데이터 — 토스증권 Open API 연동 전 단계의 정적 시세.
/// 웹 `pages/stocks/model/stocksMock.ts` 와 동일 데이터·시드 (앱↔웹 화면 정합).
/// 연동 시 이 모듈만 API repository 로 교체한다.
library;

import 'package:porest_desk_app/features/stocks/domain/stock.dart';

const double kFxUsdKrw = 1383.5;

/// 가벼운 의사난수 스파크라인 (종목별 고정 시드 — 렌더마다 동일)
List<double> _spark(int seed, {int n = 24, double drift = 0}) {
  final out = <double>[];
  var v = 100.0;
  var s = seed;
  for (var i = 0; i < n; i++) {
    s = (s * 9301 + 49297) % 233280;
    final r = s / 233280;
    v = v + (r - 0.5) * 6 + drift;
    out.add(v < 60 ? 60 : v);
  }
  return out;
}

/// 종목 마스터 — 검색·상세·관심·보유 공통 참조
final List<Stock> kStocks = [
  // 국내
  Stock(ticker: '005930', name: '삼성전자',    market: StockMarket.kr, sector: '반도체',  price: 73400,  changePct: 1.24,  spark: _spark(11, drift: 0.6),  marketCap: '438.2조', per: 13.2, eps: 5560,  high52: 88800,  low52: 49900,  vol: '12,840,221'),
  Stock(ticker: '000660', name: 'SK하이닉스',  market: StockMarket.kr, sector: '반도체',  price: 189500, changePct: 2.81,  spark: _spark(23, drift: 1.1),  marketCap: '137.9조', per: 8.6,  eps: 22010, high52: 248500, low52: 89000,  vol: '4,221,908'),
  Stock(ticker: '035420', name: 'NAVER',       market: StockMarket.kr, sector: '인터넷',  price: 168200, changePct: -0.71, spark: _spark(37, drift: -0.4), marketCap: '27.4조',  per: 18.9, eps: 8900,  high52: 232000, low52: 151900, vol: '512,773'),
  Stock(ticker: '035720', name: '카카오',      market: StockMarket.kr, sector: '인터넷',  price: 39850,  changePct: -1.36, spark: _spark(53, drift: -0.6), marketCap: '17.7조',  per: 41.2, eps: 967,   high52: 61900,  low52: 36050,  vol: '1,994,302'),
  Stock(ticker: '247540', name: '에코프로비엠', market: StockMarket.kr, sector: '2차전지', price: 142700, changePct: 4.62,  spark: _spark(71, drift: 1.6),  marketCap: '13.9조',  per: 55.4, eps: 2577,  high52: 296000, low52: 118400, vol: '1,338,540'),
  Stock(ticker: '069500', name: 'KODEX 200',   market: StockMarket.kr, sector: 'ETF',     price: 36120,  changePct: 0.83,  spark: _spark(89, drift: 0.4),  marketCap: '6.1조',   per: null, eps: null,  high52: 39400,  low52: 29980,  vol: '3,011,442'),
  // 해외 (USD)
  Stock(ticker: 'NVDA',  name: 'NVIDIA',    market: StockMarket.us, sector: '반도체',     price: 138.07, changePct: 3.41,  spark: _spark(101, drift: 1.4),  marketCap: r'$3.39T', per: 64.8, eps: 2.13,  high52: 153.13, low52: 47.32,  vol: '241.3M'),
  Stock(ticker: 'AAPL',  name: 'Apple',     market: StockMarket.us, sector: '하드웨어',   price: 227.48, changePct: 0.62,  spark: _spark(127, drift: 0.5),  marketCap: r'$3.44T', per: 34.6, eps: 6.57,  high52: 237.49, low52: 164.08, vol: '38.1M'),
  Stock(ticker: 'TSLA',  name: 'Tesla',     market: StockMarket.us, sector: '자동차',     price: 339.82, changePct: -2.14, spark: _spark(149, drift: -0.7), marketCap: r'$1.09T', per: 92.3, eps: 3.68,  high52: 414.5,  low52: 138.8,  vol: '74.9M'),
  Stock(ticker: 'MSFT',  name: 'Microsoft', market: StockMarket.us, sector: '소프트웨어', price: 423.46, changePct: 0.94,  spark: _spark(163, drift: 0.6),  marketCap: r'$3.15T', per: 36.1, eps: 11.73, high52: 468.35, low52: 362.9,  vol: '17.2M'),
  Stock(ticker: 'GOOGL', name: 'Alphabet',  market: StockMarket.us, sector: '인터넷',     price: 178.35, changePct: 1.52,  spark: _spark(181, drift: 0.8),  marketCap: r'$2.18T', per: 23.4, eps: 7.62,  high52: 191.75, low52: 127.9,  vol: '21.8M'),
  Stock(ticker: 'AMZN',  name: 'Amazon',    market: StockMarket.us, sector: '이커머스',   price: 207.89, changePct: 1.18,  spark: _spark(199, drift: 0.7),  marketCap: r'$2.18T', per: 44.7, eps: 4.65,  high52: 215.9,  low52: 144.05, vol: '33.4M'),
];

Stock? findStock(String ticker) {
  for (final s in kStocks) {
    if (s.ticker == ticker) return s;
  }
  return null;
}

/// 보유 종목 — 평균단가·수량 (평가액/손익은 화면에서 계산)
const List<StockHolding> kStockHoldings = [
  StockHolding(ticker: '005930', qty: 42, avg: 67200),
  StockHolding(ticker: '000660', qty: 8,  avg: 142800),
  StockHolding(ticker: '069500', qty: 30, avg: 33500),
  StockHolding(ticker: 'NVDA',   qty: 12, avg: 98.4),
  StockHolding(ticker: 'AAPL',   qty: 6,  avg: 191.2),
];

/// 관심종목 — 그룹별 (화면에서 복사해 로컬 상태로 사용)
const List<WatchGroup> kStockWatch = [
  WatchGroup(id: 'w-main', name: '관심',        tickers: ['035420', '035720', '247540', 'TSLA']),
  WatchGroup(id: 'w-us',   name: '미국 기술주', tickers: ['MSFT', 'GOOGL', 'AMZN', 'NVDA']),
];

// ---- 시세 계산 헬퍼 ----

/// 시세 원화 환산 (US는 환율 적용)
int priceKrw(Stock s) =>
    s.isUs ? (s.price * kFxUsdKrw).round() : s.price.round();

int holdingEval(StockHolding h) {
  final s = findStock(h.ticker);
  return s == null ? 0 : priceKrw(s) * h.qty;
}

int holdingCost(StockHolding h) {
  final s = findStock(h.ticker);
  if (s == null) return 0;
  final avgKrw = s.isUs ? (h.avg * kFxUsdKrw).round() : h.avg.round();
  return avgKrw * h.qty;
}
