import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/dashboard/domain/dashboard_summary.dart';

/// Dashboard summary — front `dashboardApi` 미러.
class DashboardRepository {
  DashboardRepository(this._dio);
  final Dio _dio;

  /// 통합 요약. GET /dashboard/summary.
  Future<DashboardSummary> summary() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/summary');
      final body = ApiResponse<DashboardSummary>.fromJson(
        res.data ?? const {},
        (raw) => DashboardSummary.fromJson(raw! as Map<String, dynamic>),
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
