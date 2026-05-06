import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../domain/calendar_aggregate.dart';
import '../domain/calendar_event.dart';
import '../domain/event_label.dart';

class CalendarRepository {
  CalendarRepository(this._dio);
  final Dio _dio;

  // ─── Events ────────────────────────────────────

  Future<List<CalendarEvent>> events({
    required String startDate, // ISO LocalDateTime
    required String endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/calendar/events',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      return _unwrapList(res, 'events', CalendarEvent.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    String? eventType,
    String? color,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    int? labelRowId,
    String? location,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/calendar/event',
        data: {
          'title': title,
          'description': ?description,
          'eventType': eventType ?? 'NORMAL',
          'color': ?color,
          'startDate': startDate,
          'endDate': endDate,
          'isAllDay': isAllDay ? 'Y' : 'N',
          'labelRowId': ?labelRowId,
          'location': ?location,
        },
      );
      return _unwrap(res, CalendarEvent.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<CalendarEvent> updateEvent({
    required int id,
    required String title,
    String? description,
    String? eventType,
    String? color,
    required String startDate,
    required String endDate,
    bool isAllDay = false,
    int? labelRowId,
    String? location,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/calendar/event/$id',
        data: {
          'title': title,
          'description': ?description,
          'eventType': eventType ?? 'NORMAL',
          'color': ?color,
          'startDate': startDate,
          'endDate': endDate,
          'isAllDay': isAllDay ? 'Y' : 'N',
          'labelRowId': ?labelRowId,
          'location': ?location,
        },
      );
      return _unwrap(res, CalendarEvent.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteEvent(int id) async {
    try {
      await _dio.delete<void>('/calendar/event/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─── Labels ────────────────────────────────────

  Future<List<EventLabel>> labels() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/calendar/labels');
      return _unwrapList(res, 'labels', EventLabel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 라벨 생성. POST /calendar/label.
  Future<EventLabel> createLabel({
    required String labelName,
    String? color,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/calendar/label',
        data: {
          'labelName': labelName,
          'color': ?color,
        },
      );
      return _unwrap(res, EventLabel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 라벨 수정. PUT /calendar/label/{id}.
  Future<EventLabel> updateLabel({
    required int id,
    required String labelName,
    String? color,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/calendar/label/$id',
        data: {
          'labelName': labelName,
          'color': ?color,
        },
      );
      return _unwrap(res, EventLabel.fromJson);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  /// 라벨 삭제. DELETE /calendar/label/{id}.
  Future<void> deleteLabel(int id) async {
    try {
      await _dio.delete<void>('/calendar/label/$id');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  // ─── Aggregate ─────────────────────────────────

  /// 캘린더 통합 집계 — events/todos/expenses 단일 호출.
  /// GET /calendar/aggregate?startDate&endDate (YYYY-MM-DD).
  Future<CalendarAggregate> aggregate({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        '/calendar/aggregate',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      return _unwrap(res, CalendarAggregate.fromJson);
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
