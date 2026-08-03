/// 종목 마스터 시장 코드 → 로케일 라벨 (웹 stocks:market.* 미러).
library;

import 'package:porest_desk_app/l10n/generated/app_localizations.dart';

String stockMarketLabel(AppLocalizations l, String marketCode) =>
    switch (marketCode) {
      'KOSPI' => l.stockMarketKospi,
      'KOSDAQ' => l.stockMarketKosdaq,
      'KONEX' => l.stockMarketKonex,
      'KRX_IDX' => l.stockMarketKrxIdx,
      'NAS' => l.stockMarketNas,
      'NYS' => l.stockMarketNys,
      'AMS' => l.stockMarketAms,
      'SHS' => l.stockMarketShs,
      'SHI' => l.stockMarketShi,
      'SZS' => l.stockMarketSzs,
      'SZI' => l.stockMarketSzi,
      'TSE' => l.stockMarketTse,
      'HKS' => l.stockMarketHks,
      'HNX' => l.stockMarketHnx,
      'HSX' => l.stockMarketHsx,
      _ => marketCode,
    };

/// 종목 유형 → 로케일 라벨 (웹 `securityType.*` 미러). ETF 는 그대로 노출한다.
String stockSecurityTypeLabel(AppLocalizations l, String securityType) =>
    switch (securityType) {
      'ETF' => 'ETF',
      'INDEX' => l.stockSecurityTypeIndex,
      'WARRANT' => l.stockSecurityTypeWarrant,
      _ => l.stocksInstrumentStock,
    };
