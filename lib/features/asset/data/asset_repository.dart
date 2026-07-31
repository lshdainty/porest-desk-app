import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/asset/domain/asset.dart';
import 'package:porest_desk_app/features/asset/domain/asset_summary.dart';
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
          'balance': ?balance,
          'currency': ?currency,
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
          'balance': ?balance,
          'currency': ?currency,
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

  /// holdings 요청 바디 — linked ↔ manual 별 필요한 필드만 직렬화.
  static Map<String, dynamic> _holdingBody(AssetHolding h) => {
        'rowId': ?h.rowId,
        'linked': h.linked,
        if (h.linked) ...{
          'tossSymbol': h.tossSymbol,
          'quantity': h.quantity ?? 0,
        } else ...{
          'holdingName': h.holdingName,
          'holdingValue': h.holdingValue ?? 0,
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

  /// 투자 자산 ↔ 토스 종목 연결 (종목코드 + 보유수량). PUT /asset/{id}/toss-link.
  /// 평가액 = 토스 현재가 × 수량. 프로(SECURITIES)+토스 연결 사용자만 가능(미충족 시 403).
  Future<Asset> linkTossSymbol(int id, String symbol, int quantity) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/asset/$id/toss-link',
        data: {'symbol': symbol, 'quantity': quantity},
      );
      return _unwrap(res, Asset.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 토스 연결 해제. DELETE /asset/{id}/toss-link.
  Future<Asset> unlinkTossSymbol(int id) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>('/asset/$id/toss-link');
      return _unwrap(res, Asset.fromJson);
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

  /// 지금 결제 — 이번 청구액을 결제 출금계좌에서 이체. POST /asset/{id}/pay.
  /// 방금 기록된 청구 1건을 반환.
  Future<BillingItem> payCard(int id) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/asset/$id/pay');
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
    String? description,
    required String transferDate, // 'YYYY-MM-DD'
  }) async {
    try {
      await _dio.post<dynamic>(
        '/asset-transfer',
        data: {
          'fromAssetRowId': fromAssetRowId,
          'toAssetRowId': toAssetRowId,
          'amount': amount,
          'fee': ?fee,
          'description': ?description,
          'transferDate': transferDate,
        },
      );
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
