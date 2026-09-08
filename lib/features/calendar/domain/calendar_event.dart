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
    // 서버가 늘 채워 내려주는 목록(`CalendarEventApiDto.Response.reminders`).
    // 목록·집계·수정 응답 셋 다 실려 온다 — 없으면 빈 목록으로 읽는다.
    @Default(<EventReminder>[]) List<EventReminder> reminders,
  }) = _CalendarEvent;

  factory CalendarEvent.fromJson(Map<String, dynamic> json) =>
      _$CalendarEventFromJson(json);
}

/// 일정 알림 한 건 — 백엔드 `CalendarEventApiDto.ReminderResponse` 매핑.
///
/// 저장 요청은 이 객체가 아니라 사전분 목록(`reminderMinutes`)만 보낸다.
/// 서버가 그 목록으로 행을 맞춰 준다(있으면 두고, 없으면 만들고, 빠진 건 지운다).
@freezed
abstract class EventReminder with _$EventReminder {
  const factory EventReminder({
    int? rowId,
    int? eventRowId,
    String? reminderType,
    int? minutesBefore,
    String? isSent, // 'Y'|'N'
  }) = _EventReminder;

  factory EventReminder.fromJson(Map<String, dynamic> json) =>
      _$EventReminderFromJson(json);
}

extension CalendarEventX on CalendarEvent {
  DateTime get start => DateTime.parse(startDate);
  DateTime get end => DateTime.parse(endDate);
  bool get isAllDayBool => (isAllDay ?? 'N') == 'Y';

  /// 알림 사전분 목록 — 저장 요청에 그대로 되실을 수 있는 형태.
  ///
  /// **아는 값(칩 목록)으로 걸러내지 않는다.** 웹이 5·15·30·60·1440 밖의 값을
  /// 만들거나 서버가 선택지를 늘렸을 때, 그 값을 모르는 앱이 저장 한 번으로 알림을
  /// 지우면 안 된다 — 화면에 칩이 없어도 값은 그대로 되돌려 준다.
  List<int> get reminderMinutes => [
    for (final r in reminders)
      if (r.minutesBefore != null) r.minutesBefore!,
  ];
}
