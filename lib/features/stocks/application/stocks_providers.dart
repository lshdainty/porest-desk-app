/// 토스증권 Open API 연동 Riverpod providers.
/// 모든 provider 는 에러(키 미설정 503·미기동)를 삼키고 null/false 로 폴백 → 화면은 mock 유지.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:porest_desk_app/core/network/dio_provider.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_mock.dart';
import 'package:porest_desk_app/features/stocks/data/stocks_repository.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';

final stocksRepositoryProvider = FutureProvider<StocksRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return StocksRepository(dio);
});

/// 화면 진입 시 전체 종목 라이브 시세 + 환율을 받아 mock 모듈에 적용.
/// 키 있으면 실데이터(kStocks[].price / kFxUsdKrw 갱신), 없으면 mock 유지. applied 여부 반환.
final stockLiveOverlayProvider = FutureProvider<bool>((ref) async {
  var applied = false;
  final StocksRepository repo;
  try {
    repo = await ref.watch(stocksRepositoryProvider.future);
  } catch (_) {
    return false;
  }
  try {
    final prices = await repo.getPrices(kStocks.map((s) => s.ticker).toList());
    final map = {for (final p in prices) p.symbol: p.priceValue};
    if (applyLivePrices(map)) applied = true;
  } catch (_) {
    // 키 없음/미기동 → mock 시세 유지
  }
  try {
    final fx = await repo.getExchangeRate();
    if (setLiveFx(fx.rateValue)) applied = true;
  } catch (_) {
    // mock 환율 유지
  }
  return applied;
});

/// 종목 호가 (라이브). 에러/미설정 시 null → 호가창 빈 상태 (mock 폴백 없음).
final tossOrderbookProvider =
    FutureProvider.family<TossOrderbook?, String>((ref, symbol) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getOrderbook(symbol);
  } catch (_) {
    return null;
  }
});

/// 종목 체결 내역 (라이브). 에러/미설정 시 null → 체결 테이프 빈 상태 (mock 폴백 없음).
final tossTradesProvider =
    FutureProvider.family<List<TossTrade>?, String>((ref, symbol) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getTrades(symbol);
  } catch (_) {
    return null;
  }
});

/// 증권 계좌 목록 (개인 키). 키 미등록/미설정/에러 시 null → 화면은 '연결 유도' 빈 상태.
final tossAccountsProvider =
    FutureProvider<List<TossAccount>?>((ref) async {
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
final tossCandlesProvider =
    FutureProvider.family<TossCandlePage?, CandleArg>((ref, arg) async {
  if (arg.symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    final count = arg.interval == '1m' ? 390 : 250;
    return await repo.getCandles(arg.symbol, arg.interval, count: count);
  } catch (_) {
    return null;
  }
});

/// 종목 기본정보(시장/유형/통화/상장일/발행주식수/거래상태). 에러/미설정 시 null.
final tossStockInfoProvider =
    FutureProvider.family<TossStockInfo?, String>((ref, symbol) async {
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
final tossPriceLimitsProvider =
    FutureProvider.family<TossPriceLimit?, String>((ref, symbol) async {
  if (symbol.isEmpty) return null;
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getPriceLimits(symbol);
  } catch (_) {
    return null;
  }
});

/// 국내 장 운영 일정. 에러/미설정 시 null.
final tossMarketCalendarKrProvider =
    FutureProvider<TossKrMarketCalendar?>((ref) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getMarketCalendarKr();
  } catch (_) {
    return null;
  }
});

/// 미국 장 운영 일정. 에러/미설정 시 null.
final tossMarketCalendarUsProvider =
    FutureProvider<TossUsMarketCalendar?>((ref) async {
  try {
    final repo = await ref.watch(stocksRepositoryProvider.future);
    return await repo.getMarketCalendarUs();
  } catch (_) {
    return null;
  }
});
