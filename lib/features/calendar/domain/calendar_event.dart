import 'package:freezed_annotation/freezed_annotation.dart';

part 'calendar_event.freezed.dart';
part 'calendar_event.g.dart';

/// 백엔드 `CalendarEventApiDto.Response` 매핑.
@freezed
abstract class CalendarEvent with _$CalendarEvent {
  const factory CalendarEvent({
    required int rowId,
    int? userRowId,
    required String title,
    String? description,
    // 서버 enum `CalendarEventType` — 'PERSONAL' | 'WORK' | 'BIRTHDAY' | 'HOLIDAY'.
    // 목록 밖의 값을 되보내면 저장이 400 으로 끝난다.
    String? eventType,
    String? color,
    required String startDate, // ISO LocalDateTime
    required String endDate,
    String? isAllDay, // 'Y'|'N'
    int? calendarRowId,
    String? calendarColor,
    int? labelRowId,
    String? labelName,
    String? labelColor,
    String? location,
    String? rrule,
    int? groupRowId,
    String? groupName,
  }) = _CalendarEvent;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);
}

extension CalendarEventX on CalendarEvent {
  DateTime get start => DateTime.parse(startDate);
  DateTime get end => DateTime.parse(endDate);
  bool get isAllDayBool => (isAllDay ?? 'N') == 'Y';
}
