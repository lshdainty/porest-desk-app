import 'package:dio/dio.dart';

import 'package:porest_desk_app/core/network/api_exception.dart';
import 'package:porest_desk_app/core/network/api_response.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_aggregate.dart';
import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/event_label.dart';

/// 일정 종류 기본값. 앱에는 종류를 고르는 자리가 없어 웹과 같은 값을 쓴다
/// (웹 `EventForm` 도 신규 일정에 `PERSONAL` 을 고정으로 싣는다).
const kDefaultCalendarEventType = 'PERSONAL';

/// 저장 요청에 실을 일정 종류를 정한다.
///
/// 서버 enum(`CalendarEventType`)은 `PERSONAL`·`WORK`·`BIRTHDAY`·`HOLIDAY` 넷뿐이다.
/// 여기 없는 값을 실으면 본문을 읽는 단계에서 걸려 저장이 400 으로 끝나고, 키를 아예
/// 빼면 `event_type` 이 비어 저장이 깨진다 — 어느 쪽도 일정이 저장되지 않는다.
/// 그래서 **항상 값을 싣되, 비어 있을 때만** 기본값으로 채운다.
///
/// 아는 값 목록으로 걸러내지는 않는다. 서버가 종류를 늘렸을 때, 그 값을 모르는 옛 앱이
/// 수정 저장 한 번으로 사용자가 고른 종류를 기본값으로 되돌리면 안 된다.
String eventTypeOrDefault(String? eventType) {
  final trimmed = eventType?.trim();
  return (trimmed == null || trimmed.isEmpty)
      ? kDefaultCalendarEventType
      : trimmed;
}

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
        queryParameters: {'startDate': startDate, 'endDate': endDate},
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
    int? calendarRowId,
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
          'eventType': eventTypeOrDefault(eventType),
          'color': ?color,
          'calendarRowId': ?calendarRowId,
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
    int? calendarRowId,
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
          'eventType': eventTypeOrDefault(eventType),
          'color': ?color,
          'calendarRowId': ?calendarRowId,
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
        data: {'labelName': labelName, 'color': ?color},
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
        data: {'labelName': labelName, 'color': ?color},
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
        queryParameters: {'startDate': startDate, 'endDate': endDate},
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
