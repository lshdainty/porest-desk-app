/// 나무증권 조회 providers. 토스와 나눠 둔다 — 두 증권사가 주는 데이터가 겹치지 않는다.
///
/// ## 언제 다시 받나 — 웹과 같은 박자다
///
/// 나무엔 다건 조회 API 가 없어 조회 한 번이 곧 상류 1콜이고, 유량 제한(429)이 있다.
/// 그래서 박자를 앱에서 새로 정하지 않고 웹(`NamuStocksPage` · `useNamu`)을 그대로 따른다.
///
/// | | 웹 | 앱 |
/// |---|---|---|
/// | 현재가 | 30초 폴링(`WATCH_POLL_MS`), 탭이 가려지면 멈춤 | [namuPricePollInterval] |
/// | 보유 종목 | 폴링 없음. 진입·창 복귀 때 30초 지났으면(`staleTime`) | [namuHoldingsStaleTime] |
/// | 실패한 조회 | 다시 안 친다(`retry: false`) | [securitiesNoRetry] |
///
/// 웹이 안 조르는 것은 앱도 안 조른다.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:groo_damda_app/core/network/dio_provider.dart';
import 'package:groo_damda_app/core/sync/query_freshness.dart';
import 'package:groo_damda_app/features/stocks/application/securities_providers.dart';
import 'package:groo_damda_app/features/stocks/application/securities_retry.dart';
import 'package:groo_damda_app/features/stocks/data/namu_repository.dart';
import 'package:groo_damda_app/features/stocks/data/securities_repository.dart';
import 'package:groo_damda_app/features/stocks/data/stock_master_dto.dart';
import 'package:groo_damda_app/features/stocks/data/toss_dto.dart';

/// 나무 현재가를 다시 받는 주기.
///
/// 웹의 증권사 무관 시세는 기본 10초(`useSecuritiesPrices`)지만, 나무 화면에서는 웹도
/// 30초로 늘려 쓴다. 이 화면이 부르는 `/namu/*/price` 는 서버 캐시를 안 거쳐 조회 한 번이
/// 그대로 상류 1콜이다 — 10초로 조르면 웹의 세 배를 친다.
const namuPricePollInterval = Duration(seconds: 30);

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

/// 선택 종목의 나무 현재가. 국내·해외 분기는 stock_master 의 국가코드가 정한다.
final namuPriceProvider = FutureProvider.family<BrokerPrice?, StockMasterItem>((
  ref,
  item,
) async {
  final repo = await ref.watch(namuRepositoryProvider.future);
  return item.countryCode == 'KR'
      ? repo.getKrPrice(item.symbol)
      : repo.getGbPrice(item.symbol);
}, retry: securitiesNoRetry);

/// 나무 화면의 시세 — 관심 묶음 · 상세가 쓴다. 키 = 콤마로 이은 심볼(겹침을 빼고 정렬, 50 씩).
///
/// 증권사는 서버가 사용자 기본 소스로 고른다(`/securities/prices`). 다건 API 가 없는 나무는 종목마다 1콜이라
/// 서버가 상한 50 · 캐시 20초 · 예산 4초를 쥔다. 전일 종가가 응답에 딸려 와 등락률을 센다.
/// 실패는 던진다 — 호출부가 받던 값을 남긴다. 자동 재시도 없음(429 를 몰아서 치지 않는다).
final namuQuotesProvider = FutureProvider.family<List<BrokerQuote>, String>((
  ref,
  csv,
) async {
  if (csv.isEmpty) return const [];
  final repo = await ref.watch(securitiesRepositoryProvider.future);
  return repo.getPrices(csv.split(','));
}, retry: securitiesNoRetry);

/// USD→KRW 환율 — 시장 띠의 환율 줄 · 원화 환산 합계 · 비중. 못 받으면 null(그 자리를 그리지 않는다).
final securitiesExchangeRateProvider = FutureProvider<double?>((ref) async {
  final repo = await ref.watch(securitiesRepositoryProvider.future);
  return repo.getExchangeRate();
}, retry: securitiesNoRetry);

/// 일별 시세용 일봉 — 증권사는 서버가 고른다. 최근 열 봉.
final securitiesDailyCandlesProvider =
    FutureProvider.family<TossCandlePage, String>((ref, symbol) async {
      final repo = await ref.watch(securitiesRepositoryProvider.future);
      return repo.getCandles(symbol, '1d', size: 10);
    }, retry: securitiesNoRetry);
