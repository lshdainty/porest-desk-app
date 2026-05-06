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
    String? eventType, // 'NORMAL' | 'BIRTHDAY' | 'ANNIVERSARY' ...
    String? color,
    required String startDate, // ISO LocalDateTime
    required String endDate,
    String? isAllDay, // 'Y'|'N'
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
