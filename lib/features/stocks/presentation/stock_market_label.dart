/// 종목 마스터 · 토스 종목 정보의 시장 코드 → 사용자 말("NAS" 가 아니라 "나스닥"). 모르는 코드만 원문.
library;

import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

String stockMarketLabel(AppLocalizations l, String marketCode) =>
    switch (marketCode) {
      'KOSPI' => l.stockMarketKospi,
      'KOSDAQ' => l.stockMarketKosdaq,
      'KONEX' => l.stockMarketKonex,
      'KRX_IDX' => l.stockMarketKrxIdx,
      'NAS' || 'NASDAQ' => l.stockMarketNas,
      'NYS' || 'NYSE' => l.stockMarketNys,
      'AMS' || 'AMEX' => l.stockMarketAms,
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
