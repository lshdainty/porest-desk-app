import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/stats_models.dart';

class StatsRepository {
  StatsRepository(this._dio);
  final Dio _dio;

  Future<MonthlySummary> monthly({required int year, required int month}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/monthly',
        queryParameters: {'year': year, 'month': month},
      );
      return _unwrap(res, MonthlySummary.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<MonthlyTrend>> trend({int months = 6}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/trend',
        queryParameters: {'months': months},
      );
      return _unwrapList(res, 'trends', MonthlyTrend.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<MerchantSummary>> byMerchant({String? startDate, String? endDate}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/by-merchant',
        queryParameters: {
          'startDate': ?startDate,
          'endDate': ?endDate,
        },
      );
      return _unwrapList(res, 'merchants', MerchantSummary.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<AssetExpenseSummary>> byAsset({String? startDate, String? endDate}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/by-asset',
        queryParameters: {
          'startDate': ?startDate,
          'endDate': ?endDate,
        },
      );
      return _unwrapList(res, 'assets', AssetExpenseSummary.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<List<HeatmapCell>> heatmap({required int year, required int month}) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/expenses/summary/heatmap',
        queryParameters: {'year': year, 'month': month},
      );
      return _unwrapList(res, 'cells', HeatmapCell.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

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
