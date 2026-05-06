import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/asset.dart';
import '../domain/asset_summary.dart';
import '../domain/asset_transfer.dart';
import '../domain/net_worth_point.dart';

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
    String? icon,
    String? color,
    String? institution,
    String? memo,
    int? sortOrder,
    int? cardCatalogRowId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/asset',
        data: {
          'assetName': assetName,
          'assetType': assetType,
          'balance': ?balance,
          'currency': ?currency,
          'icon': ?icon,
          'color': ?color,
          'institution': ?institution,
          'memo': ?memo,
          'sortOrder': ?sortOrder,
          'cardCatalogRowId': ?cardCatalogRowId,
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
    String? icon,
    String? color,
    String? institution,
    String? memo,
    String? isIncludedInTotal, // 'Y' | 'N'
    int? cardCatalogRowId,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/asset/$id',
        data: {
          'assetName': assetName,
          'assetType': assetType,
          'balance': ?balance,
          'currency': ?currency,
          'icon': ?icon,
          'color': ?color,
          'institution': ?institution,
          'memo': ?memo,
          'isIncludedInTotal': ?isIncludedInTotal,
          'cardCatalogRowId': ?cardCatalogRowId,
        },
      );
      return _unwrap(res, Asset.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/asset/$id');
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
