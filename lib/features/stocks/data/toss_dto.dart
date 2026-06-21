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

// ── 계좌 / 보유자산 (백엔드 TossAccountDto 미러) ──────────────────────────

/// 계좌. accountSeq 는 보유주식 조회 시 식별 키.
class TossAccount {
  const TossAccount({
    required this.accountNo,
    required this.accountSeq,
    required this.accountType,
  });
  final String accountNo;
  final int accountSeq;
  final String accountType;

  factory TossAccount.fromJson(Map<String, dynamic> j) => TossAccount(
        accountNo: (j['accountNo'] as String?) ?? '',
        accountSeq: (j['accountSeq'] as num).toInt(),
        accountType: (j['accountType'] as String?) ?? '',
      );
}

/// 통화별 금액 (원화 필수, 외화 nullable). 금액은 정밀도 보존 위해 String.
class TossAmount {
  const TossAmount({required this.krw, this.usd});
  final String krw;
  final String? usd;

  factory TossAmount.fromJson(Map<String, dynamic>? j) => TossAmount(
        krw: (j?['krw'] as String?) ?? '0',
        usd: j?['usd'] as String?,
      );

  double get krwValue => double.tryParse(krw) ?? 0;
}

/// 보유 종목 한 건 (서버가 평가·손익을 통화별로 계산해 내려줌).
class TossHoldingsItem {
  const TossHoldingsItem({
    required this.symbol,
    required this.name,
    required this.marketCountry,
    required this.currency,
    required this.quantity,
    required this.lastPrice,
    required this.averagePurchasePrice,
    required this.marketValueAmount,
    required this.profitLossAmount,
    required this.profitLossRate,
    required this.dailyProfitLossAmount,
    required this.dailyProfitLossRate,
  });

  final String symbol;
  final String name;
  final String marketCountry;
  final String currency;
  final String quantity;
  final String lastPrice;
  final String averagePurchasePrice;

  /// 평가금액(원화) — marketValue.amount.krw
  final String marketValueAmount;

  /// 평가손익(원화) — profitLoss.amount.krw
  final String profitLossAmount;

  /// 평가손익률(%) — profitLoss.rate
  final String profitLossRate;

  /// 일간손익(원화) — dailyProfitLoss.amount.krw
  final String dailyProfitLossAmount;
  final String dailyProfitLossRate;

  factory TossHoldingsItem.fromJson(Map<String, dynamic> j) {
    final mv = j['marketValue'] as Map<String, dynamic>?;
    final pl = j['profitLoss'] as Map<String, dynamic>?;
    final dpl = j['dailyProfitLoss'] as Map<String, dynamic>?;
    return TossHoldingsItem(
      symbol: (j['symbol'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      marketCountry: (j['marketCountry'] as String?) ?? '',
      currency: (j['currency'] as String?) ?? '',
      quantity: (j['quantity'] as String?) ?? '0',
      lastPrice: (j['lastPrice'] as String?) ?? '0',
      averagePurchasePrice: (j['averagePurchasePrice'] as String?) ?? '0',
      marketValueAmount: (mv?['amount'] as String?) ?? '0',
      profitLossAmount: (pl?['amount'] as String?) ?? '0',
      profitLossRate: (pl?['rate'] as String?) ?? '0',
      dailyProfitLossAmount: (dpl?['amount'] as String?) ?? '0',
      dailyProfitLossRate: (dpl?['rate'] as String?) ?? '0',
    );
  }

  double get quantityValue => double.tryParse(quantity) ?? 0;
  double get marketValueAmountValue => double.tryParse(marketValueAmount) ?? 0;
  double get profitLossAmountValue => double.tryParse(profitLossAmount) ?? 0;
  double get profitLossRateValue => double.tryParse(profitLossRate) ?? 0;
  double get averagePurchasePriceValue =>
      double.tryParse(averagePurchasePrice) ?? 0;
  bool get isUs => marketCountry.toUpperCase() == 'US' ||
      currency.toUpperCase() == 'USD';
}

/// 보유 자산 현황 (전체 요약 + 종목별 목록). 요약 금액은 통화별 Price{krw,usd}.
class TossHoldings {
  const TossHoldings({
    required this.totalPurchaseAmount,
    required this.marketValueAmount,
    required this.profitLossAmount,
    required this.profitLossRate,
    required this.dailyProfitLossAmount,
    required this.dailyProfitLossRate,
    required this.items,
  });

  /// 총매입금액(원화) — totalPurchaseAmount.krw
  final String totalPurchaseAmount;

  /// 총평가금액(원화) — marketValue.amount.krw
  final String marketValueAmount;

  /// 총평가손익(원화) — profitLoss.amount.krw
  final String profitLossAmount;
  final String profitLossRate;
  final String dailyProfitLossAmount;
  final String dailyProfitLossRate;
  final List<TossHoldingsItem> items;

  factory TossHoldings.fromJson(Map<String, dynamic> j) {
    final mv = j['marketValue'] as Map<String, dynamic>?;
    final pl = j['profitLoss'] as Map<String, dynamic>?;
    final dpl = j['dailyProfitLoss'] as Map<String, dynamic>?;
    String krwOf(Map<String, dynamic>? amountWrap, String key) {
      final amt = amountWrap?[key] as Map<String, dynamic>?;
      return (amt?['krw'] as String?) ?? '0';
    }

    final tpa = j['totalPurchaseAmount'] as Map<String, dynamic>?;
    return TossHoldings(
      totalPurchaseAmount: (tpa?['krw'] as String?) ?? '0',
      marketValueAmount: krwOf(mv, 'amount'),
      profitLossAmount: krwOf(pl, 'amount'),
      profitLossRate: (pl?['rate'] as String?) ?? '0',
      dailyProfitLossAmount: krwOf(dpl, 'amount'),
      dailyProfitLossRate: (dpl?['rate'] as String?) ?? '0',
      items: ((j['items'] as List?) ?? [])
          .map((e) => TossHoldingsItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  double get totalPurchaseAmountValue =>
      double.tryParse(totalPurchaseAmount) ?? 0;
  double get marketValueAmountValue => double.tryParse(marketValueAmount) ?? 0;
  double get profitLossAmountValue => double.tryParse(profitLossAmount) ?? 0;
  double get profitLossRateValue => double.tryParse(profitLossRate) ?? 0;
}
