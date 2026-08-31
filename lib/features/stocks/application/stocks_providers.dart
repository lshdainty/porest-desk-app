/// 토스증권 Open API 연동 Riverpod providers.
/// 모든 provider 는 에러(키 미설정 503·미기동)를 삼키고 null/빈 값으로 폴백한다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_repository.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';
import 'package:porest_desk_app/features/stocks/data/watch_dto.dart';

final stocksRepositoryProvider = FutureProvider<StocksRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return StocksRepository(dio);
});

/// 여러 종목 현재가 (콤마 조인 심볼 키 — 리스트 배치 1콜). 에러 시 빈 목록.
final tossPricesProvider = FutureProvider.family<List<TossPrice>, String>((
  ref,
  joinedSymbols,
) async {
  if (joinedSymbols.isEmpty) return const [];
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getPrices(joinedSymbols.split(','));
  } catch (_) {
    return const [];
  }
});

/// USD→KRW 환율. 에러/미설정 시 null.
final tossExchangeRateProvider = FutureProvider<TossExchangeRate?>((ref) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getExchangeRate();
  } catch (_) {
    return null;
  }
});

/// 전일 종가. 토스 /prices 엔 기준가·등락률이 없어 일봉으로 도출한다.
/// 오늘 날짜 캔들을 제외한 마지막 종가 = 전일 종가 (장 시작 전이면 마지막 캔들이 곧 전일).
final prevCloseProvider = FutureProvider.family<double?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    final page = await repo.getCandles(symbol, '1d', count: 3);
    if (page.candles.isEmpty) return null;
    final today = DateTime.now().toIso8601String().substring(0, 10);
    for (final c in page.candles.reversed) {
      if (!c.timestamp.startsWith(today)) {
        final v = double.tryParse(c.closePrice);
        return (v != null && v > 0) ? v : null;
      }
    }
    final v = double.tryParse(page.candles.first.closePrice);
    return (v != null && v > 0) ? v : null;
  } catch (_) {
    return null;
  }
});

/// 등락률(%) = (현재가 − 전일종가) / 전일종가. 어느 한쪽이 없으면 null.
double? changePctOf(double? lastPrice, double? prevClose) {
  if (lastPrice == null || prevClose == null || prevClose <= 0) return null;
  return (lastPrice - prevClose) / prevClose * 100;
}

/// 주식 랭킹 (발견 탭). 키 = "type|marketCountry|duration". 에러 시 빈 랭킹.
final tossRankingsProvider = FutureProvider.family<TossRankingResponse, String>(
  (ref, key) async {
    final parts = key.split('|');
    try {
      final repo = await ref.watch(stocksRepositoryProvider.future);
      return await repo.getRankings(
        type: parts[0],
        marketCountry: parts[1],
        duration: parts[2],
      );
    } catch (_) {
      return const TossRankingResponse(rankings: []);
    }
  },
);

/// 국내 지수 현재가 (KOSPI·KOSDAQ). 에러 시 빈 목록.
final tossIndicatorPricesProvider = FutureProvider<List<TossIndicatorPrice>>((
  ref,
) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getIndicatorPrices(const ['KOSPI', 'KOSDAQ']);
  } catch (_) {
    return const [];
  }
});

/// 관심목록 (서버 stock-watch). 에러 시 빈 목록 — 화면은 빈 상태 표시.
final watchGroupsProvider = FutureProvider<List<StockWatchGroup>>((ref) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getWatchGroups();
  } catch (_) {
    return const [];
  }
});

/// 종목 호가 (라이브). 에러/미설정 시 null → 호가창 빈 상태 (mock 폴백 없음).
final tossOrderbookProvider = FutureProvider.family<TossOrderbook?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getOrderbook(symbol);
  } catch (_) {
    return null;
  }
});

/// 종목 체결 내역 (라이브). 에러/미설정 시 null → 체결 테이프 빈 상태 (mock 폴백 없음).
final tossTradesProvider = FutureProvider.family<List<TossTrade>?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getTrades(symbol);
  } catch (_) {
    return null;
  }
});

/// 증권 계좌 목록 (개인 키). 키 미등록/미설정/에러 시 null → 화면은 '연결 유도' 빈 상태.
final tossAccountsProvider = FutureProvider<List<TossAccount>?>((ref) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getAccounts();
  } catch (_) {
    return null;
  }
});

/// 보유 자산 현황 (첫 계좌 기준). 계좌 없음/키 미등록/에러 시 null → 빈 상태.
/// 시세 mock 폴백과 달리 보유는 mock 미사용(키 없으면 연결 유도).
final tossHoldingsProvider = FutureProvider<TossHoldings?>((ref) async {
  final accounts = await ref.watch(tossAccountsProvider.future);
  if (accounts == null || accounts.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getHoldings(accounts.first.accountSeq);
  } catch (_) {
    return null;
  }
});

/// 캔들(차트·일별시세·등락률 실산출). interval '1m'(1D) / '1d'(장기).
/// 에러/미설정 시 null → 차트 빈 상태(의사난수 폴백 없음).
typedef CandleArg = ({String symbol, String interval});
final tossCandlesProvider = FutureProvider.family<TossCandlePage?, CandleArg>((
  ref,
  arg,
) async {
  if (arg.symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    // 토스 count 상한 200 초과는 repository 가 before 커서로 페이지네이션.
    final count = arg.interval == '1m' ? 390 : 252;
    return await repo.getCandles(arg.symbol, arg.interval, count: count);
  } catch (_) {
    return null;
  }
});

/// 종목 기본정보(시장/유형/통화/상장일/발행주식수/거래상태). 에러/미설정 시 null.
final tossStockInfoProvider = FutureProvider.family<TossStockInfo?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    final list = await repo.getStocks([symbol]);
    return list.isEmpty ? null : list.first;
  } catch (_) {
    return null;
  }
});

/// 매수 유의사항. 에러/미설정/없음 시 빈 목록.
final tossWarningsProvider =
    FutureProvider.family<List<TossStockWarning>, String>((ref, symbol) async {
      if (symbol.isEmpty) return const [];
      try {
        final repo = await ref.watch(stocksRepositoryProvider.future);
        return await repo.getStockWarnings(symbol);
      } catch (_) {
        return const [];
      }
    });

/// 상/하한가(국내). 에러/미설정/해외 시 null.
final tossPriceLimitsProvider = FutureProvider.family<TossPriceLimit?, String>((
  ref,
  symbol,
) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getPriceLimits(symbol);
  } catch (_) {
    return null;
  }
});

/// 국내 장 운영 일정. 에러/미설정 시 null.
final tossMarketCalendarKrProvider = FutureProvider<TossKrMarketCalendar?>((
  ref,
) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getMarketCalendarKr();
  } catch (_) {
    return null;
  }
});

/// 미국 장 운영 일정. 에러/미설정 시 null.
final tossMarketCalendarUsProvider = FutureProvider<TossUsMarketCalendar?>((
  ref,
) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getMarketCalendarUs();
  } catch (_) {
    return null;
  }
});

/// 종목 마스터 검색 (서버 stock_master — 국내 + 해외 6개국). 검색어별 캐시.
/// 에러(미기동 등) 시 빈 목록 → 화면은 코드 직접입력 폴백으로 동작.
final stockSearchProvider =
    FutureProvider.family<List<StockMasterItem>, String>((ref, query) async {
      final q = query.trim();
      if (q.isEmpty) return const [];
      try {
        final repo = await ref.watch(stocksRepositoryProvider.future);
        return await repo.searchStocks(q);
      } catch (_) {
        return const [];
      }
    });

/// 심볼 → 한글 종목명 (연결된 종목 표시용). 심볼 정확 일치만 취하고 없으면 null.
/// 국내 005930 과 상해 600519 처럼 시장 간 심볼이 겹칠 수 있어 토스 시세 대상(KR/US)을 우선한다.
final stockSymbolNameProvider = FutureProvider.family<String?, String>((
  ref,
  symbol,
) async {
  final sym = symbol.trim();
  if (sym.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    final items = await repo.searchStocks(sym, size: 20);
    final exact = items
        .where((s) => s.symbol.toUpperCase() == sym.toUpperCase())
        .toList();
    if (exact.isEmpty) return null;
    for (final s in exact) {
      if (s.countryCode == 'KR' || s.countryCode == 'US') return s.nameKr;
    }
    return exact.first.nameKr;
  } catch (_) {
    return null;
  }
});
