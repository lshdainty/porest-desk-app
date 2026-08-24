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

/// 나무 계좌 1건.
class NamuAccount {
  const NamuAccount({required this.accountNo, required this.accountType});

  final String accountNo;
  final String accountType;

  factory NamuAccount.fromJson(Map<String, dynamic> j) => NamuAccount(
        accountNo: (j['accountNo'] as String?) ?? '',
        accountType: (j['accountType'] as String?) ?? '',
      );
}

/// 보유 종목 1건. 국내·해외 필드명 차이는 서버가 흡수해 이 모양으로 준다.
class NamuHoldingItem {
  const NamuHoldingItem({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.avgPrice,
    required this.currentPrice,
    required this.evalAmount,
    required this.profitLoss,
  });

  final String symbol;
  final String name;
  final String quantity;
  final String avgPrice;
  final String currentPrice;
  final String evalAmount;
  final String profitLoss;

  /// 금액은 문자열로 온다(정밀도 보존). 화면이 계산에 쓸 때만 숫자로 바꾼다.
  double get evalAmountValue => double.tryParse(evalAmount) ?? 0;
  double get profitLossValue => double.tryParse(profitLoss) ?? 0;

  factory NamuHoldingItem.fromJson(Map<String, dynamic> j) => NamuHoldingItem(
        symbol: (j['symbol'] as String?) ?? '',
        name: (j['name'] as String?) ?? '',
        quantity: (j['quantity'] as String?) ?? '0',
        avgPrice: (j['avgPrice'] as String?) ?? '0',
        currentPrice: (j['currentPrice'] as String?) ?? '0',
        evalAmount: (j['evalAmount'] as String?) ?? '0',
        profitLoss: (j['profitLoss'] as String?) ?? '0',
      );
}

/// 계좌 하나의 보유 현황 — 요약 + 종목별.
class NamuHoldings {
  const NamuHoldings({
    required this.accountNo,
    required this.currency,
    required this.totalEvalAmount,
    required this.totalProfitLoss,
    required this.profitRate,
    required this.items,
  });

  final String accountNo;
  final String currency;
  final String totalEvalAmount;
  final String totalProfitLoss;
  final String profitRate;
  final List<NamuHoldingItem> items;

  double get totalEvalValue => double.tryParse(totalEvalAmount) ?? 0;
  double get totalProfitLossValue => double.tryParse(totalProfitLoss) ?? 0;
  double get profitRateValue => double.tryParse(profitRate) ?? 0;

  factory NamuHoldings.fromJson(Map<String, dynamic> j) => NamuHoldings(
        accountNo: (j['accountNo'] as String?) ?? '',
        currency: (j['currency'] as String?) ?? 'KRW',
        totalEvalAmount: (j['totalEvalAmount'] as String?) ?? '0',
        totalProfitLoss: (j['totalProfitLoss'] as String?) ?? '0',
        profitRate: (j['profitRate'] as String?) ?? '0',
        items: ((j['items'] as List?) ?? [])
            .whereType<Map<String, dynamic>>()
            .map(NamuHoldingItem.fromJson)
            .toList(),
      );

  static const empty = NamuHoldings(
    accountNo: '',
    currency: 'KRW',
    totalEvalAmount: '0',
    totalProfitLoss: '0',
    profitRate: '0',
    items: [],
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

  /// 본인 계좌 목록.
  Future<List<NamuAccount>> getAccounts() async {
    try {
      final res = await _dio.get<dynamic>('/namu/accounts');
      final p = _payload(res);
      if (p is! List) return const [];
      return p.whereType<Map<String, dynamic>>().map(NamuAccount.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 보유 종목. [currency] 가 KRW 면 국내, 그 밖(USD·CNY·HKD·JPY)이면 해외.
  /// [accountNo] 를 안 주면 서버가 첫 계좌를 쓴다.
  Future<NamuHoldings> getHoldings({String? accountNo, String currency = 'KRW'}) async {
    try {
      final res = await _dio.get<dynamic>('/namu/holdings',
          queryParameters: {'currency': currency, 'accountNo': ?accountNo});
      final p = _payload(res);
      return p is Map<String, dynamic> ? NamuHoldings.fromJson(p) : NamuHoldings.empty;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
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
