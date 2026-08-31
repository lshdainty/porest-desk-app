/// 종목 마스터 DTO (백엔드 `/api/v1/stocks` — stock_master, KIS daily 동기화).
/// 국내(KOSPI/KOSDAQ/KONEX/업종지수) + 해외(미국·중국·일본·홍콩·베트남) 약 33,000종목.
library;

class StockMasterItem {
  const StockMasterItem({
    required this.countryCode,
    required this.marketCode,
    required this.symbol,
    required this.nameKr,
    required this.securityType,
    required this.currency,
    this.standardCode,
    this.nameEn,
  });

  /// KR, US, CN, JP, HK, VN
  final String countryCode;

  /// KOSPI, KOSDAQ, KONEX, KRX_IDX, NAS, NYS, AMS, SHS, SHI, SZS, SZI, TSE, HKS, HNX, HSX
  final String marketCode;
  final String symbol;
  final String nameKr;

  /// STOCK, ETF, INDEX, WARRANT
  final String securityType;
  final String currency;
  final String? standardCode;
  final String? nameEn;

  factory StockMasterItem.fromJson(Map<String, dynamic> j) => StockMasterItem(
    countryCode: (j['countryCode'] as String?) ?? '',
    marketCode: (j['marketCode'] as String?) ?? '',
    symbol: (j['symbol'] as String?) ?? '',
    nameKr: (j['nameKr'] as String?) ?? '',
    securityType: (j['securityType'] as String?) ?? '',
    currency: (j['currency'] as String?) ?? '',
    standardCode: j['standardCode'] as String?,
    nameEn: j['nameEn'] as String?,
  );
}
