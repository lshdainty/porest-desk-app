import 'package:porest_desk_app/features/calendar/domain/calendar_event.dart';
import 'package:porest_desk_app/features/calendar/domain/user_calendar.dart';

/// 캘린더 하나의 표시 여부 — 웹 `calendar-provider.tsx` 의 `isCalendarVisible` 정합.
///
/// **못 찾으면 보임이다**(웹 `cal?.isVisible ?? true`). 캘린더 목록이 아직 안
/// 왔거나(로딩), 공유가 막 끊겼거나, 일정이 내 목록에 없는 캘린더를 가리킬 수
/// 있다. 그때 숨김 쪽으로 기울면 멀쩡한 일정이 조용히 사라진다 — 웹과 같이
/// 보이는 쪽으로 둔다.
bool isCalendarVisible(List<UserCalendar> calendars, int calendarRowId) {
  for (final c in calendars) {
    if (c.rowId == calendarRowId) return c.isVisible;
  }
  return true;
}

/// 표시가 꺼진 캘린더의 일정을 걸러 낸 목록.
///
/// 웹 `CalendarContainer.filteredEvents` 정합. 서버는 표시 여부로 걸러 주지
/// 않으므로(`CalendarEventServiceImpl` 에 필터 없음) 클라이언트가 건다.
///
/// **거르는 자리는 조회가 아니라 화면이다.** 조회 파라미터에 캘린더를 실으면
/// 월 캐시가 캘린더 조합마다 갈려, 체크박스를 누를 때마다 같은 달을 다시 받는다.
/// 받아 둔 한 달치를 그대로 두고 화면에서만 뺀다.
///
/// 캘린더가 없는 일정(`calendarRowId == null`)은 그대로 둔다 — 웹도
/// `event.calendarRowId &&` 로 값이 있을 때만 표시 여부를 본다.
List<CalendarEvent> visibleCalendarEvents(
  List<CalendarEvent> events,
  List<UserCalendar> calendars,
) => [
  for (final e in events)
    if (e.calendarRowId == null ||
        isCalendarVisible(calendars, e.calendarRowId!))
      e,
];
