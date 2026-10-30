/// 나무증권 조회 providers. 토스와 나눠 둔다 — 응답 모양 · 박자가 달라 증권사별 경로(`/namu/**`)로 부르고,
/// 화면은 두 증권사가 같은 띠 틀을 쓴다.
///
/// ## 언제 다시 받나 — 웹과 같은 박자다
///
/// 나무엔 다건 조회 API 가 없어 조회 한 번이 곧 상류 1콜이고, 유량 제한(429)이 있다.
/// 그래서 박자를 앱에서 새로 정하지 않고 웹(`NamuStocksPage` · `useNamu`)을 그대로 따른다.
///
/// | | 웹 | 앱 |
/// |---|---|---|
/// | 관심 시세 | 30초 폴링(`WATCH_POLL_MS`), 탭이 가려지면 멈춤 | [namuPricePollInterval] |
/// | 상세 시세(머리 · 오늘 시세 · 호가 · 기본 정보) | 10초, 상세가 보일 때만 | [namuDetailPollInterval] |
/// | 체결 | 5초, 체결 탭이 골라져 있고 화면이 보일 때만 | [namuTradesPollInterval] |
/// | 투자자별 | 상세를 열 때 한 번 · 5분 | 폴링 없음 |
/// | 장 상태(시장 띠) | 60초, 시장마다 대표 종목 하나 | [namuMarketStatePollInterval] |
/// | 주문 가능 · 달러(margin) | 폴링 없음. 보유와 같이(진입 · 창 복귀 때 60초 지났으면) | [namuMarginStaleTime] |
/// | 보유 종목 | 폴링 없음. 진입·창 복귀 때 30초 지났으면(`staleTime`) | [namuHoldingsStaleTime] |
/// | 실패한 조회 | 다시 안 친다(`retry: false`) | [securitiesNoRetry] |
///
/// 웹이 안 조르는 것은 앱도 안 조른다. 시세 · 차트 · 환율은 모두 **나무 경로**(`/namu/prices` · `/namu/candles` ·
/// `/namu/exchange-rate`)로 부른다 — 서버 캐시(사용자 × 종목 20초)를 거치므로 상류는 20초에 한 번이다.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/sync/query_freshness.dart';
import 'package:groo_damda_app/features/stocks/data/broker_detail_dto.dart';
import 'package:groo_damda_app/features/stocks/application/securities_retry.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';

/// 나무 관심 시세를 다시 받는 주기.
const namuPricePollInterval = Duration(seconds: 30);

/// 환율을 다시 받는 박자 — [namuPricePollInterval] 마다 한 칸, 20칸 = 10분(웹 나무 환율 10분).
const kNamuFxRefreshTicks = 20;

/// 일별 시세(일봉)를 다시 받는 박자 — 10칸 = 5분(웹 staleTime 5분).
const kNamuDailyRefreshTicks = 10;

/// 나무 종목 상세 시세(머리 · 오늘 시세 · 호가 · 기본 정보)를 다시 받는 주기 — 상세가 보일 때만.
/// 서버가 사용자 × 종목 20초 캐시를 쥐어 상류는 20초에 한 번이다.
const namuDetailPollInterval = Duration(seconds: 10);

/// 나무 체결을 다시 받는 주기 — 체결 탭이 골라져 있고 화면이 보일 때만(서버 캐시 없음).
const namuTradesPollInterval = Duration(seconds: 5);

/// 시장 띠의 장 상태를 다시 받는 주기.
const namuMarketStatePollInterval = Duration(seconds: 60);

/// 주문 가능 · 달러(margin)가 낡았다고 보는 시간.
const namuMarginStaleTime = Duration(seconds: 60);

/// 나무 보유 종목이 낡았다고 보는 시간.
const namuHoldingsStaleTime = Duration(seconds: 30);

final namuRepositoryProvider = FutureProvider<NamuRepository>((ref) async {
  final dio = await ref.watch(dioProvider.future);
  return NamuRepository(dio);
});

/// 보유 종목을 **마지막으로 받아 온 시각** — 통화별.
///
/// 보유 종목은 주기로 조르지 않고, 화면에 들어올 때와 앱으로 돌아올 때 "받은 지
/// 얼마나 됐나" 를 본다([namuHoldingsStale]). 그 시각을 화면 State 에 두면 화면을 닫을
/// 때 같이 사라져, 다시 열 때마다 방금 받은 값도 처음 보는 것처럼 또 받는다.
final namuHoldingsFetchedAtProvider = Provider<Map<String, DateTime>>(
  (ref) => <String, DateTime>{},
);

/// [fetchedAt] 에 받은 보유 종목을 [now] 에 다시 받아야 하는가.
///
/// 받은 적이 없으면(`null`) 낡은 것이다 — 실패한 채 남은 조회가 여기로 온다.
/// 경계는 웹 react-query 와 같게 `>=` 다(정확히 30초면 stale).
bool namuHoldingsStale(DateTime? fetchedAt, DateTime now) =>
    fetchedAt == null || now.difference(fetchedAt) >= namuHoldingsStaleTime;

/// 나무 보유 종목. 통화가 KRW 면 국내, 그 밖이면 해외 — 서버가 엔드포인트를 가른다.
final namuHoldingsProvider = FutureProvider.family<NamuHoldings, String>((
  ref,
  currency,
) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  final holdings = await repo.getHoldings(currency: currency);
  // 성공한 뒤에만 적는다 — 실패한 조회가 "방금 받았다" 가 되면 안 된다.
  // 받는 사이 컨테이너가 버려졌으면(계정 전환) 적지 않는다 — 폐기된 ref 는 읽으면 던진다.
  if (ref.mounted) {
    ref.read(namuHoldingsFetchedAtProvider)[currency] = ref.read(
      freshnessClockProvider,
    )();
  }
  return holdings;
}, retry: securitiesNoRetry);

/// 선택 종목의 나무 현재가(옛 경로). 화면은 더 안 쓰고 세션 전환 시험이 쓴다.
final namuPriceProvider = FutureProvider.family<BrokerPrice?, StockMasterItem>((
  ref,
  item,
) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  return item.countryCode == 'KR'
      ? repo.getKrPrice(item.symbol)
      : repo.getGbPrice(item.symbol);
}, retry: securitiesNoRetry);

/// 나무 화면의 시세 — 관심 묶음 · 시장 띠 장 상태가 쓴다. 키 = 콤마로 이은 심볼(겹침을 빼고 정렬, 50 씩).
///
/// **나무 경로**(`/namu/prices`)를 부른다 — 기본 증권사를 따르는 `/securities/prices` 가 아니다(기본이 토스인 사람의
/// 나무 탭에 토스 값이 나오던 문제). 다건 API 가 없는 나무는 종목마다 1콜이라 서버가 상한 50 · 캐시 20초 · 예산 4초를
/// 쥔다. 전일 종가와 장 상태가 응답에 딸려 온다. 실패는 던진다 — 호출부가 받던 값을 남긴다. 자동 재시도 없음.
final namuQuotesProvider = FutureProvider.family<List<NamuListQuote>, String>((
  ref,
  csv,
) async {
  if (csv.isEmpty) return const [];
  final repo = await ref.watch(namuRepositoryProvider.future);
  return repo.getListQuotes(csv.split(','));
}, retry: securitiesNoRetry);

/// USD→KRW 환율 — 시장 띠의 환율 줄 · 원화 환산 합계 · 비중. 못 받으면 null(값 "환율 없음").
/// `/namu/exchange-rate`(잔고 → 현재가 순, 서버 캐시 10분). 나무 해외 보유가 없으면 해외 현재가의 환율로 넘어간다.
final namuExchangeRateProvider = FutureProvider<double?>((ref) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  return repo.getExchangeRate();
}, retry: securitiesNoRetry);

/// 일별 시세용 일봉 — `/namu/candles`. 최근 열 봉.
final namuDailyCandlesProvider = FutureProvider.family<TossCandlePage, String>((
  ref,
  symbol,
) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  return repo.getCandles(symbol, '1d', size: 10);
}, retry: securitiesNoRetry);

/// 상세 키 — 심볼 + 미국 여부(국내 · 미국 경로가 다르다).
typedef NamuDetailKey = ({String symbol, bool us});

/// 나무 종목 상세 시세. 실패는 던진다 — 머리 띠에 "시세를 불러오지 못했어요" 한 번.
final namuQuoteDetailProvider =
    FutureProvider.family<NamuQuoteDetail, NamuDetailKey>((ref, key) async {
      final repo = await ref.watch(namuRepositoryProvider.future);
      return repo.getQuoteDetail(key.symbol, us: key.us);
    }, retry: securitiesNoRetry);

/// 나무 체결(최신이 먼저). 체결 탭이 골라져 있을 때만 지켜본다.
final namuExecutionsProvider =
    FutureProvider.family<List<TossTrade>, NamuDetailKey>((ref, key) async {
      final repo = await ref.watch(namuRepositoryProvider.future);
      return repo.getExecutions(key.symbol, us: key.us);
    }, retry: securitiesNoRetry);

/// 나무 투자자별 매매동향(국내 종목만). 5분 안에는 다시 안 받는다(화면이 같은 심볼을 다시 열어도).
final namuInvestorsProvider = FutureProvider.autoDispose
    .family<List<InvestorTradingDay>, String>((ref, symbol) async {
      final link = ref.keepAlive();
      final timer = Timer(const Duration(minutes: 5), link.close);
      ref.onDispose(timer.cancel);
      final repo = await ref.watch(namuRepositoryProvider.future);
      return repo.getInvestors(symbol);
    }, retry: securitiesNoRetry);

/// 주문 가능 · 달러 줄의 값(나무는 "예수금 · 달러" — margin 응답에 주문 가능 칸이 없다). 없으면 null.
final namuUsdDepositProvider = FutureProvider<BuyingPower?>((ref) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  final v = await repo.getUsdDeposit();
  if (ref.mounted) {
    ref.read(namuMarginFetchedAtProvider)['USD'] = ref.read(
      freshnessClockProvider,
    )();
  }
  return v;
}, retry: securitiesNoRetry);

/// margin 을 마지막으로 받은 시각 — 보유와 같은 규칙(진입 · 창 복귀 때 60초 지났으면 다시).
final namuMarginFetchedAtProvider = Provider<Map<String, DateTime>>(
  (ref) => <String, DateTime>{},
);

bool namuMarginStale(DateTime? fetchedAt, DateTime now) =>
    fetchedAt == null || now.difference(fetchedAt) >= namuMarginStaleTime;
