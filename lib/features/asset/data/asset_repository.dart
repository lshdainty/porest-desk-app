import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/asset.dart';
import '../domain/asset_summary.dart';

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
