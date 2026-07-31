/// 토스증권 Open API 연동 repository (백엔드 조회 프록시 `/api/v1/toss/**`).
/// Dio baseUrl 이 이미 `/api/v1` 이므로 경로는 `/toss/...`.
/// 키 미설정 시 백엔드 503(TOSS_NOT_CONFIGURED) → 호출 provider 가 mock 폴백.
library;

import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/stocks/data/stock_master_dto.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';
import 'package:porest_desk_app/features/stocks/data/watch_dto.dart';

class StocksRepository {
  StocksRepository(this._dio);
  final Dio _dio;

  /// 토스 candles 의 count 상한(min:1 max:200). 초과 요청은 before 커서로 페이지네이션.
  static const int _tossCandleMax = 200;

  /// ApiResponse envelope({success, code, message, data})에서 data 추출.
  dynamic _payload(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body['data'];
    return body;
  }

  // 종목 마스터 검색 (구독 게이트 없음 — 로그인만 필요) ---------------------

  /// 한글명·영문명·심볼 부분일치 검색 상위 [size]개.
  /// 정확 일치 > prefix > 부분 일치 정렬은 서버(stock_master)가 보장한다.
  Future<List<StockMasterItem>> searchStocks(String keyword,
      {int size = 8}) async {
    try {
      final res = await _dio.get<dynamic>(
        '/stocks',
        queryParameters: {'keyword': keyword, 'size': size},
      );
      final page = _payload(res) as Map<String, dynamic>? ?? {};
      final list = (page['content'] as List? ?? []);
      return list
          .map((e) => StockMasterItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 시세 ----------------------------------------------------------------

  Future<List<TossPrice>> getPrices(List<String> symbols) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/prices',
        queryParameters: {'symbols': symbols.join(',')},
      );
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => TossPrice.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TossOrderbook> getOrderbook(String symbol) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/orderbook',
        queryParameters: {'symbol': symbol},
      );
      return TossOrderbook.fromJson(_payload(res) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<TossTrade>> getTrades(String symbol, {int count = 20}) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/trades',
        queryParameters: {'symbol': symbol, 'count': count},
      );
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => TossTrade.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 시장 정보 ------------------------------------------------------------

  Future<TossExchangeRate> getExchangeRate({
    String baseCurrency = 'USD',
    String quoteCurrency = 'KRW',
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/exchange-rate',
        queryParameters: {
          'baseCurrency': baseCurrency,
          'quoteCurrency': quoteCurrency,
        },
      );
      return TossExchangeRate.fromJson(_payload(res) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 계좌 / 보유자산 -------------------------------------------------------

  Future<List<TossAccount>> getAccounts() async {
    try {
      final res = await _dio.get<dynamic>('/toss/accounts');
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => TossAccount.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TossHoldings> getHoldings(int accountSeq, {String? symbol}) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/holdings',
        queryParameters: {'accountSeq': accountSeq, 'symbol': ?symbol},
      );
      return TossHoldings.fromJson(_payload(res) as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 차트 / 종목정보 / 유의사항 / 상하한가 / 장일정 -------------------------

  Future<TossCandlePage> getCandles(
    String symbol,
    String interval, {
    int? count,
  }) async {
    try {
      // count 미지정 또는 ≤200 → 단일 요청
      if (count == null || count <= _tossCandleMax) {
        return _getCandlePage(symbol, interval, size: count);
      }
      // 토스 count 상한(200) 초과 → nextCursor 커서로 누적 (요청당 ≤200)
      final merged = <TossCandle>[];
      final seen = <String>{};
      String? cursor;
      String? nextBefore;
      var remaining = count;
      while (remaining > 0) {
        final pageSize =
            remaining < _tossCandleMax ? remaining : _tossCandleMax;
        final page = await _getCandlePage(symbol, interval,
            size: pageSize, cursor: cursor);
        if (page.candles.isEmpty) break;
        for (final c in page.candles) {
          if (seen.add(c.timestamp)) merged.add(c);
        }
        nextBefore = page.nextBefore;
        remaining -= page.candles.length;
        if (page.nextBefore == null) break;
        cursor = page.nextBefore;
      }
      return TossCandlePage(candles: merged, nextBefore: nextBefore);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TossCandlePage> _getCandlePage(
    String symbol,
    String interval, {
    int? size,
    String? cursor,
  }) async {
    final res = await _dio.get<dynamic>(
      '/toss/candles',
      queryParameters: {
        'symbol': symbol,
        'interval': interval,
        'size': ?size,
        'cursor': ?cursor,
      },
    );
    return TossCandlePage.fromJson(_payload(res) as Map<String, dynamic>? ?? {});
  }

  Future<List<TossStockInfo>> getStocks(List<String> symbols) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/stocks',
        queryParameters: {'symbols': symbols.join(',')},
      );
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => TossStockInfo.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<TossStockWarning>> getStockWarnings(String symbol) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/stocks/${Uri.encodeComponent(symbol)}/warnings',
      );
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => TossStockWarning.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TossPriceLimit> getPriceLimits(String symbol) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/price-limits',
        queryParameters: {'symbol': symbol},
      );
      return TossPriceLimit.fromJson(_payload(res) as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TossKrMarketCalendar> getMarketCalendarKr({String? date}) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/market-calendar/KR',
        queryParameters: {'date': ?date},
      );
      return TossKrMarketCalendar.fromJson(
          _payload(res) as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<TossUsMarketCalendar> getMarketCalendarUs({String? date}) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/market-calendar/US',
        queryParameters: {'date': ?date},
      );
      return TossUsMarketCalendar.fromJson(
          _payload(res) as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 랭킹 / 시장 지표 ------------------------------------------------------

  /// 주식 랭킹 (등락률 포함, 상위 100). TOP_GAINERS/LOSERS 는 realtime 미지원.
  Future<TossRankingResponse> getRankings({
    required String type,
    required String marketCountry,
    required String duration,
    int count = 10,
  }) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/rankings',
        queryParameters: {
          'type': type,
          'marketCountry': marketCountry,
          'duration': duration,
          'count': count,
        },
      );
      return TossRankingResponse.fromJson(
          _payload(res) as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 시장 지표 현재가 (KOSPI·KOSDAQ 지수 등 토스 카탈로그 8종).
  Future<List<TossIndicatorPrice>> getIndicatorPrices(List<String> symbols) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/market-indicators/prices',
        queryParameters: {'symbols': symbols.join(',')},
      );
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => TossIndicatorPrice.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // 관심목록 (서버 stock-watch, 게이트 없음) --------------------------------

  Future<List<StockWatchGroup>> getWatchGroups() async {
    try {
      final res = await _dio.get<dynamic>('/stock-watch/groups');
      final list = (_payload(res) as List? ?? []);
      return list
          .map((e) => StockWatchGroup.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StockWatchGroup> createWatchGroup(String groupName) async {
    try {
      final res = await _dio.post<dynamic>(
        '/stock-watch/groups',
        data: {'groupName': groupName},
      );
      return StockWatchGroup.fromJson(_payload(res) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<StockWatchGroup> renameWatchGroup(int groupId, String groupName) async {
    try {
      final res = await _dio.put<dynamic>(
        '/stock-watch/groups/$groupId',
        data: {'groupName': groupName},
      );
      return StockWatchGroup.fromJson(_payload(res) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteWatchGroup(int groupId) async {
    try {
      await _dio.delete<dynamic>('/stock-watch/groups/$groupId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// marketCode 미지정 시 서버가 심볼 정확 일치 중 KR/US 시장을 우선 해석한다.
  Future<WatchItem> addWatchItem(int groupId, String symbol,
      {String? marketCode}) async {
    try {
      final res = await _dio.post<dynamic>(
        '/stock-watch/groups/$groupId/items',
        data: {'symbol': symbol, 'marketCode': ?marketCode},
      );
      return WatchItem.fromJson(_payload(res) as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> removeWatchItem(int itemId) async {
    try {
      await _dio.delete<dynamic>('/stock-watch/items/$itemId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
