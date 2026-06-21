/// 토스증권 Open API 응답 DTO (백엔드 조회 프록시 `/api/v1/toss/**` 응답 미러).
/// 가격·수량은 백엔드가 정밀도 보존 위해 String 으로 내려주므로 그대로 String 으로 받는다.
library;

class TossPrice {
  const TossPrice({required this.symbol, required this.lastPrice, this.currency});
  final String symbol;
  final String lastPrice;
  final String? currency;

  factory TossPrice.fromJson(Map<String, dynamic> j) => TossPrice(
        symbol: j['symbol'] as String,
        lastPrice: j['lastPrice'] as String,
        currency: j['currency'] as String?,
      );

  double get priceValue => double.tryParse(lastPrice) ?? 0;
}

class TossOrderbookEntry {
  const TossOrderbookEntry({required this.price, required this.volume});
  final String price;
  final String volume;

  factory TossOrderbookEntry.fromJson(Map<String, dynamic> j) => TossOrderbookEntry(
        price: j['price'] as String,
        volume: j['volume'] as String,
      );

  double get priceValue => double.tryParse(price) ?? 0;
  double get volumeValue => double.tryParse(volume) ?? 0;
}

class TossOrderbook {
  const TossOrderbook({required this.asks, required this.bids, this.currency});
  final List<TossOrderbookEntry> asks;
  final List<TossOrderbookEntry> bids;
  final String? currency;

  factory TossOrderbook.fromJson(Map<String, dynamic> j) => TossOrderbook(
        asks: ((j['asks'] as List?) ?? [])
            .map((e) => TossOrderbookEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        bids: ((j['bids'] as List?) ?? [])
            .map((e) => TossOrderbookEntry.fromJson(e as Map<String, dynamic>))
            .toList(),
        currency: j['currency'] as String?,
      );
}

class TossTrade {
  const TossTrade({required this.price, required this.volume, required this.timestamp});
  final String price;
  final String volume;
  final String timestamp;

  factory TossTrade.fromJson(Map<String, dynamic> j) => TossTrade(
        price: j['price'] as String,
        volume: j['volume'] as String,
        timestamp: (j['timestamp'] as String?) ?? '',
      );

  double get priceValue => double.tryParse(price) ?? 0;
  double get volumeValue => double.tryParse(volume) ?? 0;
}

class TossExchangeRate {
  const TossExchangeRate({required this.rate, this.baseCurrency, this.quoteCurrency});
  final String rate;
  final String? baseCurrency;
  final String? quoteCurrency;

  factory TossExchangeRate.fromJson(Map<String, dynamic> j) => TossExchangeRate(
        rate: j['rate'] as String,
        baseCurrency: j['baseCurrency'] as String?,
        quoteCurrency: j['quoteCurrency'] as String?,
      );

  double get rateValue => double.tryParse(rate) ?? 0;
}
