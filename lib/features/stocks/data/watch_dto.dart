/// 증권 관심목록 DTO (백엔드 `/api/v1/stock-watch` — 서버 영속, 게이트 없음).
library;

class WatchItem {
  const WatchItem({
    required this.rowId,
    required this.stockMasterRowId,
    required this.countryCode,
    required this.marketCode,
    required this.symbol,
    required this.nameKr,
    required this.securityType,
    required this.currency,
    this.nameEn,
  });

  final int rowId;
  final int stockMasterRowId;
  final String countryCode;
  final String marketCode;
  final String symbol;
  final String nameKr;
  final String securityType;
  final String currency;
  final String? nameEn;

  factory WatchItem.fromJson(Map<String, dynamic> j) => WatchItem(
    rowId: (j['rowId'] as num).toInt(),
    stockMasterRowId: (j['stockMasterRowId'] as num).toInt(),
    countryCode: (j['countryCode'] as String?) ?? '',
    marketCode: (j['marketCode'] as String?) ?? '',
    symbol: (j['symbol'] as String?) ?? '',
    nameKr: (j['nameKr'] as String?) ?? '',
    securityType: (j['securityType'] as String?) ?? '',
    currency: (j['currency'] as String?) ?? '',
    nameEn: j['nameEn'] as String?,
  );
}

class StockWatchGroup {
  const StockWatchGroup({
    required this.rowId,
    required this.groupName,
    required this.sortOrder,
    required this.items,
  });

  final int rowId;
  final String groupName;
  final int sortOrder;
  final List<WatchItem> items;

  factory StockWatchGroup.fromJson(Map<String, dynamic> j) => StockWatchGroup(
    rowId: (j['rowId'] as num).toInt(),
    groupName: (j['groupName'] as String?) ?? '',
    sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
    items: ((j['items'] as List?) ?? [])
        .map((e) => WatchItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
