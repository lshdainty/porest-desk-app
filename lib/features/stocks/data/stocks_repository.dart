/// 토스증권 Open API 연동 repository (백엔드 조회 프록시 `/api/v1/toss/**`).
/// Dio baseUrl 이 이미 `/api/v1` 이므로 경로는 `/toss/...`.
/// 키 미설정 시 백엔드 503(TOSS_NOT_CONFIGURED) → 호출 provider 가 mock 폴백.
library;

import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/features/stocks/data/toss_dto.dart';

class StocksRepository {
  StocksRepository(this._dio);
  final Dio _dio;

  /// ApiResponse envelope({success, code, message, data})에서 data 추출.
  dynamic _payload(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body['data'];
    return body;
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

  // 계좌 / 보유자산 (raw — 화면 미연동, 추후 타입화) -----------------------

  Future<List<dynamic>> getAccounts() async {
    try {
      final res = await _dio.get<dynamic>('/toss/accounts');
      return (_payload(res) as List? ?? []);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Map<String, dynamic>> getHoldings(int accountSeq, {String? symbol}) async {
    try {
      final res = await _dio.get<dynamic>(
        '/toss/holdings',
        queryParameters: {'accountSeq': accountSeq, 'symbol': ?symbol},
      );
      return (_payload(res) as Map<String, dynamic>? ?? {});
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
