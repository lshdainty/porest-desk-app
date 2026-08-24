/// 나무증권(NH PLUG) 조회 repository — 백엔드 프록시 `/api/v1/namu/**`.
/// Dio baseUrl 이 이미 `/api/v1` 이므로 경로는 `/namu/...`.
///
/// **토스와 나눠 둔 이유** — 두 증권사가 주는 데이터가 겹치지 않는다. 한 repository 에
/// 합치면 메서드 절반이 "이 증권사는 미지원" 이 된다.
library;

import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';

/// 증권사 무관 현재가. 백엔드가 증권사별 필드명 차이를 흡수해 이 모양으로 준다
/// (나무 국내 `stck_prpr` / 나무 해외 `trdprc`).
class BrokerPrice {
  const BrokerPrice({required this.symbol, required this.price, required this.currency});

  final String symbol;
  final double price;
  final String currency;

  factory BrokerPrice.fromJson(Map<String, dynamic> j) => BrokerPrice(
        symbol: (j['symbol'] as String?) ?? '',
        price: double.tryParse('${j['price']}') ?? 0,
        currency: (j['currency'] as String?) ?? 'KRW',
      );
}

class NamuRepository {
  NamuRepository(this._dio);
  final Dio _dio;

  dynamic _payload(Response<dynamic> res) {
    final body = res.data;
    if (body is Map<String, dynamic>) return body['data'];
    return body;
  }

  /// 국내주식 현재가. [marketCode] 는 KRX(기본)·NXT·UNT —
  /// 종목이 NXT 거래 대상인지는 서버 stock_master 가 안다.
  Future<BrokerPrice?> getKrPrice(String symbol, {String? marketCode}) async {
    return _price('/namu/kr/price', {'symbol': symbol, 'marketCode': ?marketCode});
  }

  /// 해외주식 현재가.
  Future<BrokerPrice?> getGbPrice(String symbol) async {
    return _price('/namu/gb/price', {'symbol': symbol});
  }

  Future<BrokerPrice?> _price(String path, Map<String, dynamic> query) async {
    try {
      final res = await _dio.get<dynamic>(path, queryParameters: query);
      final p = _payload(res);
      return p is Map<String, dynamic> ? BrokerPrice.fromJson(p) : null;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
