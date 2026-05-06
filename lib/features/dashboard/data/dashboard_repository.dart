import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/dashboard_summary.dart';

/// Dashboard summary + layout — front `dashboardApi` 미러.
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

  /// 위젯 레이아웃 (JSON 문자열). GET /dashboard/layout.
  Future<String?> getLayout() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/dashboard/layout');
      final body = ApiResponse<Map<String, dynamic>>.fromJson(
        res.data ?? const {},
        (raw) => raw! as Map<String, dynamic>,
      );
      if (!body.success || body.data == null) {
        throw ApiException(code: body.code, message: body.message);
      }
      return body.data!['dashboard'] as String?;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 위젯 레이아웃 갱신. PATCH /dashboard/layout.
  Future<void> updateLayout(String layoutJson) async {
    try {
      await _dio.patch<dynamic>(
        '/dashboard/layout',
        data: {'dashboard': layoutJson},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}
