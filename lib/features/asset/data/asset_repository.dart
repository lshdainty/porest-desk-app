import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
import 'package:porest_desk_app/features/asset/domain/asset_trade.dart';
import 'package:porest_desk_app/features/asset/domain/asset_transfer.dart';
import 'package:porest_desk_app/features/asset/domain/card_billing.dart';
import 'package:porest_desk_app/features/asset/domain/net_worth_point.dart';

class AssetRepository {
  AssetRepository(this._dio);
  final Dio _dio;

  // ─────────────────────────────────────────────
  // Asset CRUD
  // ─────────────────────────────────────────────

  Future<List<Asset>> list() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/assets');
      return _unwrapList(res, 'assets', Asset.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 단건 조회. GET /asset/{id}.
  Future<Asset> getById(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/asset/$id');
      return _unwrap(res, Asset.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 자산 정렬 순서 변경. PATCH /assets/reorder.
  /// [items] = (assetRowId, sortOrder) pair 목록.
  Future<void> reorder(List<({int assetId, int sortOrder})> items) async {
    try {
      await _dio.patch<dynamic>(
        '/assets/reorder',
        data: {
          'items': [
            for (final i in items)
              {'assetId': i.assetId, 'sortOrder': i.sortOrder},
          ],
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 자산 잔액 추이 (주별). GET /asset/{id}/balance-trend?weeks=N.
  Future<List<AssetBalancePoint>> balanceTrend(int id, {int weeks = 12}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/asset/$id/balance-trend',
        queryParameters: {'weeks': weeks},
      );
      return _unwrapList(res, 'trend', AssetBalancePoint.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 최근 N개월 순자산 추이.
  Future<List<NetWorthPoint>> netWorthTrend({int months = 12}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/assets/net-worth-trend',
        queryParameters: {'months': months},
      );
      return _unwrapList(res, 'trend', NetWorthPoint.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 순자산/자산/부채/지난달 대비 변화 등.
  Future<AssetSummary> summary({int? year, int? month}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/assets/summary',
        queryParameters: {
          'year': ?year,
          'month': ?month,
        },
      );
      return _unwrap(res, AssetSummary.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Asset> create({
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal, // 'Y' | 'N'
    int? sortOrder,
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    // 투자 보유 종목 (INVESTMENT 전용) — 전달 시 전체 교체.
    List<AssetHolding>? holdings,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset',
        data: {
          'assetName': assetName,
          'assetType': assetType,
          'balance': ?_balanceBody(assetType, balance, holdings),
          'currency': ?currency,
          'exchangeRate': ?exchangeRate,
          'color': ?color,
          'institution': ?institution,
          'memo': ?memo,
          'isIncludedInTotal': ?isIncludedInTotal,
          'sortOrder': ?sortOrder,
          'cardCatalogRowId': ?cardCatalogRowId,
          'creditLimit': ?creditLimit,
          'paymentDay': ?paymentDay,
          'paymentAssetRowId': ?paymentAssetRowId,
          'holdings': ?holdings?.map(_holdingBody).toList(),
        },
      );
      return _unwrap(res, Asset.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Asset> update({
    required int id,
    required String assetName,
    required String assetType,
    int? balance,
    String? currency,
    double? exchangeRate,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal, // 'Y' | 'N'
    int? cardCatalogRowId,
    int? creditLimit,
    int? paymentDay,
    int? paymentAssetRowId,
    // 투자 보유 종목 (INVESTMENT 전용) — 전달 시 전체 교체.
    List<AssetHolding>? holdings,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/asset/$id',
        data: {
          'assetName': assetName,
          'assetType': assetType,
          'balance': ?_balanceBody(assetType, balance, holdings),
          'currency': ?currency,
          'exchangeRate': ?exchangeRate,
          'color': ?color,
          'institution': ?institution,
          'memo': ?memo,
          'isIncludedInTotal': ?isIncludedInTotal,
          'cardCatalogRowId': ?cardCatalogRowId,
          'creditLimit': ?creditLimit,
          'paymentDay': ?paymentDay,
          'paymentAssetRowId': ?paymentAssetRowId,
          'holdings': ?holdings?.map(_holdingBody).toList(),
        },
      );
      return _unwrap(res, Asset.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 투자 자산 잔액 — 보유를 함께 보내면 **서버가 평가액을 BigDecimal 로 산정**하므로 싣지 않는다.
  /// 클라이언트가 double 로 계산한 금액을 보내면 DB 에 남는 금액이 깎일 뿐이다.
  /// 보유가 없는 자산(그리고 투자가 아닌 자산)은 기존대로 사용자 입력 잔액을 보낸다.
  static int? _balanceBody(
    String assetType,
    int? balance,
    List<AssetHolding>? holdings,
  ) =>
      assetType == 'INVESTMENT' && (holdings?.isNotEmpty ?? false)
          ? null
          : balance;

  /// holdings 요청 바디 — linked ↔ manual 별 필요한 필드만 직렬화.
  /// 수량은 소수 허용(코인 0.05·금 3.75g)이라 **문자열 그대로** 보낸다 — 서버가 BigDecimal 로 받아
  /// 정밀도가 깎이지 않는다. 미연동도 수량을 남긴다 — 선택이라 없으면 미전송.
  static Map<String, dynamic> _holdingBody(AssetHolding h) => {
        'rowId': ?h.rowId,
        'holdingType': h.holdingType.wire,
        'linked': h.linked,
        if (h.linked) ...{
          'tossSymbol': h.tossSymbol,
          'quantity': h.quantity ?? '0',
        } else ...{
          'holdingName': h.holdingName,
          'holdingValue': h.holdingValue ?? 0,
          'quantity': ?h.quantity,
        },
        'sortOrder': ?h.sortOrder,
      };

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/asset/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─────────────────────────────────────────────
  // Credit Card Billing
  // ─────────────────────────────────────────────

  /// 신용카드 청구 사이클 조회. GET /asset/{id}/billing.
  /// 이번 결제예정액·예정일·결제일·결제계좌 + 청구이력.
  Future<CardBilling> getCardBilling(int id) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/asset/$id/billing');
      return _unwrap(res, CardBilling.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 지금 결제 — 청구액을 결제 출금계좌에서 이체. POST /asset/{id}/pay.
  /// [amount] 미전달이면 남은 청구액 전액, 전달하면 그만큼만(부분 선결제).
  /// 방금 기록된 청구 1건을 반환.
  Future<BillingItem> payCard(int id, {int? amount}) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset/$id/pay',
        queryParameters: amount != null ? {'amount': amount} : null,
      );
      return _unwrap(res, BillingItem.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─────────────────────────────────────────────
  // Asset Transfer
  // ─────────────────────────────────────────────

  Future<void> createTransfer({
    required int fromAssetRowId,
    required int toAssetRowId,
    required int amount,
    int? fee,
    int? interestAmount,
    String? description,
    required String transferDate, // ISO-LOCAL-DATETIME 'YYYY-MM-DDTHH:mm:ss'
  }) async {
    try {
      await _dio.post<dynamic>(
        '/asset-transfer',
        data: {
          'fromAssetRowId': fromAssetRowId,
          'toAssetRowId': toAssetRowId,
          'amount': amount,
          'fee': ?fee,
          'interestAmount': ?interestAmount,
          'description': ?description,
          'transferDate': transferDate,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 매수·매도 등록 — 예수금·보유 수량·원가·실현손익이 함께 움직인다.
  ///
  /// [amount] 는 수수료를 뺀 거래대금이다. 수수료는 매수면 취득원가에 들어가고
  /// 매도면 대금에서 빠진다 — 어느 쪽이든 예수금에서 실제로 나간다.
  Future<AssetTrade> createTrade({
    required int assetRowId,
    required String tradeType, // 'BUY' | 'SELL' | 'OPENING'
    required String holdingType,
    required String holdingKey,
    required bool linked,
    required String quantity,
    required int amount,
    int? fee,
    required String tradeDate, // ISO-LOCAL-DATETIME
    String? description,
    /// 결제 계좌 — null 이면 증권계좌 예수금에서.
    int? settlementAssetRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset-trade',
        data: {
          'assetRowId': assetRowId,
          'tradeType': tradeType,
          'holdingType': holdingType,
          'holdingKey': holdingKey,
          'linked': linked,
          'quantity': quantity,
          'amount': amount,
          'fee': fee ?? 0,
          'tradeDate': tradeDate,
          'description': ?description,
          'settlementAssetRowId': settlementAssetRowId,
        },
      );
      return _unwrap(res, AssetTrade.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<AssetTrade>> getTrades(int assetRowId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/asset-trades',
        queryParameters: {'assetRowId': assetRowId},
      );
      // 거래 목록은 data 가 바로 배열이다 — 다른 목록처럼 감싸는 키가 없다.
      final body = ApiResponse<List<dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => (raw as List<dynamic>?) ?? const [],
      );
      if (!body.success) {
        throw ApiException(code: body.code, message: body.message);
      }
      return (body.data ?? const [])
          .map((e) => AssetTrade.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 거래 취소 — 예수금·수량·원가가 그 거래 직전으로 돌아간다.
  Future<void> deleteTrade(int id) async {
    try {
      await _dio.delete<void>('/asset-trade/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteTransfer(int id) async {
    try {
      await _dio.delete<void>('/asset-transfer/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 자산 이체 내역 조회. GET /asset-transfers?startDate&endDate.
  Future<List<AssetTransfer>> listTransfers({
    String? startDate,
    String? endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/asset-transfers',
        queryParameters: {
          'startDate': ?startDate,
          'endDate': ?endDate,
        },
      );
      return _unwrapList(res, 'transfers', AssetTransfer.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────

  T _unwrap<T>(
    Response<Map<String, dynamic>> res,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<T>.fromJson(
      res.data ?? const {},
      (raw) => fromJson(raw! as Map<String, dynamic>),
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    return body.data!;
  }

  List<T> _unwrapList<T>(
    Response<Map<String, dynamic>> res,
    String listKey,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = ApiResponse<Map<String, dynamic>>.fromJson(
      res.data ?? const {},
      (raw) => raw! as Map<String, dynamic>,
    );
    if (!body.success || body.data == null) {
      throw ApiException(code: body.code, message: body.message);
    }
    final list = (body.data![listKey] as List<dynamic>?) ?? const [];
    return list
        .map((e) => fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }
}
