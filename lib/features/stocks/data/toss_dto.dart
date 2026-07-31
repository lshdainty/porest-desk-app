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
    required this.purchaseAmount,
    required this.commission,
    required this.tax,
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

  /// 매입금액(원화) — marketValue.purchaseAmount
  final String purchaseAmount;

  /// 수수료 — cost.commission
  final String commission;

  /// 세금 — cost.tax
  final String tax;

  factory TossHoldingsItem.fromJson(Map<String, dynamic> j) {
    final mv = j['marketValue'] as Map<String, dynamic>?;
    final pl = j['profitLoss'] as Map<String, dynamic>?;
    final dpl = j['dailyProfitLoss'] as Map<String, dynamic>?;
    final cost = j['cost'] as Map<String, dynamic>?;
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
      purchaseAmount: (mv?['purchaseAmount'] as String?) ?? '0',
      commission: (cost?['commission'] as String?) ?? '0',
      tax: (cost?['tax'] as String?) ?? '0',
    );
  }

  double get quantityValue => double.tryParse(quantity) ?? 0;
  double get lastPriceValue => double.tryParse(lastPrice) ?? 0;
  double get marketValueAmountValue => double.tryParse(marketValueAmount) ?? 0;
  double get profitLossAmountValue => double.tryParse(profitLossAmount) ?? 0;
  double get profitLossRateValue => double.tryParse(profitLossRate) ?? 0;
  double get dailyProfitLossAmountValue =>
      double.tryParse(dailyProfitLossAmount) ?? 0;
  double get averagePurchasePriceValue =>
      double.tryParse(averagePurchasePrice) ?? 0;
  double get purchaseAmountValue => double.tryParse(purchaseAmount) ?? 0;
  double get feesValue =>
      (double.tryParse(commission) ?? 0) + (double.tryParse(tax) ?? 0);
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

// ── 캔들 (백엔드 TossMarketDto.Candle 미러) ───────────────────────────────

class TossCandle {
  const TossCandle({
    required this.timestamp,
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.closePrice,
    required this.volume,
  });
  final String timestamp;
  final String openPrice;
  final String highPrice;
  final String lowPrice;
  final String closePrice;
  final String volume;

  factory TossCandle.fromJson(Map<String, dynamic> j) => TossCandle(
        timestamp: (j['timestamp'] as String?) ?? '',
        openPrice: (j['openPrice'] as String?) ?? '0',
        highPrice: (j['highPrice'] as String?) ?? '0',
        lowPrice: (j['lowPrice'] as String?) ?? '0',
        closePrice: (j['closePrice'] as String?) ?? '0',
        volume: (j['volume'] as String?) ?? '0',
      );

  double get closeValue => double.tryParse(closePrice) ?? 0;
  double get volumeValue => double.tryParse(volume) ?? 0;
  DateTime? get time => DateTime.tryParse(timestamp);
}

/// 백엔드 candle 응답(porest-core `CursorResponse<Candle>`)을 내부 정규화 형태로 받는다.
/// content→candles, meta.nextCursor→nextBefore.
class TossCandlePage {
  const TossCandlePage({required this.candles, this.nextBefore});
  final List<TossCandle> candles;
  final String? nextBefore;

  factory TossCandlePage.fromJson(Map<String, dynamic> j) {
    final meta = j['meta'] as Map<String, dynamic>?;
    return TossCandlePage(
      candles: ((j['content'] as List?) ?? [])
          .map((e) => TossCandle.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextBefore: meta?['nextCursor'] as String?,
    );
  }
}

// ── 종목 기본정보 (백엔드 TossStockDto.StockInfo 미러) ─────────────────────

/// 국내 종목 전용 상세 (해외는 null).
class TossKrMarketDetail {
  const TossKrMarketDetail({
    required this.liquidationTrading,
    required this.nxtSupported,
    required this.krxTradingSuspended,
    required this.nxtTradingSuspended,
  });
  final bool liquidationTrading;
  final bool nxtSupported;
  final bool krxTradingSuspended;
  final bool nxtTradingSuspended;

  factory TossKrMarketDetail.fromJson(Map<String, dynamic> j) =>
      TossKrMarketDetail(
        liquidationTrading: (j['liquidationTrading'] as bool?) ?? false,
        nxtSupported: (j['nxtSupported'] as bool?) ?? false,
        krxTradingSuspended: (j['krxTradingSuspended'] as bool?) ?? false,
        nxtTradingSuspended: (j['nxtTradingSuspended'] as bool?) ?? false,
      );
}

class TossStockInfo {
  const TossStockInfo({
    required this.symbol,
    required this.name,
    required this.englishName,
    required this.market,
    required this.securityType,
    required this.status,
    required this.currency,
    required this.listDate,
    required this.sharesOutstanding,
    required this.koreanMarketDetail,
  });
  final String symbol;
  final String name;
  final String englishName;
  final String market;
  final String securityType;
  final String status;
  final String currency;
  final String? listDate;
  final String sharesOutstanding;
  final TossKrMarketDetail? koreanMarketDetail;

  factory TossStockInfo.fromJson(Map<String, dynamic> j) {
    final kr = j['koreanMarketDetail'];
    return TossStockInfo(
      symbol: (j['symbol'] as String?) ?? '',
      name: (j['name'] as String?) ?? '',
      englishName: (j['englishName'] as String?) ?? '',
      market: (j['market'] as String?) ?? '',
      securityType: (j['securityType'] as String?) ?? '',
      status: (j['status'] as String?) ?? '',
      currency: (j['currency'] as String?) ?? '',
      listDate: j['listDate'] as String?,
      sharesOutstanding: (j['sharesOutstanding'] as String?) ?? '0',
      koreanMarketDetail:
          kr is Map<String, dynamic> ? TossKrMarketDetail.fromJson(kr) : null,
    );
  }

  double get sharesValue => double.tryParse(sharesOutstanding) ?? 0;
  bool get isEtf => securityType.toUpperCase() == 'ETF';
  bool get isNormal => status.toUpperCase() == 'NORMAL';
}

// ── 매수 유의사항 (백엔드 TossStockDto.StockWarning 미러) ──────────────────

class TossStockWarning {
  const TossStockWarning({
    required this.warningType,
    this.exchange,
    this.startDate,
    this.endDate,
  });
  final String warningType;
  final String? exchange;
  final String? startDate;
  final String? endDate;

  factory TossStockWarning.fromJson(Map<String, dynamic> j) => TossStockWarning(
        warningType: (j['warningType'] as String?) ?? '',
        exchange: j['exchange'] as String?,
        startDate: j['startDate'] as String?,
        endDate: j['endDate'] as String?,
      );
}

// ── 상/하한가 (백엔드 TossMarketDto.PriceLimitResponse 미러) ───────────────

class TossPriceLimit {
  const TossPriceLimit({this.upperLimitPrice, this.lowerLimitPrice, this.currency});
  final String? upperLimitPrice;
  final String? lowerLimitPrice;
  final String? currency;

  factory TossPriceLimit.fromJson(Map<String, dynamic> j) => TossPriceLimit(
        upperLimitPrice: j['upperLimitPrice'] as String?,
        lowerLimitPrice: j['lowerLimitPrice'] as String?,
        currency: j['currency'] as String?,
      );

  double? get upperValue =>
      upperLimitPrice == null ? null : double.tryParse(upperLimitPrice!);
  double? get lowerValue =>
      lowerLimitPrice == null ? null : double.tryParse(lowerLimitPrice!);
}

// ── 장 운영 일정 (백엔드 TossMarketInfoDto 미러) ───────────────────────────

class TossMarketSession {
  const TossMarketSession({required this.startTime, required this.endTime});
  final String startTime;
  final String endTime;

  factory TossMarketSession.fromJson(Map<String, dynamic> j) =>
      TossMarketSession(
        startTime: (j['startTime'] as String?) ?? '',
        endTime: (j['endTime'] as String?) ?? '',
      );
}

class TossKrMarketDay {
  const TossKrMarketDay({required this.date, this.regularMarket});
  final String date;

  /// integrated.regularMarket (KRX+NXT 합집합 정규장). 휴장이면 null.
  final TossMarketSession? regularMarket;

  factory TossKrMarketDay.fromJson(Map<String, dynamic> j) {
    final integrated = j['integrated'] as Map<String, dynamic>?;
    final reg = integrated?['regularMarket'];
    return TossKrMarketDay(
      date: (j['date'] as String?) ?? '',
      regularMarket:
          reg is Map<String, dynamic> ? TossMarketSession.fromJson(reg) : null,
    );
  }
}

class TossKrMarketCalendar {
  const TossKrMarketCalendar({required this.today, this.nextBusinessDay});
  final TossKrMarketDay today;
  final TossKrMarketDay? nextBusinessDay;

  factory TossKrMarketCalendar.fromJson(Map<String, dynamic> j) {
    final next = j['nextBusinessDay'];
    return TossKrMarketCalendar(
      today: TossKrMarketDay.fromJson(
          (j['today'] as Map<String, dynamic>?) ?? const {}),
      nextBusinessDay: next is Map<String, dynamic>
          ? TossKrMarketDay.fromJson(next)
          : null,
    );
  }
}

class TossUsMarketDay {
  const TossUsMarketDay({required this.date, this.regularMarket});
  final String date;
  final TossMarketSession? regularMarket;

  factory TossUsMarketDay.fromJson(Map<String, dynamic> j) {
    final reg = j['regularMarket'];
    return TossUsMarketDay(
      date: (j['date'] as String?) ?? '',
      regularMarket:
          reg is Map<String, dynamic> ? TossMarketSession.fromJson(reg) : null,
    );
  }
}

class TossUsMarketCalendar {
  const TossUsMarketCalendar({required this.today, this.nextBusinessDay});
  final TossUsMarketDay today;
  final TossUsMarketDay? nextBusinessDay;

  factory TossUsMarketCalendar.fromJson(Map<String, dynamic> j) {
    final next = j['nextBusinessDay'];
    return TossUsMarketCalendar(
      today: TossUsMarketDay.fromJson(
          (j['today'] as Map<String, dynamic>?) ?? const {}),
      nextBusinessDay: next is Map<String, dynamic>
          ? TossUsMarketDay.fromJson(next)
          : null,
    );
  }
}

// ---- 랭킹 / 시장 지표 -------------------------------------------------------

/// 랭킹 종목 가격. changeRate 는 소수 비율(0.0125 = 1.25%).
class TossRankingPrice {
  const TossRankingPrice({required this.lastPrice, required this.basePrice, this.changeRate});
  final String lastPrice;
  final String basePrice;
  final String? changeRate;

  factory TossRankingPrice.fromJson(Map<String, dynamic> j) => TossRankingPrice(
        lastPrice: (j['lastPrice'] as String?) ?? '0',
        basePrice: (j['basePrice'] as String?) ?? '0',
        changeRate: j['changeRate'] as String?,
      );

  double get lastPriceValue => double.tryParse(lastPrice) ?? 0;
  double? get changePct {
    final r = changeRate == null ? null : double.tryParse(changeRate!);
    return r == null ? null : r * 100;
  }
}

class TossRankingItem {
  const TossRankingItem({
    required this.rank,
    required this.symbol,
    required this.currency,
    required this.price,
    required this.tradingVolume,
    required this.tradingAmount,
  });

  final int rank;
  final String symbol;
  final String currency;
  final TossRankingPrice price;
  final String tradingVolume;
  final String tradingAmount;

  factory TossRankingItem.fromJson(Map<String, dynamic> j) => TossRankingItem(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        symbol: (j['symbol'] as String?) ?? '',
        currency: (j['currency'] as String?) ?? 'KRW',
        price: TossRankingPrice.fromJson((j['price'] as Map<String, dynamic>?) ?? {}),
        tradingVolume: (j['tradingVolume'] as String?) ?? '0',
        tradingAmount: (j['tradingAmount'] as String?) ?? '0',
      );
}

class TossRankingResponse {
  const TossRankingResponse({this.rankedAt, required this.rankings});
  final String? rankedAt;
  final List<TossRankingItem> rankings;

  factory TossRankingResponse.fromJson(Map<String, dynamic> j) => TossRankingResponse(
        rankedAt: j['rankedAt'] as String?,
        rankings: ((j['rankings'] as List?) ?? [])
            .map((e) => TossRankingItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

/// 시장 지표 현재가 (지수: 포인트, 국채: 수익률 %). 토스 카탈로그 8종만 지원.
class TossIndicatorPrice {
  const TossIndicatorPrice({required this.symbol, required this.lastPrice, this.timestamp});
  final String symbol;
  final String lastPrice;
  final String? timestamp;

  factory TossIndicatorPrice.fromJson(Map<String, dynamic> j) => TossIndicatorPrice(
        symbol: (j['symbol'] as String?) ?? '',
        lastPrice: (j['lastPrice'] as String?) ?? '0',
        timestamp: j['timestamp'] as String?,
      );

  double get priceValue => double.tryParse(lastPrice) ?? 0;
}
