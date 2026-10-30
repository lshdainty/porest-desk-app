import 'package:groo_damda_app/l10n/generated/app_localizations.dart';

/// 일정 폼의 규칙 — 화면이 없는 순수 함수(웹 `use-event-form.ts` 의 짝). 저장 본문 · 고르는 칸의 값 규칙이 여기 있어
/// 시트 · 시험이 같은 것을 읽는다.

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// 제목 · 설명 · 장소 입력 상한 — 서버 `FieldLimits`(TITLE_MAX 200 · CONTENT_MAX 10,000 · SHORT_NOTE_MAX 500)와 같은 값(웹과 같다).
const int kCalendarTitleMax = 200;
const int kCalendarContentMax = 10000;
const int kCalendarLocationMax = 500;

/// 신규 일정 기본 색 = blue(primary) — 웹 DEFAULT_EVENT_COLOR(#2c70bf) 정합.
const String kDefaultEventColor = '#2c70bf';

/// 알림 고르기의 선택지(분 전) — 웹 REMINDER_OPTIONS 와 같다.
const List<int> kCalendarReminderOptions = <int>[5, 15, 30, 60, 1440];

/// 반복 — 다섯 밖의 규칙(격주 등)은 [none] 으로 읽힌다(보이는 값만 틀리고 저장은 원본이다).
enum CalendarRecurrence { none, daily, weekly, monthly, yearly }

CalendarRecurrence rruleToRecurrence(String? rrule) {
  if (rrule == null || rrule.isEmpty) return CalendarRecurrence.none;
  if (rrule.contains('FREQ=DAILY')) return CalendarRecurrence.daily;
  if (rrule.contains('FREQ=WEEKLY')) return CalendarRecurrence.weekly;
  if (rrule.contains('FREQ=MONTHLY')) return CalendarRecurrence.monthly;
  if (rrule.contains('FREQ=YEARLY')) return CalendarRecurrence.yearly;
  return CalendarRecurrence.none;
}

/// 고른 반복을 저장 본문에 실을 RRULE 로 — 웹 `recurrenceToRrule` 과 같은 값. `none` 은 null(수정에서는 "반복을 지워라").
String? recurrenceToRrule(CalendarRecurrence r) => switch (r) {
  CalendarRecurrence.none => null,
  CalendarRecurrence.daily => 'FREQ=DAILY',
  CalendarRecurrence.weekly => 'FREQ=WEEKLY',
  CalendarRecurrence.monthly => 'FREQ=MONTHLY',
  CalendarRecurrence.yearly => 'FREQ=YEARLY',
};

String recurrenceLabel(AppLocalizations l, CalendarRecurrence r) => switch (r) {
  CalendarRecurrence.none => l.calRecurrenceNone,
  CalendarRecurrence.daily => l.calRepeatDaily,
  CalendarRecurrence.weekly => l.calRepeatWeekly,
  CalendarRecurrence.monthly => l.calRepeatMonthly,
  CalendarRecurrence.yearly => l.calRepeatYearly,
};

String reminderLabel(AppLocalizations l, int minutes) {
  if (minutes == 60) return l.calReminderHourBefore;
  if (minutes == 1440) return l.calReminderDayBefore;
  return l.calReminderMinutesBefore(minutes);
}

/// 알림 줄의 값 글 — 고른 차례가 아니라 짧은 차례("1시간 전, 1일 전"), 없으면 "알림 없음".
String reminderValueText(AppLocalizations l, Iterable<int> minutes) {
  final sorted = minutes.toList()..sort();
  return sorted.isEmpty
      ? l.calFormNoReminder
      : sorted.map((m) => reminderLabel(l, m)).join(', ');
}

/// 시작을 옮긴 뒤 끝을 맞춘다(웹 `ensureEndAfterStart` 와 같은 결과).
///
/// 시각이 있는 일정 — 끝이 시작보다 늦으면 그대로, 같거나 앞서면 시작 + 1시간. 종일 — 날짜만 본다: 시작 날이 끝 날보다
/// 뒤일 때만 끝을 시작 + 1시간(같은 날 안에서는 건드리지 않는다).
DateTime ensureEndAfterStart(
  DateTime start,
  DateTime end, {
  required bool allDay,
}) {
  if (allDay) {
    return _day(start).isAfter(_day(end))
        ? start.add(const Duration(hours: 1))
        : end;
  }
  return start.isBefore(end) ? end : start.add(const Duration(hours: 1));
}

/// 끝이 시작보다 앞서는가 — 저장 때 종료 줄 아래 오류가 된다. 종일은 날짜만 비교한다.
bool calendarRangeInvalid(
  DateTime start,
  DateTime end, {
  required bool allDay,
}) => allDay ? _day(end).isBefore(_day(start)) : end.isBefore(start);

/// 저장 본문의 시각 글 — 서버 LocalDateTime(`yyyy-MM-ddTHH:mm:00`).
String calendarIso(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}T${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}:00';
