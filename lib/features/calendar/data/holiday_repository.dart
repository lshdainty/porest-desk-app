import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/calendar/domain/holiday.dart';

/// 공휴일/사용자 정의 휴일 — front `holidayApi` 미러.
class HolidayRepository {
  HolidayRepository(this._dio);
  final Dio _dio;

  /// 기간 내 공휴일 목록. GET /holidays?startDate&endDate.
  Future<List<Holiday>> list({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/holidays',
        queryParameters: {'startDate': startDate, 'endDate': endDate},
      );
      return _unwrapList(res, 'holidays', Holiday.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Holiday> create({
    required String holidayDate, // YYYY-MM-DD
    required String holidayName,
    String holidayType = 'CUSTOM',
    bool isRecurring = false,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/holiday',
        data: {
          'holidayDate': holidayDate,
          'holidayName': holidayName,
          'holidayType': holidayType,
          'isRecurring': isRecurring ? 'Y' : 'N',
        },
      );
      return _unwrap(res, Holiday.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<Holiday> update({
    required int id,
    required String holidayDate,
    required String holidayName,
    String holidayType = 'CUSTOM',
    bool isRecurring = false,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/holiday/$id',
        data: {
          'holidayDate': holidayDate,
          'holidayName': holidayName,
          'holidayType': holidayType,
          'isRecurring': isRecurring ? 'Y' : 'N',
        },
      );
      return _unwrap(res, Holiday.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> delete(int id) async {
    try {
      await _dio.delete<void>('/holiday/$id');
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
